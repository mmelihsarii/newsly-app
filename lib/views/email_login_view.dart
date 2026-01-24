import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'city_selection_view.dart';

class EmailLoginView extends StatefulWidget {
  const EmailLoginView({super.key});

  @override
  State<EmailLoginView> createState() => _EmailLoginViewState();
}

class _EmailLoginViewState extends State<EmailLoginView> {
  final AuthService _authService = Get.find<AuthService>();

  bool _isSignIn = true;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _goBack() {
    Get.back();
  }

  Future<void> _markAsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('lastLoginTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar(
        'Hata',
        'E-posta ve şifre gerekli',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final result = _isSignIn
        ? await _authService.signInWithEmail(
            _emailController.text,
            _passwordController.text,
          )
        : await _authService.signUpWithEmail(
            _emailController.text,
            _passwordController.text,
          );

    if (result != null) {
      await _markAsLoggedIn();
      Get.offAll(() => const CitySelectionView());
    }
  }

  Future<void> _signInWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    if (result != null) {
      await _markAsLoggedIn();
      Get.offAll(() => const CitySelectionView());
    }
  }

  void _signInWithApple() {
    _authService.signInWithApple();
  }

  void _forgotPassword() {
    if (_emailController.text.isEmpty) {
      Get.snackbar(
        'Hata',
        'Şifre sıfırlamak için e-posta adresi girin',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    _authService.resetPassword(_emailController.text);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Back Button
                  IconButton(
                    onPressed: _goBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sign In / Sign Up Toggle
                  _buildToggle(isDark),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    _isSignIn ? "Giriş\nYap" : "Kayıt\nOl",
                    style: TextStyle(
                      fontSize: screenHeight < 700 ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                      height: 1.1,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'E-posta',
                    prefixIcon: Icons.email_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  
                  // Password Field
                  _buildPasswordField(isDark),
                  const SizedBox(height: 8),
                  
                  // Forgot Password
                  GestureDetector(
                    onTap: _forgotPassword,
                    child: Text(
                      'Şifremi unuttum',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13),
                    ),
                  ),
                  
                  const Spacer(),
                  const SizedBox(height: 24),
                  
                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4220B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isSignIn ? 'Giriş Yap' : 'Kayıt Ol',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Or sign in with
                  Center(
                    child: Text(
                      'veya ile giriş yap',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Social Buttons Row
                  Row(
                    children: [
                      // Google Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _signInWithGoogle,
                            icon: Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 18,
                              height: 18,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata,
                                size: 22,
                                color: Colors.red,
                              ),
                            ),
                            label: Text(
                              'Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Apple Button - sadece iOS
                      if (Platform.isIOS) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _signInWithApple,
                              icon: Icon(
                                Icons.apple,
                                size: 20,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              label: Text(
                                'Apple ID',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2F47) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isSignIn = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isSignIn ? const Color(0xFF1E3A5F) : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                'Giriş Yap',
                style: TextStyle(
                  color: _isSignIn ? Colors.white : (isDark ? Colors.white54 : Colors.grey),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isSignIn = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: !_isSignIn ? const Color(0xFF1E3A5F) : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                'Kayıt Ol',
                style: TextStyle(
                  color: !_isSignIn ? Colors.white : (isDark ? Colors.white54 : Colors.grey),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2F47) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
          prefixIcon: Icon(prefixIcon, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2F47) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Şifre',
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
