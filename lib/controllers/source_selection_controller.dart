import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/source_model.dart';
import '../services/source_service.dart';
import '../services/news_service.dart';
import '../utils/news_sources_data.dart';
import 'home_controller.dart';
import 'follow_controller.dart';

/// Controller for managing news source selection
/// Supports both dynamic (Firestore) and static (local) sources
class SourceSelectionController extends GetxController {
  final GetStorage _storage = GetStorage();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Use Get.find to get the injected SourceService
  SourceService get _sourceService => Get.find<SourceService>();

  // Storage key for offline cache
  static const String _selectedSourcesKey = 'selected_sources';
  static const String _subscribedCategoriesKey = 'subscribed_categories';

  // === KAYDEDİLMİŞ KAYNAKLAR (Gerçek veri) ===
  RxSet<String> _savedSources = <String>{}.obs;
  
  // === GEÇİCİ SEÇİMLER (UI için - kaydetmeden önce) ===
  RxSet<String> tempSelectedSources = <String>{}.obs;
  
  // Dışarıdan erişim için (geriye uyumluluk)
  RxSet<String> get selectedSources => _savedSources;
  
  // Subscribed category IDs (for notifications)
  RxSet<int> subscribedCategories = <int>{}.obs;

  // Dynamic sources from Firestore
  RxList<SourceCategory> dynamicCategories = <SourceCategory>[].obs;
  
  // Loading states
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isSourcesLoading = false.obs;

  // Use dynamic sources flag
  var useDynamicSources = true.obs;
  
  // Değişiklik var mı? (Kaydet butonu için)
  bool get hasChanges => !_setEquals(tempSelectedSources, _savedSources);
  
  // Kategori ID eşleştirmesi (Backend ile uyumlu)
  static const Map<String, int> categoryIdMap = {
    'yerel_haberler': 1,
    'yerel': 1,
    'son_dakika': 2,
    'gundem': 3,
    'spor': 4,
    'ekonomi': 5,
    'ekonomi_finans': 5,
    'bilim': 6,
    'teknoloji': 6,
    'bilim_teknoloji': 6,
    'haber_ajanslari': 9,
    'yabanci_kaynaklar': 10,
  };

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _loadSources();
    _loadDynamicSources();
    _loadSubscribedCategories();
  }
  
  /// Kaynak seçim ekranına girerken çağrılır - geçici state'i sıfırla
  Future<void> initTempSelection() async {
    // Önce kaynakların yüklenmesini bekle
    await _loadSources();
    
    // Geçici seçimleri kayıtlı duruma sıfırla
    tempSelectedSources.clear();
    tempSelectedSources.addAll(_savedSources);
    print('🔄 Geçici seçimler sıfırlandı: ${tempSelectedSources.length} kaynak');
    print('📌 Kayıtlı kaynaklar: $_savedSources');
  }
  
  /// Dışarıdan kaynak eklemek için (AddSourceView'dan)
  void setSelectedSources(Set<String> sources) {
    _savedSources.clear();
    _savedSources.addAll(sources);
    tempSelectedSources.clear();
    tempSelectedSources.addAll(sources);
    print('📌 Kaynaklar dışarıdan güncellendi: ${sources.length} kaynak');
  }
  
  /// Değişiklikleri iptal et - geçici state'i kayıtlı haline döndür
  void cancelChanges() {
    tempSelectedSources.clear();
    tempSelectedSources.addAll(_savedSources);
    print('↩️ Değişiklikler iptal edildi');
  }
  
  /// Load subscribed categories from local storage
  void _loadSubscribedCategories() {
    final List<dynamic>? stored = _storage.read<List<dynamic>>(_subscribedCategoriesKey);
    if (stored != null && stored.isNotEmpty) {
      subscribedCategories.assignAll(stored.cast<int>().toSet());
      print('📱 ${subscribedCategories.length} kategori aboneliği yüklendi');
    }
  }

  /// Load dynamic sources from Firestore
  Future<void> _loadDynamicSources() async {
    isSourcesLoading.value = true;
    
    try {
      print('🔄 Dinamik kaynaklar yükleniyor...');
      final categories = await _sourceService.getSourcesByCategory(forceRefresh: true);
      
      if (categories.isNotEmpty) {
        dynamicCategories.assignAll(categories);
        useDynamicSources.value = true;
        print('✅ ${categories.length} kategori, ${categories.fold<int>(0, (sum, c) => sum + c.sources.length)} kaynak yüklendi');
        
        // Log categories for debugging
        for (final cat in categories) {
          print('📁 Kategori: ${cat.name} (${cat.sources.length} kaynak)');
        }
      } else {
        print('⚠️ Firestore\'dan kaynak gelmedi, statik moda geçiliyor');
        useDynamicSources.value = false;
      }
    } catch (e) {
      print('❌ Dinamik kaynak yükleme hatası: $e');
      useDynamicSources.value = false;
    } finally {
      isSourcesLoading.value = false;
    }
  }

  /// Refresh dynamic sources
  Future<void> refreshSources() async {
    // Cache'i temizle
    _sourceService.clearCache();
    await _loadDynamicSources();
  }

  /// Get categories (dynamic or static)
  List<dynamic> get categories {
    if (useDynamicSources.value && dynamicCategories.isNotEmpty) {
      return dynamicCategories;
    }
    return kNewsSources;
  }

  /// Load sources: Offline-first strategy
  Future<void> _loadSources() async {
    isLoading.value = true;

    try {
      // 1. Load from local storage first
      _loadFromLocalStorage();

      // 2. Sync with Firestore if user is logged in
      if (_savedSources.isEmpty && _userId != null) {
        await _syncWithFirestore();
      } else if (_userId != null) {
        // Background sync
        _syncWithFirestore().catchError((e) {
          print("⚠️ Arka plan senkronizasyon hatası: $e");
        });
      }
      
      // Geçici seçimleri de güncelle
      tempSelectedSources.clear();
      tempSelectedSources.addAll(_savedSources);
      
    } catch (e) {
      print('❌ Kaynak yükleme hatası: $e');
      if (_savedSources.isEmpty) _loadFromLocalStorage();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _syncWithFirestore() async {
    if (_userId == null) return;

    try {
      final doc = await _db.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data();
        final List<dynamic>? firestoreSources = 
            data?['selectedSources'] ?? data?['followed_source_ids'];

        if (firestoreSources != null && firestoreSources.isNotEmpty) {
          final newSources = firestoreSources.cast<String>().toSet();
          
          if (!_setEquals(_savedSources, newSources)) {
            print('☁️ Firestore\'dan güncelleme: ${_savedSources.length} → ${newSources.length}');
            _savedSources.assignAll(newSources);
            _saveToLocalStorage();
          }
        }
      }
    } catch (e) {
      print("Firestore okuma hatası: $e");
    }
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.every((element) => b.contains(element));
  }

  void _loadFromLocalStorage() {
    final List<dynamic>? stored = _storage.read<List<dynamic>>(_selectedSourcesKey);
    if (stored != null && stored.isNotEmpty) {
      _savedSources.clear();
      _savedSources.addAll(stored.cast<String>().toSet());
      print('📱 Yerel depodan ${_savedSources.length} kaynak yüklendi');
    } else {
      _savedSources.clear();
      print('🆕 Varsayılan olarak hiçbir kaynak seçili değil');
    }
  }

  void _saveToLocalStorage() {
    _storage.write(_selectedSourcesKey, _savedSources.toList());
  }

  Future<void> _saveToFirestore() async {
    if (_userId == null) return;

    try {
      await _db.collection('users').doc(_userId).set({
        'selectedSources': _savedSources.toList(),
        'followed_source_ids': _savedSources.toList(),
        'selectedSourcesUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('☁️ Firestore\'a ${_savedSources.length} kaynak kaydedildi');
    } catch (e) {
      print('❌ Firestore kaydetme hatası: $e');
    }
  }

  /// TÜM DEĞİŞİKLİKLERİ KAYDET (Devam Et butonunda çağrılır)
  Future<void> saveAllChanges() async {
    isSaving.value = true;
    
    try {
      // Geçici seçimleri kalıcı yap
      _savedSources.clear();
      _savedSources.addAll(tempSelectedSources);
      
      // Kaydet - local storage hemen
      _saveToLocalStorage();
      
      // Firestore'a kaydet (timeout ile)
      try {
        await _saveToFirestore().timeout(const Duration(seconds: 5));
      } catch (e) {
        print('⚠️ Firestore kaydetme timeout/hata: $e');
      }
      
      // NewsService cache'ini temizle
      _clearNewsServiceCache();
      
      // Kategori aboneliklerini arka planda güncelle (beklemeden)
      _updateCategorySubscriptions().catchError((e) {
        print('⚠️ Kategori abonelik hatası: $e');
      });
      
      // HomeController'ı yenile (eğer varsa)
      _refreshHomeController();
      
      print('✅ ${_savedSources.length} kaynak kaydedildi');
    } catch (e) {
      print('❌ Kaydetme hatası: $e');
    } finally {
      isSaving.value = false;
    }
  }
  
  /// HomeController'ı yenile
  void _refreshHomeController() {
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.refreshNews();
        print('🔄 HomeController yenilendi');
      }
    } catch (e) {
      print('⚠️ HomeController yenileme hatası: $e');
    }
    
    // FollowController'ı da yenile
    try {
      if (Get.isRegistered<FollowController>()) {
        final followController = Get.find<FollowController>();
        followController.refreshSources();
        print('🔄 FollowController yenilendi');
      }
    } catch (e) {
      print('⚠️ FollowController yenileme hatası: $e');
    }
  }
  
  /// NewsService cache'ini temizle
  void _clearNewsServiceCache() {
    try {
      if (Get.isRegistered<NewsService>()) {
        Get.find<NewsService>().clearSelectedSourcesCache();
        print('🗑️ Kaynak seçimi değişti - NewsService cache temizlendi');
      }
    } catch (e) {
      print('⚠️ NewsService cache temizleme hatası: $e');
    }
  }
  
  /// Kategori aboneliklerini güncelle
  Future<void> _updateCategorySubscriptions() async {
    try {
      // Seçili kaynakların kategorilerini bul
      final selectedCategoryIds = <int>{};
      
      for (final sourceId in _savedSources) {
        final categoryId = _getCategoryIdForSource(sourceId);
        if (categoryId != null) {
          selectedCategoryIds.add(categoryId);
        }
      }
      
      // Yeni abonelikler
      final toSubscribe = selectedCategoryIds.difference(subscribedCategories);
      // Çıkılacak abonelikler
      final toUnsubscribe = subscribedCategories.difference(selectedCategoryIds);
      
      // Yeni kategorilere abone ol
      for (final catId in toSubscribe) {
        await _subscribeToCategory(catId);
      }
      
      // Eski kategorilerden çık
      for (final catId in toUnsubscribe) {
        await _unsubscribeFromCategory(catId);
      }
      
      // Güncel listeyi kaydet
      subscribedCategories.assignAll(selectedCategoryIds);
      _storage.write(_subscribedCategoriesKey, subscribedCategories.toList());
      
      print('🔔 Kategori abonelikleri güncellendi: ${subscribedCategories.length} kategori');
      
    } catch (e) {
      print('❌ Kategori abonelik güncelleme hatası: $e');
    }
  }
  
  /// Kaynak ID'sine göre kategori ID'sini bul
  int? _getCategoryIdForSource(String sourceId) {
    // Dinamik kategorilerde ara
    for (final category in dynamicCategories) {
      for (final source in category.sources) {
        if (source.id == sourceId || source.name == sourceId) {
          // Kategori adını normalize edip ID'ye çevir
          final normalizedName = _normalizeCategoryName(category.name);
          return categoryIdMap[normalizedName];
        }
      }
    }
    
    // Statik kategorilerde ara
    for (final category in kNewsSources) {
      for (final source in category.sources) {
        if (source.id == sourceId || source.name == sourceId) {
          final normalizedName = _normalizeCategoryName(category.name);
          return categoryIdMap[normalizedName];
        }
      }
    }
    
    return null;
  }
  
  /// Kategori adını normalize et
  String _normalizeCategoryName(String name) {
    return name
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '_')
        .replaceAll('&', '')
        .replaceAll('-', '_')
        .trim();
  }
  
  /// Kategoriye abone ol
  Future<void> _subscribeToCategory(int categoryId) async {
    try {
      final topic = 'category_$categoryId';
      await _messaging.subscribeToTopic(topic);
      print('✅ Kategori topic\'ine abone olundu: $topic');
    } catch (e) {
      print('❌ Kategori abonelik hatası: $e');
    }
  }
  
  /// Kategoriden çık
  Future<void> _unsubscribeFromCategory(int categoryId) async {
    try {
      final topic = 'category_$categoryId';
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Kategori topic\'inden çıkıldı: $topic');
    } catch (e) {
      print('❌ Kategori çıkış hatası: $e');
    }
  }

  /// Toggle a single source selection (GEÇİCİ - kaydetmez)
  void toggleSource(String sourceId) {
    print("🖱️ Toggle Source: $sourceId");
    
    // Önce mevcut seçili mi kontrol et (normalize ile)
    String? matchedId;
    for (final selected in tempSelectedSources) {
      if (selected == sourceId || 
          selected.toLowerCase() == sourceId.toLowerCase() ||
          _normalizeForComparison(selected) == _normalizeForComparison(sourceId)) {
        matchedId = selected;
        break;
      }
    }
    
    if (matchedId != null) {
      tempSelectedSources.remove(matchedId);
      print("➖ Kaynak kaldırıldı: $matchedId");
    } else {
      tempSelectedSources.add(sourceId);
      print("➕ Kaynak eklendi: $sourceId");
    }
    // NOT: Artık otomatik kaydetmiyor!
  }

  /// Check if a source is selected (GEÇİCİ state'den kontrol)
  /// Hem ID hem name ile kontrol eder
  bool isSourceSelected(String sourceId) {
    // Direkt eşleşme
    if (tempSelectedSources.contains(sourceId)) {
      return true;
    }
    
    // Normalize edilmiş eşleşme
    final normalizedId = _normalizeForComparison(sourceId);
    for (final selected in tempSelectedSources) {
      final normalizedSelected = _normalizeForComparison(selected);
      if (normalizedId == normalizedSelected) {
        return true;
      }
      // Kaynak adı ile de kontrol et
      if (sourceId.toLowerCase() == selected.toLowerCase()) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Karşılaştırma için normalize et
  String _normalizeForComparison(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .trim();
  }

  /// Select all sources in a category (GEÇİCİ)
  void selectAllInCategory(String categoryId) {
    final sources = _getSourcesInCategory(categoryId);
    for (final sourceId in sources) {
      tempSelectedSources.add(sourceId);
    }
  }

  /// Deselect all sources in a category (GEÇİCİ)
  void deselectAllInCategory(String categoryId) {
    final sources = _getSourcesInCategory(categoryId);
    for (final sourceId in sources) {
      tempSelectedSources.remove(sourceId);
    }
  }

  /// Toggle all sources in a category (GEÇİCİ)
  void toggleCategorySelection(String categoryId) {
    if (isCategoryFullySelected(categoryId)) {
      deselectAllInCategory(categoryId);
    } else {
      selectAllInCategory(categoryId);
    }
  }

  /// Get source IDs in a category
  List<String> _getSourcesInCategory(String categoryId) {
    // Try dynamic first
    if (useDynamicSources.value && dynamicCategories.isNotEmpty) {
      final category = dynamicCategories.firstWhereOrNull(
        (c) => c.id == categoryId || c.name == categoryId
      );
      if (category != null) {
        // Name kullan (NewsService ile uyumlu)
        return category.sources.map((s) => s.name).toList();
      }
    }
    
    // Fallback to static
    final staticCategory = getCategoryById(categoryId);
    if (staticCategory != null) {
      // Name kullan (NewsService ile uyumlu)
      return staticCategory.sources.map((s) => s.name).toList();
    }
    
    return [];
  }

  /// Check if all sources in a category are selected (GEÇİCİ state)
  bool isCategoryFullySelected(String categoryId) {
    final sources = _getSourcesInCategory(categoryId);
    if (sources.isEmpty) return false;
    return sources.every((name) => isSourceSelected(name));
  }

  /// Check if any source in a category is selected (GEÇİCİ state)
  bool isCategoryPartiallySelected(String categoryId) {
    final sources = _getSourcesInCategory(categoryId);
    if (sources.isEmpty) return false;
    final selectedCount = sources.where((name) => isSourceSelected(name)).length;
    return selectedCount > 0 && selectedCount < sources.length;
  }

  /// Get count of selected sources in a category (GEÇİCİ state)
  int getSelectedCountInCategory(String categoryId) {
    final sources = _getSourcesInCategory(categoryId);
    return sources.where((name) => isSourceSelected(name)).length;
  }

  /// Get total source count in a category
  int getTotalCountInCategory(String categoryId) {
    return _getSourcesInCategory(categoryId).length;
  }

  /// Select all sources (GEÇİCİ)
  void selectAll() {
    tempSelectedSources.clear();
    
    if (useDynamicSources.value && dynamicCategories.isNotEmpty) {
      for (final category in dynamicCategories) {
        for (final source in category.sources) {
          tempSelectedSources.add(source.id);
        }
      }
    } else {
      tempSelectedSources.addAll(getAllSourceIds().toSet());
    }
  }

  /// Deselect all sources (GEÇİCİ)
  void deselectAll() {
    tempSelectedSources.clear();
  }

  /// Get total selected count (GEÇİCİ state)
  int get totalSelectedCount => tempSelectedSources.length;
  
  /// Kayıtlı kaynak sayısı
  int get savedSourcesCount => _savedSources.length;

  /// Get total available sources count
  int get totalSourcesCount {
    if (useDynamicSources.value && dynamicCategories.isNotEmpty) {
      return dynamicCategories.fold<int>(0, (total, c) => total + c.sources.length);
    }
    return getAllSourceIds().length;
  }

  /// Force sync with Firestore
  Future<void> syncWithFirestore() async {
    await _loadSources();
    await _loadDynamicSources();
  }
  
  /// Tüm verileri temizle (hesap silme/çıkış için)
  void clearAllData() {
    // Bellekteki verileri temizle
    _savedSources.clear();
    tempSelectedSources.clear();
    subscribedCategories.clear();
    
    // Local storage'ı temizle
    _storage.remove(_selectedSourcesKey);
    _storage.remove(_subscribedCategoriesKey);
    
    print('🗑️ SourceSelectionController tüm veriler temizlendi');
  }
}
