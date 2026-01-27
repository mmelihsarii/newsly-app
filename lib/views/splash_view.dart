import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_view.dart';
import 'dashboard_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // Ana animasyon controller
  late AnimationController _mainController;
  
  // Logo animasyonları
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  
  // Arka plan parçacık animasyonu
  late AnimationController _particleController;
  
  // Gradient animasyonu
  late Animation<double> _gradientAnimation;

  static const int _sessionExpiryDays = 30;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkAppState();
  }

  void _initAnimations() {
    // Ana controller - 1.5 saniye (iOS için hızlandırıldı)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Parçacık animasyonu - sürekli döngü
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Logo scale: küçükten büyüğe, sonra hafif geri
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 20,
      ),
    ]).animate(_mainController);

    // Logo opacity: fade in
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Gradient animasyonu
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
  }

  Future<void> _checkAppState() async {
    // 1.5 saniye bekle (iOS için hızlandırıldı)
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final int? lastLoginTime = prefs.getInt('lastLoginTime');

    // 30 gün kontrolü
    bool sessionExpired = false;
    if (lastLoginTime != null) {
      final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
      final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;
      
      if (daysSinceLogin >= _sessionExpiryDays) {
        sessionExpired = true;
        await _forceLogout(prefs);
      }
    }

    if (sessionExpired) {
      Get.offAll(() => LoginView());
    } else if (isLoggedIn || firebaseUser != null) {
      await prefs.setInt('lastLoginTime', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('isLoggedIn', true);
      
      // Direkt anasayfaya git
      Get.offAll(() => DashboardView());
    } else {
      // Giriş yapılmamış -> Login'e git
      Get.offAll(() => LoginView());
    }
  }

  Future<void> _forceLogout(SharedPreferences prefs) async {
    try {
      await FirebaseAuth.instance.signOut();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('lastLoginTime');
    } catch (e) {
      print('❌ Çıkış hatası: $e');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                        _gradientAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xFF0F0F1A),
                        const Color(0xFF1A1A2E),
                        _gradientAnimation.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating particles
          ...List.generate(12, (index) => _buildParticle(index)),

          // Glowing orbs
          _buildGlowingOrb(
            alignment: const Alignment(-0.8, -0.6),
            size: 200,
            color: const Color(0xFFF4220B).withOpacity(0.15),
            delay: 0,
          ),
          _buildGlowingOrb(
            alignment: const Alignment(0.8, 0.6),
            size: 250,
            color: const Color(0xFFFF6B4A).withOpacity(0.1),
            delay: 0.5,
          ),
          _buildGlowingOrb(
            alignment: const Alignment(0.3, -0.8),
            size: 150,
            color: const Color(0xFFF4220B).withOpacity(0.08),
            delay: 0.3,
          ),

          // Logo
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glow effect behind logo
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF4220B).withOpacity(0.3 * _logoOpacity.value),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                          child: SizedBox(
                            height: 100,
                            width: 260,
                            child: SvgPicture.asset(
                              'assets/logo.svg',
                              fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFF4220B),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final startX = random.nextDouble() * 2 - 1;
    final startY = random.nextDouble() * 2 - 1;
    final size = random.nextDouble() * 4 + 2;
    final duration = random.nextDouble() * 3 + 5;
    final delay = random.nextDouble();

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = ((_particleController.value + delay) % 1.0);
        final x = startX + math.sin(progress * math.pi * 2) * 0.1;
        final y = startY + math.cos(progress * math.pi * 2) * 0.15;
        final opacity = (math.sin(progress * math.pi * 2) + 1) / 2 * 0.6;

        return Align(
          alignment: Alignment(x, y),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF4220B).withOpacity(opacity),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF4220B).withOpacity(opacity * 0.5),
                  blurRadius: size * 2,
                  spreadRadius: size / 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlowingOrb({
    required Alignment alignment,
    required double size,
    required Color color,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = ((_particleController.value + delay) % 1.0);
        final scale = 1.0 + math.sin(progress * math.pi * 2) * 0.1;
        final opacity = 0.5 + math.sin(progress * math.pi * 2) * 0.3;

        return Align(
          alignment: alignment,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(opacity),
                    color.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
