import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/news_model.dart';
import '../services/api_service.dart';
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

class NotificationService extends GetxController {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  // Global Navigator Key
  late GlobalKey<NavigatorState> navigatorKey;

  // Bildirimler listesi
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;

  // Okunmamış bildirim sayısı
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Servisi başlat ve gerekli dinleyicileri kur
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    print('🔔 NotificationService başlatılıyor...');

    // 1. İzin İste (Android 13+ için kritik!)
    final permissionGranted = await _requestPermission();
    if (!permissionGranted) {
      print('❌ Bildirim izni verilmedi, bildirimler çalışmayacak!');
      return;
    }

    // 2. Foreground Bildirim Ayarları (iOS ve Android için)
    // Bu ayar olmadan foreground'da bildirimler görünmez!
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, // Heads-up notification göster
      badge: true, // Badge güncelle
      sound: true, // Ses çal
    );
    print('✅ Foreground bildirim ayarları yapılandırıldı.');

    // 3. FCM Token al ve logla (debug için)
    try {
      final token = await _messaging.getToken();
      print('📱 FCM Token: $token');
    } catch (e) {
      print('⚠️ FCM Token alınamadı: $e');
    }

    // 4. Topic Aboneliği (Web'de desteklenmiyor)
    if (!kIsWeb) {
      try {
        await _messaging.subscribeToTopic('all');
        print('✅ "all" topic\'ine abone olundu.');
      } catch (e) {
        print('❌ Topic abonelik hatası: $e');
      }
    } else {
      print('ℹ️ Web platformunda topic aboneliği desteklenmiyor.');
    }

    // 5. Etkileşim ve Navigation Ayarları
    await setupInteractedMessage();

    // 6. Foreground Dinleyicisi
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Ön Planda Bildirim Alındı!');
      print('   Başlık: ${message.notification?.title}');
      print('   İçerik: ${message.notification?.body}');
      print('   Data: ${message.data}');
      _addNotification(message);
    });

    print('✅ NotificationService başarıyla başlatıldı!');
  }

  /// Gelen bildirimi listeye ekle
  void _addNotification(RemoteMessage message) {
    final notification = NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Bildirim',
      body: message.notification?.body ?? '',
      receivedAt: DateTime.now(),
      data: message.data,
    );

    // Başa ekle (en yeni en üstte)
    notifications.insert(0, notification);
    print('📥 Bildirim eklendi: ${notification.title}');
  }

  /// Bildirimi okundu olarak işaretle
  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      notifications.refresh();
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  void markAllAsRead() {
    for (var notification in notifications) {
      notification.isRead = true;
    }
    notifications.refresh();
  }

  /// Bildirimi sil
  void removeNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
  }

  /// Tüm bildirimleri temizle
  void clearAll() {
    notifications.clear();
  }

  /// Kullanıcının bildirime tıklama senaryolarını yönetir
  Future<void> setupInteractedMessage() async {
    // A. Uygulama Kapalıyken (Terminated) Açılırsa
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _addNotification(initialMessage);
      _handleMessage(initialMessage);
    }

    // B. Uygulama Arka Plandayken (Background) Açılırsa
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _addNotification(message);
      _handleMessage(message);
    });
  }

  /// Gelen mesajın verisini işle ve yönlendir
  void _handleMessage(RemoteMessage message) {
    print("📩 Bildirim Tıklandı! Data: ${message.data}");
    print("TÜM DATA PAKETİ: ${message.data}");

    // Eğer data içinde 'newsId' varsa detaya git
    if (message.data.containsKey('newsId')) {
      final String newsId = message.data['newsId'].toString();
      _navigateToNewsDetail(newsId);
    }
  }

  /// Haberi API'den çek ve detay sayfasına git
  Future<void> _navigateToNewsDetail(String newsId) async {
    try {
      print("🚀 Haber detayı getiriliyor... ID: $newsId");

      // API'den haberi çek (get_news endpoint'ine ID göndererek)
      // NOT: Backend'in tekil haber çekme desteği olduğunu varsayıyoruz.
      // Eğer yoksa, bu kısım backend dökümantasyonuna göre güncellenmeli.
      var response = await _apiService.postData("get_news", {
        'news_id': newsId,
        'access_key': '6808', // Sabit key, gerekirse config'den alınmalı
        'language_id': '2',
      });

      if (response != null &&
          response['error'] == false &&
          response['data'] != null) {
        // Gelen veri liste olabilir, ilk elemanı alalım
        var data = response['data'];
        Map<String, dynamic> newsMap;

        if (data is List && data.isNotEmpty) {
          newsMap = data.first;
        } else if (data is Map<String, dynamic>) {
          newsMap = data;
        } else {
          print("⚠️ Beklenmeyen veri formatı.");
          return;
        }

        NewsModel news = NewsModel.fromJson(newsMap);

        // Navigator ile Sayfaya Git
        // Context olmadan global key kullanarak yönlendirme yapıyoruz
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => NewsDetailPage(news: news)),
        );
      } else {
        print("⚠️ Haber detay verisi alınamadı veya hata döndü.");
      }
    } catch (e) {
      print("❌ Navigasyon Hatası: $e");
    }
  }

  Future<bool> _requestPermission() async {
    print('📋 Bildirim izni isteniyor...');

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // iOS için geçici izin istemiyoruz
      criticalAlert: false,
      announcement: false,
      carPlay: false,
    );

    print('📋 İzin Durumu: ${settings.authorizationStatus}');
    print('   Alert: ${settings.alert}');
    print('   Badge: ${settings.badge}');
    print('   Sound: ${settings.sound}');

    // Android 13+ ve iOS için izin kontrolü
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('✅ Bildirim izni verildi!');
      return true;
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ Bildirim izni reddedildi!');
      return false;
    } else {
      print('⚠️ Bildirim izni belirlenmedi: ${settings.authorizationStatus}');
      return false;
    }
  }
}
