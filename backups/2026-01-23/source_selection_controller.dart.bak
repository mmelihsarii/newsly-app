import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/news_sources_data.dart';

/// Controller for managing news source selection with Firestore sync
class SourceSelectionController extends GetxController {
  final GetStorage _storage = GetStorage();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Storage key for offline cache
  static const String _selectedSourcesKey = 'selected_sources';

  // Selected source IDs
  RxSet<String> selectedSources = <String>{}.obs;

  // Loading state
  var isLoading = false.obs;
  var isSaving = false.obs;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _loadSources();
  }

  /// Load sources: Offline-first strategy
  /// 1. Load from local storage immediately (fastest, most up-to-date user action)
  /// 2. Then check Firestore for remote updates (background sync)
  Future<void> _loadSources() async {
    isLoading.value = true;

    try {
      // 1. Önce yerel depodan yükle (Hızlı ve kullanıcının son seçimi buradadır)
      _loadFromLocalStorage();

      // Eğer yerel depo boşsa veya ilk yüklemeyse Firestore'a bak
      if (selectedSources.isEmpty && _userId != null) {
        await _syncWithFirestore();
      } else {
        // Yerel veri varsa bile arka planda Firestore ile senkronize et
        // (ama UI'ı bloklama ve mevcut seçimi ezme)
        _syncWithFirestore()
            .then((_) {
              print("☁️ Firestore ile arka plan senkronizasyonu tamamlandı");
            })
            .catchError((e) {
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
        final List<dynamic>? firestoreSources = data?['selectedSources'];

        if (firestoreSources != null && firestoreSources.isNotEmpty) {
          // Firestore'dan gelen veriyi HER ZAMAN kullan (en güncel kaynak)
          final newSources = firestoreSources.cast<String>().toSet();
          
          // Eğer farklıysa güncelle
          if (!_setEquals(selectedSources, newSources)) {
            print('☁️ Firestore\'dan güncelleme: $selectedSources → $newSources');
            selectedSources.assignAll(newSources);
            _saveToLocalStorage(); // Yerel depoyu da güncelle
          }
          print('✅ Firestore\'dan ${selectedSources.length} kaynak yüklendi: $selectedSources');
        }
      }
    } catch (e) {
      print("Firestore okuma hatası: $e");
    }
  }

  // İki Set'in eşit olup olmadığını kontrol et
  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.every((element) => b.contains(element));
  }

  /// Load from local storage (offline cache)
  void _loadFromLocalStorage() {
    final List<dynamic>? stored = _storage.read<List<dynamic>>(
      _selectedSourcesKey,
    );
    if (stored != null && stored.isNotEmpty) {
      selectedSources.clear();
      selectedSources.addAll(stored.cast<String>().toSet());
      print('📱 Yerel depodan ${selectedSources.length} kaynak yüklendi: $selectedSources');
    } else {
      // Default: NO sources selected - user should manually pick
      selectedSources.clear();
      // Don't auto-save empty selection, let user choose first
      print('🆕 Varsayılan olarak hiçbir kaynak seçili değil');
    }
  }

  /// Save to local storage (for offline cache)
  void _saveToLocalStorage() {
    _storage.write(_selectedSourcesKey, selectedSources.toList());
  }

  /// Save to Firestore
  Future<void> _saveToFirestore() async {
    if (_userId == null) return;

    try {
      await _db.collection('users').doc(_userId).set({
        'selectedSources': selectedSources.toList(),
        'selectedSourcesUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('☁️ Firestore\'a ${selectedSources.length} kaynak kaydedildi');
    } catch (e) {
      print('❌ Firestore kaydetme hatası: $e');
    }
  }

  /// Save to both local storage and Firestore
  Future<void> _saveAll() async {
    _saveToLocalStorage();
    await _saveToFirestore();
  }

  /// Toggle a single source selection
  Future<void> toggleSource(String sourceId) async {
    print("🖱️ Toggle Source Tıklandı: $sourceId");
    if (selectedSources.contains(sourceId)) {
      selectedSources.remove(sourceId);
      print("🗑️ Kaynak silindi. Güncel liste: $selectedSources");
    } else {
      selectedSources.add(sourceId);
      print("➕ Kaynak eklendi. Güncel liste: $selectedSources");
    }
    // Hemen kaydet (hem yerel hem Firestore)
    await _saveAll();
    print("💾 Kaydedildi: $selectedSources");
  }

  /// Check if a source is selected
  bool isSourceSelected(String sourceId) {
    return selectedSources.contains(sourceId);
  }

  /// Select all sources in a category
  Future<void> selectAllInCategory(String categoryId) async {
    final category = getCategoryById(categoryId);
    if (category != null) {
      for (final source in category.sources) {
        selectedSources.add(source.id);
      }
      await _saveAll();
    }
  }

  /// Deselect all sources in a category
  Future<void> deselectAllInCategory(String categoryId) async {
    final category = getCategoryById(categoryId);
    if (category != null) {
      for (final source in category.sources) {
        selectedSources.remove(source.id);
      }
      await _saveAll();
    }
  }

  /// Toggle all sources in a category
  Future<void> toggleCategorySelection(String categoryId) async {
    if (isCategoryFullySelected(categoryId)) {
      await deselectAllInCategory(categoryId);
    } else {
      await selectAllInCategory(categoryId);
    }
  }

  /// Check if all sources in a category are selected
  bool isCategoryFullySelected(String categoryId) {
    final category = getCategoryById(categoryId);
    if (category == null) return false;
    return category.sources.every((s) => selectedSources.contains(s.id));
  }

  /// Check if any source in a category is selected
  bool isCategoryPartiallySelected(String categoryId) {
    final category = getCategoryById(categoryId);
    if (category == null) return false;
    final selectedCount = category.sources
        .where((s) => selectedSources.contains(s.id))
        .length;
    return selectedCount > 0 && selectedCount < category.sources.length;
  }

  /// Get count of selected sources in a category
  int getSelectedCountInCategory(String categoryId) {
    final category = getCategoryById(categoryId);
    if (category == null) return 0;
    return category.sources.where((s) => selectedSources.contains(s.id)).length;
  }

  /// Get total source count in a category
  int getTotalCountInCategory(String categoryId) {
    final category = getCategoryById(categoryId);
    return category?.sources.length ?? 0;
  }

  /// Select all sources
  Future<void> selectAll() async {
    selectedSources.clear();
    selectedSources.addAll(getAllSourceIds().toSet());
    await _saveAll();
  }

  /// Deselect all sources
  Future<void> deselectAll() async {
    selectedSources.clear();
    await _saveAll();
  }

  /// Get total selected count
  int get totalSelectedCount => selectedSources.length;

  /// Get total available sources count
  int get totalSourcesCount => getAllSourceIds().length;

  /// Force sync with Firestore (useful after login)
  Future<void> syncWithFirestore() async {
    await _loadSources();
  }
}
