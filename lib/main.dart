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
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';

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
  Get.put(HomeController());
  Get.put(InterestController());
  Get.put(SavedController());

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
      home: const SplashView(),
    ));
  }
}
