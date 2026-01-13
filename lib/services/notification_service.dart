import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../models/news_model.dart';
import '../services/api_service.dart';
import '../views/news_detail_page.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  // Global Navigator Key
  late GlobalKey<NavigatorState> navigatorKey;

  /// Servisi başlat ve gerekli dinleyicileri kur
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // 1. İzin İste
    await _requestPermission();

    // 2. Topic Aboneliği
    await _messaging.subscribeToTopic('genel');
    print('✅ NotificationService: "genel" konusuna abone olundu.');

    // 3. Etkileşim ve Navigation Ayarları
    await setupInteractedMessage();

    // 4. Foreground Dinleyicisi
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Ön Planda Bildirim: ${message.notification?.title}');
      // Burada yerel bildirim (Local Notification) gösterilebilir.
    });
  }

  /// Kullanıcının bildirime tıklama senaryolarını yönetir
  Future<void> setupInteractedMessage() async {
    // A. Uygulama Kapalıyken (Terminated) Açılırsa
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // B. Uygulama Arka Plandayken (Background) Açılırsa
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
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

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('📋 İzin Durumu: ${settings.authorizationStatus}');
  }
}
