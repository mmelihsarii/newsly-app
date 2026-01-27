import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_model.dart';
import '../views/news_detail_page.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'news_service.dart';

/// Bildirim modeli
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic>? data;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.data,
    this.isRead = false,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime receivedAt = DateTime.now();
    final createdAtRaw = data['created_at'];
    if (createdAtRaw != null) {
      if (createdAtRaw is Timestamp) {
        receivedAt = createdAtRaw.toDate();
      } else if (createdAtRaw is String) {
        try {
          receivedAt = DateTime.parse(createdAtRaw);
        } catch (_) {}
      }
    }
    
    // data alanını al - nested veya flat olabilir
    Map<String, dynamic>? notificationData;
    final dataRaw = data['data'];
    if (dataRaw != null && dataRaw is Map) {
      notificationData = Map<String, dynamic>.from(dataRaw);
    } else {
      // data alanı yoksa, news_id doğrudan root'ta olabilir
      notificationData = {};
      if (data['news_id'] != null) {
        notificationData['news_id'] = data['news_id'];
      }
      if (data['newsId'] != null) {
        notificationData['news_id'] = data['newsId'];
      }
    }
    
    return NotificationItem(
      id: doc.id,
      title: _decodeHtmlEntities(data['title']?.toString() ?? ''),
      body: _decodeHtmlEntities(data['body']?.toString() ?? ''),
      receivedAt: receivedAt,
      data: notificationData,
      isRead: false,
    );
  }
  
  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&apos;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—');
  }
}

/// Bildirim Servisi
class NotificationService extends GetxController {
  static NotificationService get to => Get.find<NotificationService>();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  GlobalKey<NavigatorState>? navigatorKey;
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxBool breakingNewsEnabled = true.obs;
  final RxBool isInitialized = false.obs;
  final RxBool isLoading = false.obs;
  
  final RxSet<String> readNotificationIds = <String>{}.obs;
  
  DateTime? _lastNotificationTime;
  String? _lastNotificationId;
  static const int _minInterval = 5;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _loadReadNotificationIds();
  }

  void _loadSettings() {
    breakingNewsEnabled.value = _storage.read('breaking_news_enabled') ?? true;
  }
  
  void _loadReadNotificationIds() {
    final List<dynamic>? savedIds = _storage.read('read_notification_ids');
    if (savedIds != null) {
      readNotificationIds.addAll(savedIds.cast<String>());
    }
  }
  
  void _saveReadNotificationIds() {
    _storage.write('read_notification_ids', readNotificationIds.toList());
  }

  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    
    await fetchNotificationsFromFirestore();
    
    if (kIsWeb) return;

    try {
      await _createNotificationChannel();
      
      // iOS için ön plan bildirim ayarları
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: true,
        carPlay: false,
        criticalAlert: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        String? token;
        for (int i = 0; i < 10; i++) {
          try {
            // iOS için APNS token'ı al
            final apnsToken = await _messaging.getAPNSToken();
            if (apnsToken != null) {
              debugPrint('APNS Token alındı');
            }
            
            token = await _messaging.getToken();
            if (token != null) {
              debugPrint('FCM Token alındı: ${token.substring(0, 20)}...');
              break;
            }
          } catch (e) {
            debugPrint('Token alma hatası: $e');
          }
          await Future.delayed(const Duration(seconds: 1));
        }
        
        await _subscribeToTopics();
        _setupMessageListener();
        isInitialized.value = true;
        debugPrint('Bildirim servisi başarıyla başlatıldı');
      } else {
        debugPrint('Bildirim izni reddedildi: ${settings.authorizationStatus}');
      }
    } catch (e) {
      debugPrint('Bildirim servisi başlatma hatası: $e');
    }
  }
  
  Future<void> _createNotificationChannel() async {
    try {
      const platform = MethodChannel('com.newsly.haber/notifications');
      await platform.invokeMethod('createNotificationChannel', {
        'id': 'high_importance_channel',
        'name': 'Haber Bildirimleri',
        'description': 'Önemli haber bildirimleri',
        'importance': 4,
      });
    } catch (_) {}
  }

  void _setupMessageListener() {
    // Uygulama ön plandayken
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (_isDuplicate(message)) return;
      
      final notification = message.notification;
      if (notification == null) return;
      
      final newsId = message.data['news_id']?.toString();
      
      notifications.insert(0, NotificationItem(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification.title ?? '',
        body: notification.body ?? '',
        receivedAt: DateTime.now(),
        data: message.data,
        isRead: false,
      ));

      if (notifications.length > 50) {
        notifications.removeLast();
      }
      
      Get.snackbar(
        notification.title ?? 'Bildirim',
        notification.body ?? '',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFF4220B),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        icon: const Icon(Icons.notifications_active, color: Colors.white),
        dismissDirection: DismissDirection.horizontal,
        isDismissible: true,
        onTap: (_) {
          if (newsId != null && newsId.isNotEmpty && newsId != '0') {
            _navigateToNewsByNewsId(newsId);
          }
        },
        mainButton: TextButton(
          onPressed: () => Get.closeCurrentSnackbar(),
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
      );
      
      _lastNotificationTime = DateTime.now();
      _lastNotificationId = message.messageId;
    });

    // Bildirime tıklanınca (arka plan)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
    
    // Uygulama kapalıyken
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }
  
  bool _isDuplicate(RemoteMessage message) {
    if (_lastNotificationId == message.messageId && message.messageId != null) {
      return true;
    }
    
    if (_lastNotificationTime != null) {
      final diff = DateTime.now().difference(_lastNotificationTime!).inSeconds;
      if (diff < _minInterval) {
        return true;
      }
    }
    
    return false;
  }
  
  Future<void> _subscribeToTopics() async {
    try {
      await _messaging.subscribeToTopic('Turkish');
    } catch (_) {}
  }
  
  Future<void> refreshTopicSubscriptions() async {
    await _subscribeToTopics();
  }
  
  /// Bildirime tıklanınca - news_id ile habere git
  void _handleNotificationTap(RemoteMessage message) {
    final newsId = message.data['news_id']?.toString();
    
    if (newsId != null && newsId.isNotEmpty && newsId != '0') {
      _navigateToNewsByNewsId(newsId);
    } else {
      _showNotFoundSnackbar();
    }
  }
  
  /// news_id ile habere git - ÖNCE CACHE/RSS'DEN, SONRA API'DEN
  void _navigateToNewsByNewsId(String newsId) async {
    debugPrint('🔍 Haber ID ile aranıyor: $newsId');
    
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.white)),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
    
    try {
      // 1. ÖNCE API'DEN HABERİN BAŞLIĞINI AL
      final apiService = Get.find<ApiService>();
      String? newsTitle;
      
      final response = await apiService.getData(
        ApiConstants.getNewsDetail,
        params: {'id': newsId},
      );
      
      if (response != null && response['success'] == true && response['data'] != null) {
        newsTitle = response['data']['title']?.toString();
        debugPrint('📰 API\'den başlık alındı: $newsTitle');
      }
      
      if (newsTitle != null && newsTitle.isNotEmpty) {
        // 2. BAŞLIK İLE RSS CACHE'İNDEN TAM HABERİ BUL
        final newsFromCache = await _findNewsInCacheByTitle(newsTitle);
        
        if (newsFromCache != null) {
          debugPrint('✅ Cache\'den tam haber bulundu: ${newsFromCache.title}');
          Get.back();
          Get.to(() => NewsDetailPage(news: newsFromCache));
          return;
        }
        
        // 3. Cache'de yoksa API verisini kullan (eksik olsa bile)
        debugPrint('⚠️ Cache\'de bulunamadı, API verisi kullanılıyor');
        final newsData = response['data'];
        final news = NewsModel.fromJson(newsData);
        Get.back();
        Get.to(() => NewsDetailPage(news: news));
        return;
      }
      
      debugPrint('❌ Haber bulunamadı: $newsId');
      Get.back();
      _showNotFoundSnackbar();
    } catch (e) {
      debugPrint('❌ Haber detay hatası: $e');
      if (Get.isDialogOpen == true) Get.back();
      _showNotFoundSnackbar();
    }
  }
  
  /// Cache'deki RSS haberlerinden başlığa göre bul
  Future<NewsModel?> _findNewsInCacheByTitle(String title) async {
    try {
      // NewsService'den cache'deki haberleri al
      final newsService = NewsService();
      final cachedNews = await newsService.fetchAllNews();
      
      if (cachedNews.isEmpty) {
        debugPrint('⚠️ Cache boş');
        return null;
      }
      
      // Başlığı normalize et (küçük harf, boşlukları temizle)
      final normalizedTitle = _normalizeTitle(title);
      
      // Tam eşleşme ara
      for (final news in cachedNews) {
        if (news.title != null) {
          final normalizedNewsTitle = _normalizeTitle(news.title!);
          if (normalizedNewsTitle == normalizedTitle) {
            return news;
          }
        }
      }
      
      // Tam eşleşme yoksa, başlığın büyük kısmı eşleşen haberi bul
      for (final news in cachedNews) {
        if (news.title != null) {
          final normalizedNewsTitle = _normalizeTitle(news.title!);
          // %80 benzerlik kontrolü
          if (normalizedNewsTitle.contains(normalizedTitle) || 
              normalizedTitle.contains(normalizedNewsTitle)) {
            return news;
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Cache arama hatası: $e');
      return null;
    }
  }
  
  /// Başlığı normalize et (karşılaştırma için)
  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), '')
        .trim();
  }
  
  /// Bildirim item'ına tıklanınca (bottom sheet'ten)
  void openNotificationDetail(NotificationItem notification) {
    markAsRead(notification.id);
    
    final newsId = notification.data?['news_id']?.toString();
    debugPrint('📰 Bildirim tıklandı - news_id: $newsId');
    debugPrint('📰 Bildirim data: ${notification.data}');
    
    if (newsId != null && newsId.isNotEmpty && newsId != '0') {
      _navigateToNewsByNewsId(newsId);
    } else {
      debugPrint('❌ news_id boş veya geçersiz');
      _showNotFoundSnackbar();
    }
  }
  
  void _showNotFoundSnackbar() {
    Get.snackbar(
      'Haber Bulunamadı',
      'Bu haber artık mevcut değil veya kaldırılmış olabilir.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
    );
  }

  Future<void> fetchNotificationsFromFirestore() async {
    try {
      isLoading.value = true;
      
      QuerySnapshot snapshot;
      try {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        
        snapshot = await _firestore
            .collection('notifications')
            .where('created_at', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
            .orderBy('created_at', descending: true)
            .limit(50)
            .get();
      } catch (_) {
        snapshot = await _firestore
            .collection('notifications')
            .orderBy('created_at', descending: true)
            .limit(50)
            .get();
      }
      
      final List<NotificationItem> fetchedNotifications = [];
      
      for (final doc in snapshot.docs) {
        try {
          final notification = NotificationItem.fromFirestore(doc);
          notification.isRead = readNotificationIds.contains(notification.id);
          fetchedNotifications.add(notification);
        } catch (_) {}
      }
      
      final existingIds = notifications.map((n) => n.id).toSet();
      for (final notification in fetchedNotifications) {
        if (!existingIds.contains(notification.id)) {
          notifications.add(notification);
        }
      }
      
      notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> refreshNotifications() async {
    await fetchNotificationsFromFirestore();
  }

  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      readNotificationIds.add(id);
      _saveReadNotificationIds();
      notifications.refresh();
    }
  }

  void markAllAsRead() {
    for (var notification in notifications) {
      notification.isRead = true;
      readNotificationIds.add(notification.id);
    }
    _saveReadNotificationIds();
    notifications.refresh();
  }

  void removeNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
  }

  void clearAll() {
    notifications.clear();
  }

  Future<void> toggleBreakingNews(bool enabled) async {
    breakingNewsEnabled.value = enabled;
    await _storage.write('breaking_news_enabled', enabled);
  }
}
