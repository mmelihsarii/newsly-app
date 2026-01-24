import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/source_model.dart';
import '../services/source_service.dart';
import '../services/news_service.dart';
import '../utils/news_sources_data.dart';

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

  // Selected source IDs
  RxSet<String> selectedSources = <String>{}.obs;
  
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
      if (selectedSources.isEmpty && _userId != null) {
        await _syncWithFirestore();
      } else if (_userId != null) {
        // Background sync
        _syncWithFirestore().catchError((e) {
          print("⚠️ Arka plan senkronizasyon hatası: $e");
        });
      }
    } catch (e) {
      print('❌ Kaynak yükleme hatası: $e');
      if (selectedSources.isEmpty) _loadFromLocalStorage();
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
          
          if (!_setEquals(selectedSources, newSources)) {
            print('☁️ Firestore\'dan güncelleme: ${selectedSources.length} → ${newSources.length}');
            selectedSources.assignAll(newSources);
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
      selectedSources.clear();
      selectedSources.addAll(stored.cast<String>().toSet());
      print('📱 Yerel depodan ${selectedSources.length} kaynak yüklendi');
    } else {
      selectedSources.clear();
      print('🆕 Varsayılan olarak hiçbir kaynak seçili değil');
    }
  }

  void _saveToLocalStorage() {
    _storage.write(_selectedSourcesKey, selectedSources.toList());
  }

  Future<void> _saveToFirestore() async {
    if (_userId == null) return;

    try {
      await _db.collection('users').doc(_userId).set({
        'selectedSources': selectedSources.toList(),
        'followed_source_ids': selectedSources.toList(),
        'selectedSourcesUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('☁️ Firestore\'a ${selectedSources.length} kaynak kaydedildi');
    } catch (e) {
      print('❌ Firestore kaydetme hatası: $e');
    }
  }

  Future<void> _saveAll() async {
    _saveToLocalStorage();
    await _saveToFirestore();
    await _updateCategorySubscriptions();
    
    // NewsService cache'ini temizle - yeni kaynak seçimiyle haberler yenilensin
    _clearNewsServiceCache();
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
      
      for (final sourceId in selectedSources) {
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

  /// Toggle a single source selection
  Future<void> toggleSource(String sourceId) async {
    print("🖱️ Toggle Source: $sourceId");
    if (selectedSources.contains(sourceId)) {
      selectedSources.remove(sourceId);
    } else {
      selectedSources.add(sourceId);
    }
    await _saveAll();
  }

  /// Check if a source is selected
  bool isSourceSelected(String sourceId) {
    return selectedSources.contains(sourceId);
  }

  /// Select all sources in a category (works with both dynamic and static)
  Future<void> selectAllInCategory(String categoryId) async {
    final sources = _getSourcesInCategory(categoryId);
    for (final sourceId in sources) {
      selectedSources.add(sourceId);
    }
    await _saveAll();
  }

  /// Deselect all sources in a category
  Future<void> deselectAllInCategory(String categoryId) async {
    final sources = _getSourcesInCategory(categoryId);
    for (final sourceId in sources) {
      selectedSources.remove(sourceId);
    }
    await _saveAll();
  }

  /// Toggle all sources in a category
  Future<void> toggleCategorySelection(String categoryId) async {
    if (isCategoryFullySelected(categoryId)) {
      await deselectAllInCategory(categoryId);
    } else {
      await selectAllInCategory(categoryId);
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
        return category.sources.map((s) => s.id).toList();
      }
    }
    
    // Fallback to static
    final staticCategory = getCategoryById(categoryId);
    if (staticCategory != null) {
      return staticCategory.sources.map((s) => s.id).toList();
    }
    
    return [];
  }

  /// Check if all sources in a category are selected
  bool isCategoryFullySelected(String categoryId) {
    final sources = _getSourcesInCategory(categoryId);
    if (sources.isEmpty) return false;
    return sources.every((id) => selectedSources.contains(id));
  }

  /// Check if any source in a category is selected
  bool isCategoryPartiallySelected(String categoryId) {
    final sources = _getSourcesInCategory(categoryId);
    if (sources.isEmpty) return false;
    final selectedCount = sources.where((id) => selectedSources.contains(id)).length;
    return selectedCount > 0 && selectedCount < sources.length;
  }

  /// Get count of selected sources in a category
  int getSelectedCountInCategory(String categoryId) {
    final sources = _getSourcesInCategory(categoryId);
    return sources.where((id) => selectedSources.contains(id)).length;
  }

  /// Get total source count in a category
  int getTotalCountInCategory(String categoryId) {
    return _getSourcesInCategory(categoryId).length;
  }

  /// Select all sources
  Future<void> selectAll() async {
    selectedSources.clear();
    
    if (useDynamicSources.value && dynamicCategories.isNotEmpty) {
      for (final category in dynamicCategories) {
        for (final source in category.sources) {
          selectedSources.add(source.id);
        }
      }
    } else {
      selectedSources.addAll(getAllSourceIds().toSet());
    }
    
    await _saveAll();
  }

  /// Deselect all sources
  Future<void> deselectAll() async {
    selectedSources.clear();
    
    // Tüm kategori aboneliklerinden çık
    for (final catId in subscribedCategories.toList()) {
      await _unsubscribeFromCategory(catId);
    }
    subscribedCategories.clear();
    _storage.write(_subscribedCategoriesKey, []);
    
    _saveToLocalStorage();
    await _saveToFirestore();
  }

  /// Get total selected count
  int get totalSelectedCount => selectedSources.length;

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
}
