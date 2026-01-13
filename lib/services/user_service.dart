import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class UserService extends GetxController {
  static UserService get to => Get.find<UserService>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reaktif değişkenler
  var userProfile = Rx<Map<String, dynamic>?>(null);
  var savedNews = <String>[].obs; // Kaydedilen haber ID'leri
  var followedCategories = <String>[].obs; // Takip edilen kategoriler
  var followedSources = <String>[].obs; // Takip edilen kaynaklar
  var isLoading = false.obs;

  // Mevcut kullanıcı ID
  String? get userId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    // Auth durumu değiştiğinde kullanıcı verilerini yükle
    _auth.authStateChanges().listen((user) {
      _loadUserData();
    });
  }

  // ==================== USER PROFILE ====================

  /// Kullanıcı profilini Firestore'a kaydet
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'savedNews': [],
        'followedCategories': [],
        'followedSources': [],
      }, SetOptions(merge: true));

      await _loadUserData();
    } catch (e) {
      print('Profil oluşturma hatası: $e');
    }
  }

  /// Kullanıcı profilini güncelle
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).update({
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUserData();
    } catch (e) {
      print('Profil güncelleme hatası: $e');
    }
  }

  /// Tam profil kaydet (Ad, Soyad, Hakkında, Burç, Takım)
  Future<bool> saveFullProfile({
    required String firstName,
    required String lastName,
    String? about,
    String? zodiacSign,
    String? team,
  }) async {
    if (userId == null) return false;

    try {
      await _db.collection('users').doc(userId).set({
        'firstName': firstName,
        'lastName': lastName,
        'displayName': '$firstName $lastName',
        'about': about ?? '',
        'zodiacSign': zodiacSign ?? '',
        'team': team ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _loadUserData();
      return true;
    } catch (e) {
      print('Profil kaydetme hatası: $e');
      return false;
    }
  }

  /// Kullanıcı verilerini yükle
  Future<void> _loadUserData() async {
    if (userId == null) {
      userProfile.value = null;
      savedNews.clear();
      followedCategories.clear();
      followedSources.clear();
      return;
    }

    try {
      isLoading.value = true;

      final doc = await _db.collection('users').doc(userId).get();

      if (doc.exists) {
        userProfile.value = doc.data();
        savedNews.value = List<String>.from(doc.data()?['savedNews'] ?? []);
        followedCategories.value = List<String>.from(
          doc.data()?['followedCategories'] ?? [],
        );
        followedSources.value = List<String>.from(
          doc.data()?['followedSources'] ?? [],
        );
      }
    } catch (e) {
      print('Veri yükleme hatası: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== SAVED NEWS ====================

  /// Haberi kaydet
  Future<void> saveNews(String newsId) async {
    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).update({
        'savedNews': FieldValue.arrayUnion([newsId]),
      });

      if (!savedNews.contains(newsId)) {
        savedNews.add(newsId);
      }
    } catch (e) {
      print('Haber kaydetme hatası: $e');
    }
  }

  /// Kaydedilen haberi kaldır
  Future<void> unsaveNews(String newsId) async {
    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).update({
        'savedNews': FieldValue.arrayRemove([newsId]),
      });

      savedNews.remove(newsId);
    } catch (e) {
      print('Haber kaldırma hatası: $e');
    }
  }

  /// Haber kaydedilmiş mi?
  bool isNewsSaved(String newsId) => savedNews.contains(newsId);

  /// Toggle kaydet/kaldır
  Future<void> toggleSaveNews(String newsId) async {
    if (isNewsSaved(newsId)) {
      await unsaveNews(newsId);
    } else {
      await saveNews(newsId);
    }
  }

  // ==================== FOLLOWED CATEGORIES ====================

  /// Kategori takip et
  Future<void> followCategory(String category) async {
    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).update({
        'followedCategories': FieldValue.arrayUnion([category]),
      });

      if (!followedCategories.contains(category)) {
        followedCategories.add(category);
      }
    } catch (e) {
      print('Kategori takip hatası: $e');
    }
  }

  /// Kategori takipten çık
  Future<void> unfollowCategory(String category) async {
    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).update({
        'followedCategories': FieldValue.arrayRemove([category]),
      });

      followedCategories.remove(category);
    } catch (e) {
      print('Kategori takipten çıkma hatası: $e');
    }
  }

  /// Kategori takip ediliyor mu?
  bool isCategoryFollowed(String category) =>
      followedCategories.contains(category);

  /// Toggle takip/takipten çık
  Future<void> toggleFollowCategory(String category) async {
    if (isCategoryFollowed(category)) {
      await unfollowCategory(category);
    } else {
      await followCategory(category);
    }
  }

  // ==================== FOLLOWED SOURCES ====================

  /// Kaynak takip et
  Future<void> followSource(String source) async {
    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).update({
        'followedSources': FieldValue.arrayUnion([source]),
      });

      if (!followedSources.contains(source)) {
        followedSources.add(source);
      }
    } catch (e) {
      print('Kaynak takip hatası: $e');
    }
  }

  /// Kaynak takipten çık
  Future<void> unfollowSource(String source) async {
    if (userId == null) return;

    try {
      await _db.collection('users').doc(userId).update({
        'followedSources': FieldValue.arrayRemove([source]),
      });

      followedSources.remove(source);
    } catch (e) {
      print('Kaynak takipten çıkma hatası: $e');
    }
  }

  /// Kaynak takip ediliyor mu?
  bool isSourceFollowed(String source) => followedSources.contains(source);

  /// Toggle takip/takipten çık
  Future<void> toggleFollowSource(String source) async {
    if (isSourceFollowed(source)) {
      await unfollowSource(source);
    } else {
      await followSource(source);
    }
  }

  // ==================== STREAM LISTENERS ====================

  /// Kullanıcı profilini gerçek zamanlı dinle
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream() {
    if (userId == null) {
      return const Stream.empty();
    }
    return _db.collection('users').doc(userId).snapshots();
  }
}
