import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class ProfileController extends GetxController {
  final UserService _userService = Get.find<UserService>();
  final AuthService _authService = Get.find<AuthService>();
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final aboutController = TextEditingController();

  // Reaktif değişkenler
  var isLoading = false.obs;
  var isSaving = false.obs;
  var profileImageUrl = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    aboutController.dispose();
    super.onClose();
  }

  /// Kullanıcı profilini yükle
  void loadUserProfile() {
    final user = _authService.user.value;
    if (user != null) {
      // Önce Firestore'dan yükle
      _loadFirestoreProfile();
    }
  }

  /// Firestore'dan profil bilgilerini yükle
  Future<void> _loadFirestoreProfile() async {
    try {
      final profile = _userService.userProfile.value;
      final user = _authService.user.value;
      
      if (profile != null) {
        // Firestore'da firstName/lastName varsa onları kullan
        final firestoreFirstName = profile['firstName']?.toString() ?? '';
        final firestoreLastName = profile['lastName']?.toString() ?? '';
        
        if (firestoreFirstName.isNotEmpty) {
          firstNameController.text = firestoreFirstName;
          lastNameController.text = firestoreLastName;
        } else if (user != null) {
          // Firestore'da yoksa Firebase Auth'dan veya email'den çek
          _extractNameFromUser(user);
        }
        
        aboutController.text = profile['about']?.toString() ?? '';
        profileImageUrl.value = profile['photoUrl'];
      } else if (user != null) {
        // Firestore profili yoksa Firebase Auth'dan çek
        _extractNameFromUser(user);
      }
    } catch (e) {
      print('Profil yükleme hatası: $e');
    }
  }

  /// Firebase Auth kullanıcısından isim çıkar
  void _extractNameFromUser(dynamic user) {
    final displayName = user.displayName ?? '';
    final email = user.email ?? '';
    
    if (displayName.isNotEmpty) {
      // Google'dan gelen displayName'i kullan
      final nameParts = displayName.trim().split(' ');
      firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    } else if (email.isNotEmpty) {
      // Email'den isim çıkar
      final emailName = email.split('@')[0];
      final nameParts = emailName.split(RegExp(r'[._-]'));
      if (nameParts.isNotEmpty) {
        firstNameController.text = _capitalizeFirst(nameParts.first);
        if (nameParts.length > 1) {
          lastNameController.text = _capitalizeFirst(nameParts.sublist(1).join(' '));
        }
      }
    }
  }

  /// İlk harfi büyük yap
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Profil bilgilerini kaydet
  Future<void> saveProfile() async {
    if (firstNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Hata',
        'Lütfen adınızı girin',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isSaving.value = true;

    try {
      final success = await _userService.saveFullProfile(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        about: aboutController.text.trim(),
      );

      if (success) {
        Get.back(); // Dialog'u kapat
        Get.snackbar(
          'Başarılı',
          'Profiliniz güncellendi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Profil güncellenemedi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Bir hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Profil resmi seçme seçeneklerini göster
  void showImageSourceOptions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Profil Resmi Seç',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildImageSourceOption(
              icon: Icons.camera_alt,
              title: 'Kamera',
              subtitle: 'Fotoğraf çek',
              onTap: () {
                Get.back();
                pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildImageSourceOption(
              icon: Icons.photo_library,
              title: 'Galeri',
              subtitle: 'Galeriden seç',
              onTap: () {
                Get.back();
                pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            if (profileImageUrl.value != null)
              _buildImageSourceOption(
                icon: Icons.delete,
                title: 'Resmi Kaldır',
                subtitle: 'Profil resmini sil',
                color: Colors.red,
                onTap: () {
                  Get.back();
                  removeProfileImage();
                },
              ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFFF4220B)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color ?? const Color(0xFFF4220B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// Resim seç ve kırp
  Future<void> pickImage(ImageSource source) async {
    try {
      isLoading.value = true;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Resmi kırp
        final croppedFile = await _cropImage(pickedFile.path);
        if (croppedFile != null) {
          // Firebase Storage'a yükle
          await uploadProfileImage(File(croppedFile.path));
        }
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Resim seçilirken hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Resmi kırp (Instagram tarzı daire)
  Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Resmi Düzenle',
            toolbarColor: const Color(0xFFF4220B),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Resmi Düzenle',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
          ),
        ],
      );
    } catch (e) {
      print('Resim kırpma hatası: $e');
      return null;
    }
  }

  /// Profil resmini Firebase Storage'a yükle
  Future<void> uploadProfileImage(File imageFile) async {
    try {
      isLoading.value = true;

      final userId = _authService.user.value?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      // Firebase Storage referansı
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      // Önce eski resmi sil (varsa)
      try {
        await storageRef.delete();
      } catch (e) {
        print('Eski resim silinirken hata (normal olabilir): $e');
      }

      // Resmi yükle
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );
      
      final snapshot = await uploadTask;

      // Download URL'i al
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore'da güncelle
      await _userService.updateUserProfile(photoUrl: downloadUrl);

      profileImageUrl.value = downloadUrl;

      Get.snackbar(
        'Başarılı',
        'Profil resminiz güncellendi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } on FirebaseException catch (e) {
      print('Firebase Storage hatası: ${e.code} - ${e.message}');
      Get.snackbar(
        'Hata',
        'Resim yüklenirken hata oluştu: ${e.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      print('Genel hata: $e');
      Get.snackbar(
        'Hata',
        'Resim yüklenirken hata oluştu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Profil resmini kaldır
  Future<void> removeProfileImage() async {
    try {
      isLoading.value = true;

      final userId = _authService.user.value?.uid;
      if (userId == null) return;

      // Firebase Storage'dan sil
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$userId.jpg');
        await storageRef.delete();
      } catch (e) {
        print('Storage silme hatası (dosya bulunamadı olabilir): $e');
      }

      // Firestore'da güncelle
      await _userService.updateUserProfile(photoUrl: null);

      profileImageUrl.value = null;

      Get.snackbar(
        'Başarılı',
        'Profil resminiz kaldırıldı',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Resim kaldırılırken hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
