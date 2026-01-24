import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import '../models/source_model.dart';

class FollowController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  var isLoading = false.obs;
  var allSources = <SourceModel>[].obs;
  var selectedSources = <SourceModel>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSources();
  }

  /// Firestore'dan tüm aktif kaynakları çek ve seçilenleri filtrele
  Future<void> fetchSources() async {
    try {
      isLoading(true);
      errorMessage('');

      // Kullanıcının seçtiği kaynak ID'lerini al
      final selectedIds = await _getSelectedSourceIds();
      print('📌 Seçili kaynak sayısı: ${selectedIds.length}');

      final snapshot = await _firestore
          .collection('news_sources')
          .where('is_active', isEqualTo: true)
          .get();

      final sources = snapshot.docs
          .map((doc) => SourceModel.fromFirestore(doc))
          .where((s) => s.rssUrl.isNotEmpty)
          .toList();

      allSources.value = sources;

      // Seçili kaynakları filtrele
      if (selectedIds.isNotEmpty) {
        final filtered = sources.where((s) {
          final normalizedId = _normalizeSourceName(s.id);
          final normalizedName = _normalizeSourceName(s.name);
          
          for (final selectedId in selectedIds) {
            final normalizedSelected = _normalizeSourceName(selectedId);
            if (s.id == selectedId ||
                s.name.toLowerCase() == selectedId.toLowerCase() ||
                normalizedId == normalizedSelected ||
                normalizedName == normalizedSelected) {
              return true;
            }
          }
          return false;
        }).toList();

        filtered.sort((a, b) => a.name.compareTo(b.name));
        selectedSources.value = filtered;
        print('✅ ${filtered.length} seçili kaynak yüklendi');
      } else {
        selectedSources.clear();
        print('⚠️ Hiç kaynak seçilmemiş');
      }

    } catch (e) {
      print('❌ Kaynak yükleme hatası: $e');
      errorMessage('Kaynaklar yüklenirken bir hata oluştu');
    } finally {
      isLoading(false);
    }
  }

  /// Kullanıcının seçtiği kaynak ID'lerini al
  Future<Set<String>> _getSelectedSourceIds() async {
    final List<dynamic>? localSources = _storage.read<List<dynamic>>('selected_sources');
    if (localSources != null && localSources.isNotEmpty) {
      return localSources.cast<String>().toSet();
    }
    return {};
  }

  /// Kaynak adını normalize et
  String _normalizeSourceName(String name) {
    const Map<String, String> turkishChars = {
      'ı': 'i', 'İ': 'i', 'ğ': 'g', 'Ğ': 'g', 'ü': 'u', 'Ü': 'u',
      'ş': 's', 'Ş': 's', 'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
      ' ': '_', '-': '_', '.': '', ',': '', '&': '',
    };

    String normalized = name.toLowerCase().trim();
    turkishChars.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    normalized = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return normalized;
  }

  /// Kaynakları yenile
  Future<void> refreshSources() async {
    await fetchSources();
  }

  /// Seçili kaynak var mı?
  bool get hasSelectedSources => selectedSources.isNotEmpty;

  /// Kategoriye göre seçili kaynakları getir
  List<SourceModel> getSelectedByCategory(String category) {
    return selectedSources.where((s) => s.category == category).toList();
  }

  /// Seçili kaynakların kategorilerini getir
  List<String> get selectedCategories {
    final cats = selectedSources.map((s) => s.category).toSet().toList();
    cats.sort();
    return cats;
  }
}
