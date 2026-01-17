import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'city_selection_view.dart';
import 'dashboard_view.dart';
import 'email_login_view.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});

  final AuthService _authService = Get.find<AuthService>();

  void _goBack() {
    Get.back();
  }

  void _continueWithEmail() {
    Get.to(() => const EmailLoginView());
  }

  Future<void> _signInWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    if (result != null) {
      // Giriş başarılı - isLoggedIn kaydet
      await _markAsLoggedIn();
      // Giriş yapan kullanıcıyı şehir seçimine yönlendir
      Get.offAll(() => const CitySelectionView());
    }
  }

  void _signInWithApple() {
    // Apple sign-in henüz implemente edilmedi, sadece bilgi göster
    _authService.signInWithApple();
  }

  void _signUp() {
    Get.to(() => const EmailLoginView());
  }

  Future<void> _continueAsGuest() async {
    // Misafir olarak devam - yine de isLoggedIn kaydet
    await _markAsLoggedIn();
    Get.offAll(() => DashboardView());
  }

  Future<void> _markAsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    print('✅ isLoggedIn = true olarak kaydedildi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header - Sadece Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _goBack,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Görsel Kart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Arka plan görseli
                        Image.network(
                          'https://images.unsplash.com/photo-1529107386315-e1a2ed48a620?w=800',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color.fromARGB(255, 15, 32, 54),
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.4, 1.0],
                              colors: [
                                Colors.transparent,
                                const Color.fromARGB(
                                  255,
                                  11,
                                  25,
                                  43,
                                ).withOpacity(0.2),
                                const Color.fromARGB(
                                  255,
                                  12,
                                  24,
                                  39,
                                ).withOpacity(0.85),
                              ],
                            ),
                          ),
                        ),
                        // Logo (üstte ortalanmış)
                        Positioned(
                          top: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              height: 30,
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
                        ),
                        // Metin (altta)
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Giriş\nSeçenekleri.',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4220B),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Login Butonları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Email Button (Kırmızı - daha tombul)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _continueWithEmail,
                        icon: const Icon(Icons.email_outlined, size: 24),
                        label: const Text(
                          'E-posta ile Devam Et',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4220B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Google Button (daha tombul)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 22,
                          height: 22,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.g_mobiledata,
                            size: 26,
                            color: Colors.red,
                          ),
                        ),
                        label: const Text(
                          'Google ile Giriş Yap',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    // Apple Button - sadece iOS'ta göster
                    if (Platform.isIOS)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: OutlinedButton.icon(
                            onPressed: _signInWithApple,
                            icon: const Icon(
                              Icons.apple,
                              size: 26,
                              color: Colors.black,
                            ),
                            label: const Text(
                              'Apple ile Giriş Yap',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 44),
              // Ayırıcı - Hesap oluşturmadan devam et
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'hesap oluşturmadan devam et',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              // Misafir Butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton.icon(
                    onPressed: _continueAsGuest,
                    icon: const Icon(
                      Icons.person_outline,
                      size: 24,
                      color: Colors.black54,
                    ),
                    label: const Text(
                      'Misafir Olarak Devam Et',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hesabın yok mu? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: _signUp,
                    child: const Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        color: Color(0xFFF4220B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
