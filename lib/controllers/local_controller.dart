import 'package:get/get.dart';
import '../models/news_model.dart';
import '../services/local_news_service.dart';
import '../utils/city_data.dart';

class LocalController extends GetxController {
  final LocalNewsService _localNewsService = LocalNewsService();

  // Kaynak listesi (dinamik veya statik)
  var sourceList = <Map<String, dynamic>>[].obs;
  var selectedSource = Rxn<Map<String, dynamic>>();

  // Dinamik kaynaklar
  var dynamicSources = <LocalSource>[].obs;
  var useDynamicSources = false.obs;

  // Haber listesi
  var localNewsList = <NewsModel>[].obs;

  // Loading states
  var isCitiesLoading = false.obs;
  var isNewsLoading = false.obs;

  // Eski API uyumluluğu için
  RxList<Map<String, dynamic>> get cityList => sourceList;

  @override
  void onInit() {
    super.onInit();
    loadSources();
  }

  /// Kaynakları yükle - önce Firestore'dan "Yerel Haberler" kategorisini dene
  Future<void> loadSources() async {
    isCitiesLoading.value = true;

    try {
      print('🔄 Yerel haber kaynakları yükleniyor...');
      final sources = await _localNewsService.fetchLocalSources(forceRefresh: true);

      if (sources.isNotEmpty) {
        // Dinamik kaynaklar var (news_sources'dan Yerel Haberler kategorisi)
        dynamicSources.assignAll(sources);
        useDynamicSources.value = true;

        // Map formatına çevir (UI uyumluluğu için)
        sourceList.assignAll(sources.map((s) => {
          'name': s.name,
          'rss': s.rssUrl,
          'id': s.id,
          'category': s.category,
        }).toList());

        print('✅ Firestore\'dan ${sources.length} yerel kaynak yüklendi');
        
        // Debug: Kaynakları listele
        for (var s in sources) {
          print('   📍 ${s.name}: ${s.rssUrl}');
        }
      } else {
        // Statik şehir verilerini kullan (fallback)
        useDynamicSources.value = false;
        sourceList.assignAll(CityData.cities);
        print('📦 Statik ${CityData.cities.length} şehir yüklendi (fallback)');
      }

      // İlk kaynağı varsayılan olarak seç
      if (sourceList.isNotEmpty) {
        selectedSource.value = sourceList.first;
        print('🎯 Varsayılan kaynak seçildi: ${selectedSource.value?['name']}');
        await fetchLocalNews();
      }
    } catch (e) {
      print('❌ Kaynak yükleme hatası: $e');
      // Hata durumunda statik verileri kullan
      useDynamicSources.value = false;
      sourceList.assignAll(CityData.cities);
      if (sourceList.isNotEmpty) {
        selectedSource.value = sourceList.first;
        await fetchLocalNews();
      }
    } finally {
      isCitiesLoading.value = false;
    }
  }

  /// Eski API uyumluluğu
  Future<void> loadCities() => loadSources();

  /// Kaynakları yenile
  Future<void> refreshSources() async {
    await loadSources();
  }

  /// Seçilen kaynağın haberlerini çek
  Future<void> fetchLocalNews() async {
    if (selectedSource.value == null) {
      print('⚠️ Seçili kaynak yok');
      return;
    }

    try {
      isNewsLoading.value = true;
      localNewsList.clear();

      final sourceName = selectedSource.value!['name'] ?? '';
      final rssUrl = selectedSource.value!['rss'] ?? '';

      print('📡 Yerel haber çekiliyor: $sourceName');
      print('   RSS URL: $rssUrl');

      if (rssUrl.isEmpty) {
        print('⚠️ RSS linki bulunamadı: $sourceName');
        return;
      }

      // LocalNewsService kullanarak haberleri çek
      final news = await _localNewsService.fetchNewsForSource(sourceName, rssUrl);
      localNewsList.assignAll(news);

      print('✅ $sourceName: ${news.length} haber yüklendi');
    } catch (e) {
      print('❌ Yerel haber çekme hatası: $e');
    } finally {
      isNewsLoading.value = false;
    }
  }

  /// Kaynak seç (eski API: selectCity)
  void selectSource(Map<String, dynamic> source) {
    selectedSource.value = source;
    fetchLocalNews();
  }

  /// Eski API uyumluluğu
  void selectCity(Map<String, dynamic> city) => selectSource(city);
  Rxn<Map<String, dynamic>> get selectedCity => selectedSource;

  /// Kaynak ara
  List<Map<String, dynamic>> searchSources(String query) {
    if (query.isEmpty) return sourceList;
    
    final normalizedQuery = _normalizeText(query);
    return sourceList.where((source) {
      final sourceName = _normalizeText(source['name'] ?? '');
      return sourceName.contains(normalizedQuery);
    }).toList();
  }

  String _normalizeText(String text) {
    const Map<String, String> turkishChars = {
      'ı': 'i', 'İ': 'i', 'ğ': 'g', 'Ğ': 'g',
      'ü': 'u', 'Ü': 'u', 'ş': 's', 'Ş': 's',
      'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
    };

    String normalized = text.toLowerCase();
    turkishChars.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    return normalized;
  }
}
