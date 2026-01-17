import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';
import 'firebase_options.dart';

import 'utils/colors.dart';
import 'views/splash_view.dart';
import 'controllers/home_controller.dart';
import 'controllers/interest_controller.dart';
import 'controllers/saved_controller.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
// Yeni importlar
import 'services/api_service.dart';
import 'models/news_model.dart';
import 'views/news_detail_page.dart';

// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 1. Background Handler (Top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  print("Background Data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Arka plan handler'ı kaydet
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await GetStorage.init();

  // Dependecy Injection
  Get.put(UserService());
  Get.put(AuthService());
  Get.put(HomeController());
  Get.put(InterestController());
  Get.put(SavedController());

  // Notification Service Başlat
  NotificationService().initialize(navigatorKey);

  runApp(const NewslyApp());
}

class NewslyApp extends StatefulWidget {
  const NewslyApp({super.key});

  @override
  State<NewslyApp> createState() => _NewslyAppState();
}

class _NewslyAppState extends State<NewslyApp> {
  // API Servisini burada tanımlıyoruz
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // 3. Click Handling (Navigation)
    setupInteractedMessage();
  }

  Future<void> setupInteractedMessage() async {
    // A. Terminated State (Uygulama kapalıyken tıklandıysa)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // B. Background State (Uygulama arka plandayken tıklandıysa)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    // 4. Deep Linking Logic
    if (message.data.containsKey('newsId')) {
      final newsId = message.data['newsId'].toString();
      print("🔔 BİLDİRİM TIKLANDI - ID: $newsId");
      print("🚀 Detay sayfasına yönlendiriliyor...");

      // API'den veriyi çekip gitmek için fonksiyonu çağır
      _fetchAndNavigate(newsId);
    }
  }

  // ID ile haberi çekip sayfaya yönlendiren fonksiyon
  Future<void> _fetchAndNavigate(String newsId) async {
    try {
      // API İsteği
      // Not: API parametreleriniz backend'e göre değişiklik gösterebilir
      var response = await _apiService.postData("get_news", {
        'news_id': newsId,
        'access_key': '6808',
        'language_id': '2',
      });

      if (response != null &&
          response['error'] == false &&
          response['data'] != null) {
        // Gelen veriyi parse et
        var data = response['data'];
        Map<String, dynamic> newsMap;

        if (data is List && data.isNotEmpty) {
          newsMap = data.first;
        } else if (data is Map<String, dynamic>) {
          newsMap = data;
        } else {
          print("⚠️ Gelen veri formatı beklenmedik: $data");
          return;
        }

        // Modeli oluştur
        NewsModel news = NewsModel.fromJson(newsMap);

        // Sayfaya Git
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewsDetailPage(news: news)),
          );
        }
      } else {
        print("⚠️ Haber verisi alınamadı. Response: $response");
      }
    } catch (e) {
      print("❌ Navigasyon sırasında hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Newsly',
      navigatorKey: navigatorKey, // Global Key
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const SplashView(),
    );
  }
}
