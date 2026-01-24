import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'firebase_options.dart';

import 'views/splash_view.dart';
import 'controllers/home_controller.dart';
import 'controllers/interest_controller.dart';
import 'controllers/saved_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/reading_settings_controller.dart';
import 'controllers/source_selection_controller.dart';
import 'controllers/local_controller.dart';
import 'controllers/follow_controller.dart';
import 'controllers/search_controller.dart' as search;
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/source_service.dart';
import 'services/news_service.dart';
import 'services/analytics_service.dart';

// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlat (Auth ve Firestore için gerekli)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // NOT: FCM background handler KALDIRILDI - Otomatik bildirimler devre dışı

  await GetStorage.init();

  // Dependency Injection
  Get.put(ApiService());
  Get.put(UserService());
  Get.put(AuthService());
  Get.put(ThemeController());
  Get.put(ReadingSettingsController());
  Get.put(SourceService());
  Get.put(NewsService()); // Singleton olarak kaydet
  Get.put(SourceSelectionController());
  Get.put(HomeController());
  Get.put(InterestController());
  Get.put(SavedController());
  Get.lazyPut(() => LocalController());
  Get.put(FollowController());
  Get.put(search.NewsSearchController(), permanent: true);

  // Notification Service Başlat (artık sadece boş bir servis)
  NotificationService().initialize(navigatorKey);

  runApp(const NewslyApp());
}

class NewslyApp extends StatelessWidget {
  const NewslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() => GetMaterialApp(
      title: 'Newsly',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: themeController.lightTheme,
      darkTheme: themeController.darkTheme,
      themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      navigatorObservers: [AnalyticsService().observer],
      home: const SplashView(),
    ));
  }
}
