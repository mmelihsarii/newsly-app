import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/user_service.dart';

class ThemeController extends GetxController {
  final _storage = GetStorage();
  final _userService = Get.find<UserService>();
  
  // Theme mode
  var isDarkMode = false.obs;
  
  // Storage key
  static const String _themeKey = 'isDarkMode';
  
  @override
  void onInit() {
    super.onInit();
    loadThemeMode();
  }
  
  /// Tema modunu yükle
  void loadThemeMode() {
    // Önce local storage'dan yükle
    final savedTheme = _storage.read(_themeKey);
    if (savedTheme != null) {
      isDarkMode.value = savedTheme;
    }
    
    // Firestore'dan da yükle (senkronizasyon için)
    _loadThemeFromFirestore();
  }
  
  /// Firestore'dan tema yükle
  Future<void> _loadThemeFromFirestore() async {
    try {
      final profile = _userService.userProfile.value;
      if (profile != null && profile['isDarkMode'] != null) {
        isDarkMode.value = profile['isDarkMode'];
        // Local storage'ı da güncelle
        await _storage.write(_themeKey, profile['isDarkMode']);
      }
    } catch (e) {
      print('Tema yükleme hatası: $e');
    }
  }
  
  /// Tema modunu değiştir
  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    
    // Local storage'a kaydet
    await _storage.write(_themeKey, isDarkMode.value);
    
    // Firestore'a kaydet
    await _saveThemeToFirestore();
    
    // Theme'i güncelle
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
  
  /// Firestore'a tema kaydet
  Future<void> _saveThemeToFirestore() async {
    try {
      await _userService.saveDarkModeSetting(isDarkMode.value);
    } catch (e) {
      print('Tema kaydetme hatası: $e');
    }
  }
  
  /// Light theme
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFFF4220B),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFF4220B),
      secondary: Color(0xFF1E3A5F),
      surface: Colors.white,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFF4220B)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFFF4220B),
      unselectedItemColor: Colors.grey,
    ),
  );
  
  /// Dark theme
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFF4220B),
    scaffoldBackgroundColor: const Color(0xFF132440),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF4220B),
      secondary: Color(0xFF1E3A5F),
      surface: Color(0xFF1A2F47),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A2F47),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFF4220B)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A2F47),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A2F47),
      selectedItemColor: Color(0xFFF4220B),
      unselectedItemColor: Colors.grey,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
    ),
  );
}
