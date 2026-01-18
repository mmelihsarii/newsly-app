import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'onboarding_view.dart';
import 'login_view.dart';
import 'dashboard_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animasyonu için
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Durum kontrolü ve yönlendirme
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    // Splash ekranının en az 2 saniye görünmesi için
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();

    // Değerleri oku
    final bool isIntroShown = prefs.getBool('isIntroShown') ?? false;
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    print(
      '🔍 Splash Check - isIntroShown: $isIntroShown, isLoggedIn: $isLoggedIn',
    );

    if (!isIntroShown) {
      // Intro henüz gösterilmedi -> Onboarding'e git
      Get.offAll(() => const OnboardingView());
    } else if (isLoggedIn) {
      // Intro gösterildi VE kullanıcı giriş yapmış -> Ana sayfaya git
      Get.offAll(() => DashboardView());
    } else {
      // Intro gösterildi AMA giriş yapılmamış -> Login'e git
      Get.offAll(() => LoginView());
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              SizedBox(
                height: 80,
                width: 200,
                child: SvgPicture.asset(
                  'assets/logo.svg',
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFF4220B),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Loading indicator
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF4220B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
