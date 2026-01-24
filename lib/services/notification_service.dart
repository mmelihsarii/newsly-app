import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/news_model.dart';
import '../views/news_detail_page.dart';

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
}

/// Bildirim Servisi - Panel uyumlu
/// Panelin SendNotificationController'ı ile çalışır
class NotificationService extends GetxController {
  static NotificationService get to => Get.find<NotificationService>();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final GetStorage _storage = GetStorage();

  GlobalKey<NavigatorState>? navigatorKey;
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxBool breakingNewsEnabled = true.obs;
  final RxBool isInitialized = false.obs;
  
  // Spam önleme
  DateTime? _lastNotificationTime;
  String? _lastNotificationId;
  static const int _minInterval = 5; // 5 saniye minimum aralık

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    breakingNewsEnabled.value = _storage.read('breaking_news_enabled') ?? true;
  }

  /// Servisi başlat
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    
    print('🚀 NotificationService.initialize() başladı');
    
    if (kIsWeb) {
      print('🔕 Web platformunda bildirimler devre dışı');
      return;
    }

    try {
      // Android için Notification Channel oluştur
      await _createNotificationChannel();
      
      // İzin iste
      print('📋 Bildirim izni isteniyor...');
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('📋 İzin durumu: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ Bildirim izni verildi');
        
        // FCM Token al ve logla
        final token = await _messaging.getToken();
        if (token != null) {
          print('📱 FCM Token (tam): $token');
        } else {
          print('⚠️ FCM Token alınamadı!');
        }
        
        // Topic'lere abone ol (panel bu topic'lere gönderiyor)
        print('🔔 Topic abonelikleri başlıyor...');
        await _subscribeToTopics();
        print('🔔 Topic abonelikleri tamamlandı');
        
        // Mesaj dinleyici
        print('👂 Mesaj dinleyici kuruluyor...');
        _setupMessageListener();
        print('👂 Mesaj dinleyici kuruldu');
        
        isInitialized.value = true;
        print('✅ Bildirim servisi başarıyla başlatıldı!');
      } else {
        print('❌ Bildirim izni reddedildi: ${settings.authorizationStatus}');
      }
    } catch (e, stackTrace) {
      print('❌ Bildirim servisi hatası: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }
  
  /// Android için Notification Channel oluştur
  Future<void> _createNotificationChannel() async {
    try {
      const platform = MethodChannel('com.newsly.haber/notifications');
      await platform.invokeMethod('createNotificationChannel', {
        'id': 'high_importance_channel',
        'name': 'Haber Bildirimleri',
        'description': 'Önemli haber bildirimleri',
        'importance': 4, // IMPORTANCE_HIGH
      });
      print('✅ Notification channel oluşturuldu');
    } catch (e) {
      // Platform channel yoksa Firebase varsayılan kanalı kullanır
      print('⚠️ Notification channel oluşturulamadı (varsayılan kullanılacak): $e');
    }
  }

  /// Mesaj dinleyici
  void _setupMessageListener() {
    // Uygulama ön plandayken
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 BİLDİRİM GELDİ!');
      print('📩 Title: ${message.notification?.title}');
      print('📩 Body: ${message.notification?.body}');
      print('📩 Data: ${message.data}');
      print('📩 MessageId: ${message.messageId}');
      
      // Duplicate kontrolü
      if (_isDuplicate(message)) {
        print('🚫 Duplicate bildirim atlandı');
        return;
      }
      
      final notification = message.notification;
      if (notification == null) {
        print('⚠️ Notification içeriği boş');
        return;
      }

      // Listeye ekle
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
      
      // Snackbar göster
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
      );
      
      // Son bildirim bilgisini güncelle
      _lastNotificationTime = DateTime.now();
      _lastNotificationId = message.messageId;
    });

    // Bildirime tıklanınca (uygulama arka plandayken)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Bildirime tıklandı: ${message.notification?.title}');
      _handleNotificationTap(message);
    });
    
    // Uygulama kapalıyken gelen bildirime tıklanınca
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📩 Uygulama bildirimle açıldı: ${message.notification?.title}');
        _handleNotificationTap(message);
      }
    });
  }
  
  /// Duplicate kontrolü
  bool _isDuplicate(RemoteMessage message) {
    // Aynı messageId kontrolü
    if (_lastNotificationId == message.messageId && message.messageId != null) {
      return true;
    }
    
    // Zaman kontrolü - 5 saniye içinde aynı bildirim
    if (_lastNotificationTime != null) {
      final diff = DateTime.now().difference(_lastNotificationTime!).inSeconds;
      if (diff < _minInterval) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Topic'lere abone ol
  Future<void> _subscribeToTopics() async {
    try {
      // Genel topic - herkes abone (önemli/acil bildirimler için)
      await _messaging.subscribeToTopic('Turkish');
      print('✅ Turkish topic\'ine abone olundu');
      
      // Kategori abonelikleri SourceSelectionController tarafından yönetiliyor
      // Kullanıcı kaynak seçtiğinde otomatik olarak o kategorinin topic'ine abone oluyor
      // category_1, category_2, ... formatında
      print('ℹ️ Kategori abonelikleri kaynak seçimine göre otomatik yönetiliyor');
      
    } catch (e) {
      print('❌ Topic abonelik hatası: $e');
    }
  }
  
  /// Topic aboneliklerini yenile (kategori değiştiğinde çağır)
  Future<void> refreshTopicSubscriptions() async {
    await _subscribeToTopics();
  }
  
  /// Bildirime tıklanınca
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    
    // Haber URL'si varsa aç
    final newsUrl = data['url'];
    if (newsUrl != null && newsUrl.isNotEmpty && newsUrl.toString().startsWith('http')) {
      final news = NewsModel(
        title: message.notification?.title ?? 'Haber',
        sourceUrl: newsUrl,
      );
      Get.to(() => NewsDetailPage(news: news));
      return;
    }
    
    // News ID varsa haberi aç
    final newsId = data['news_id'];
    if (newsId != null && newsId != '0') {
      // TODO: News ID ile haberi getir ve aç
      print('News ID: $newsId');
    }
  }

  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      notifications.refresh();
    }
  }

  void markAllAsRead() {
    for (var notification in notifications) {
      notification.isRead = true;
    }
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
