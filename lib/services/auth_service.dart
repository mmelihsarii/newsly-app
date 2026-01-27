import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';
import 'news_service.dart';
import '../views/login_view.dart';
import '../controllers/source_selection_controller.dart';
import '../controllers/follow_controller.dart';
import '../controllers/saved_controller.dart';

class AuthService extends GetxController {
  static AuthService get to => Get.find<AuthService>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Reaktif kullanıcı
  Rx<User?> user = Rx<User?>(null);

  // Loading durumu
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Auth durumunu dinle
    user.bindStream(_auth.authStateChanges());
  }

  // Kullanıcı giriş yapmış mı?
  bool get isLoggedIn => user.value != null;

  // Mevcut kullanıcı
  User? get currentUser => _auth.currentUser;

  // Misafir kullanıcı mı? (Firebase'e giriş yapmamış)
  bool get isGuest => _auth.currentUser == null;

  // Kullanıcı profilini Firestore'a kaydet
  Future<void> _createUserProfileIfNeeded(UserCredential credential) async {
    final user = credential.user;
    if (user != null) {
      await Get.find<UserService>().createUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );
    }
  }

  // ==================== GOOGLE SIGN IN ====================
  Future<UserCredential?> signInWithGoogle() async {
    try {
      isLoading.value = true;
      
      // Önceki cache'i temizle
      Get.find<NewsService>().clearSelectedSourcesCache();

      // Google Sign-In akışını başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Kullanıcı iptal etti
        isLoading.value = false;
        return null;
      }

      // Auth bilgilerini al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase credential oluştur
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'e giriş yap
      final userCredential = await _auth.signInWithCredential(credential);

      // Firestore'da kullanıcı profili oluştur
      await _createUserProfileIfNeeded(userCredential);

      _showSuccessSnackbar('Giriş başarılı!');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_getErrorMessage(e.code));
      return null;
    } catch (e) {
      // Google Sign-In API hatalarını yakala
      final errorStr = e.toString();
      if (errorStr.contains('ApiException: 10') || errorStr.contains('sign_in_failed')) {
        _showErrorSnackbar('Google giriş yapılandırması eksik. Lütfen e-posta ile giriş yapın veya misafir olarak devam edin.');
      } else if (errorStr.contains('network_error') || errorStr.contains('ApiException: 7')) {
        _showErrorSnackbar('İnternet bağlantınızı kontrol edin');
      } else {
        _showErrorSnackbar('Google ile giriş başarısız oldu. Lütfen tekrar deneyin.');
      }
      print('❌ Google Sign-In Error: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== EMAIL/PASSWORD SIGN IN ====================
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      
      // Önceki cache'i temizle
      Get.find<NewsService>().clearSelectedSourcesCache();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _showSuccessSnackbar('Giriş başarılı!');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_getErrorMessage(e.code));
      return null;
    } catch (e) {
      _showErrorSnackbar('Bir hata oluştu: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== EMAIL/PASSWORD SIGN UP ====================
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      isLoading.value = true;

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Firestore'da kullanıcı profili oluştur
      await _createUserProfileIfNeeded(userCredential);

      _showSuccessSnackbar('Kayıt başarılı!');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_getErrorMessage(e.code));
      return null;
    } catch (e) {
      _showErrorSnackbar('Bir hata oluştu: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== APPLE SIGN IN ====================
  Future<UserCredential?> signInWithApple() async {
    try {
      isLoading.value = true;
      
      // Önceki cache'i temizle
      Get.find<NewsService>().clearSelectedSourcesCache();

      // Apple Sign In akışını başlat
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Firebase credential oluştur
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Firebase'e giriş yap
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple ilk girişte isim veriyor, sonraki girişlerde vermiyor
      // İsim varsa güncelle
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      // Firestore'da kullanıcı profili oluştur
      await _createUserProfileIfNeeded(userCredential);

      _showSuccessSnackbar('Apple ile giriş başarılı!');
      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // Kullanıcı iptal etti
        return null;
      }
      _showErrorSnackbar('Apple giriş hatası: ${e.message}');
      return null;
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_getErrorMessage(e.code));
      return null;
    } catch (e) {
      _showErrorSnackbar('Apple ile giriş hatası: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== SIGN OUT ====================
  Future<void> signOut() async {
    try {
      isLoading.value = true;

      // Google'dan çıkış
      await _googleSignIn.signOut();

      // Firebase'den çıkış
      await _auth.signOut();

      // SharedPreferences'tan oturum bilgilerini temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('lastLoginTime');
      
      // GetStorage'daki tüm verileri temizle
      final storage = GetStorage();
      await storage.erase();
      
      // Tüm controller'ları sıfırla
      _resetAllControllers();

      _showSuccessSnackbar('Çıkış yapıldı');
    } catch (e) {
      _showErrorSnackbar('Çıkış yapılırken hata: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== DELETE ACCOUNT ====================
  Future<void> deleteAccount() async {
    try {
      // Onay dialogu göster
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Hesabı Sil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz silinecektir.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(
                'İptal',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Evet, Sil', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      // Kullanıcı iptal ettiyse çık
      if (confirmed != true) return;

      isLoading.value = true;
      
      // Loading dialog göster
      Get.dialog(
        PopScope(
          canPop: false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.red),
                    SizedBox(height: 16),
                    Text('Hesap siliniyor...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // UserService üzerinden hesabı sil - timeout ile
      final userService = Get.find<UserService>();
      bool success = false;
      
      try {
        success = await userService.deleteAccount().timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            print('⚠️ Hesap silme timeout - devam ediliyor');
            return true; // Timeout olsa bile devam et
          },
        );
      } catch (e) {
        print('❌ deleteAccount hatası: $e');
        success = true; // Hata olsa bile çıkış yap
      }
      
      // Loading dialog'u kapat
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (success) {
        // GetStorage'daki tüm verileri temizle
        final storage = GetStorage();
        await storage.erase();
        
        // SharedPreferences'ı da temizle
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        // Tüm controller'ları sıfırla
        _resetAllControllers();

        // Çıkış yap
        try {
          await _googleSignIn.signOut();
        } catch (e) {
          print('Google signOut hatası: $e');
        }
        
        try {
          await _auth.signOut();
        } catch (e) {
          print('Firebase signOut hatası: $e');
        }

        _showSuccessSnackbar('Hesabınız başarıyla silindi');

        // Login sayfasına yönlendir
        Get.offAll(() => LoginView());
      } else {
        _showErrorSnackbar('Hesap silinirken bir hata oluştu');
      }
    } catch (e) {
      // Loading dialog'u kapat
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      _showErrorSnackbar('Hesap silinirken hata: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== PASSWORD RESET ====================
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;

      await _auth.sendPasswordResetEmail(email: email.trim());

      _showSuccessSnackbar('Şifre sıfırlama e-postası gönderildi');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_getErrorMessage(e.code));
    } catch (e) {
      _showErrorSnackbar('Bir hata oluştu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== HELPERS ====================
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Yanlış şifre';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanımda';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'weak-password':
        return 'Şifre çok zayıf, en az 6 karakter olmalı';
      case 'operation-not-allowed':
        return 'Bu işlem şu an için devre dışı';
      case 'account-exists-with-different-credential':
        return 'Bu e-posta farklı bir giriş yöntemiyle kayıtlı';
      default:
        return 'Bir hata oluştu: $code';
    }
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Başarılı',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Hata',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showInfoSnackbar(String message) {
    Get.snackbar(
      'Bilgi',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
  
  /// Tüm controller'ları sıfırla (hesap silme/çıkış için)
  void _resetAllControllers() {
    try {
      // SourceSelectionController sıfırla
      if (Get.isRegistered<SourceSelectionController>()) {
        final controller = Get.find<SourceSelectionController>();
        controller.clearAllData();
      }
    } catch (e) {
      print('⚠️ SourceSelectionController sıfırlama hatası: $e');
    }
    
    try {
      // FollowController sıfırla
      if (Get.isRegistered<FollowController>()) {
        final controller = Get.find<FollowController>();
        controller.selectedSources.clear();
        controller.allSources.clear();
      }
    } catch (e) {
      print('⚠️ FollowController sıfırlama hatası: $e');
    }
    
    try {
      // NewsService cache temizle
      if (Get.isRegistered<NewsService>()) {
        Get.find<NewsService>().clearSelectedSourcesCache();
      }
    } catch (e) {
      print('⚠️ NewsService sıfırlama hatası: $e');
    }
    
    try {
      // SavedController sıfırla
      if (Get.isRegistered<SavedController>()) {
        Get.find<SavedController>().clearAll();
      }
    } catch (e) {
      print('⚠️ SavedController sıfırlama hatası: $e');
    }
    
    print('✅ Tüm controller\'lar sıfırlandı');
  }
}
