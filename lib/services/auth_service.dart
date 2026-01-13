import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'user_service.dart';

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
      _showErrorSnackbar('Bir hata oluştu: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== EMAIL/PASSWORD SIGN IN ====================
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      isLoading.value = true;

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

  // ==================== APPLE SIGN IN (Yakında) ====================
  Future<void> signInWithApple() async {
    _showInfoSnackbar('Apple ile giriş yakında eklenecek!');
  }

  // ==================== SIGN OUT ====================
  Future<void> signOut() async {
    try {
      isLoading.value = true;

      // Google'dan çıkış
      await _googleSignIn.signOut();

      // Firebase'den çıkış
      await _auth.signOut();

      _showSuccessSnackbar('Çıkış yapıldı');
    } catch (e) {
      _showErrorSnackbar('Çıkış yapılırken hata: $e');
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
}
