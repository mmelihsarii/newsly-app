import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/news_model.dart';
import '../models/featured_section_model.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';
import '../utils/news_sources_data.dart';
import 'source_selection_controller.dart';

class HomeController extends GetxController {
  // Services
  late final ApiService _apiService;

  // Source Selection Controller
  SourceSelectionController? _sourceController;

  // Reaktif değişkenler
  var isLoading = false.obs;

  // Featured Sections (Admin Panel'den gelen)
  var sliderSections = <FeaturedSectionModel>[].obs; // type: slider
  var newsSections =
      <FeaturedSectionModel>[].obs; // type: breaking_news, horizontal_list vs.
  var isFeaturedLoading = false.obs;

  // Featured slider için controller'lar
  final Map<int, PageController> featuredSliderControllers = {};
  final Map<int, int> featuredSliderIndices = {};
  final Map<int, Timer?> featuredSliderTimers = {};

  // Arama state
  var isSearchOpen = false.obs;

  // Scroll Controller
  late final ScrollController scrollController;

  // Disposed flag
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    _apiService = ApiService();
    scrollController = ScrollController();

    // SourceSelectionController'ı al veya oluştur
    if (Get.isRegistered<SourceSelectionController>()) {
      _sourceController = Get.find<SourceSelectionController>();
    } else {
      _sourceController = Get.put(SourceSelectionController());
    }

    // Kaynak seçimi değiştiğinde haberleri yenile
    if (_sourceController != null) {
      ever(_sourceController!.selectedSources, (_) {
        if (!_isDisposed) {
          print("🔄 Kaynak seçimi değişti, haberler yenileniyor...");
          fetchFeaturedSections();
        }
      });
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await fetchFeaturedSections();
  }

  @override
  void onClose() {
    _isDisposed = true;

    for (var timer in featuredSliderTimers.values) {
      timer?.cancel();
    }
    featuredSliderTimers.clear();

    for (var controller in featuredSliderControllers.values) {
      controller.dispose();
    }
    featuredSliderControllers.clear();

    scrollController.dispose();
    super.onClose();
  }

  // ===== PANEL'DEN FEATURED SECTIONS =====
  Future<void> fetchFeaturedSections() async {
    if (_isDisposed) return;

    try {
      isFeaturedLoading(true);
      isLoading(true);
      print("🎯 Panel'den Featured Sections çekiliyor...");

      final response = await _apiService.getData(
        ApiConstants.getFeaturedSections,
      );

      print("📦 API Response: $response");

      if (_isDisposed) return;

      if (response != null) {
        List<FeaturedSectionModel> allSections = [];

        if (response is List) {
          allSections = response
              .map(
                (item) =>
                    FeaturedSectionModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else if (response is Map && response['data'] != null) {
          allSections = (response['data'] as List)
              .map(
                (item) =>
                    FeaturedSectionModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else if (response is Map && response['sections'] != null) {
          allSections = (response['sections'] as List)
              .map(
                (item) =>
                    FeaturedSectionModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }

        print("📋 Toplam ${allSections.length} section parse edildi");
        for (var s in allSections) {
          print(
            "   - ID: ${s.id}, Title: ${s.title}, Type: ${s.type}, Active: ${s.isActive}, News: ${s.news.length}",
          );
        }

        // Aktif olanları filtrele
        allSections = allSections
            .where((s) => s.isActive == true && s.news.isNotEmpty)
            .toList();
        allSections.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

        // Kullanıcının seçtiği kaynaklara göre haberleri filtrele
        allSections = _filterSectionsByUserSources(allSections);

        // Slider'ları ayır (type: slider)
        final sliders = allSections
            .where((s) => s.type == 'slider' && s.news.isNotEmpty)
            .toList();

        // Haber listelerini ayır (type: breaking_news, horizontal_list, vs.)
        final newsLists = allSections
            .where((s) => s.type != 'slider' && s.news.isNotEmpty)
            .toList();

        sliderSections.value = sliders;
        newsSections.value = newsLists;

        print("✅ ${sliders.length} slider section yüklendi");
        print("✅ ${newsLists.length} haber section yüklendi");

        // Eski controller'ları temizle
        _cleanupSliderControllers();

        // Slider'lar için controller'ları oluştur
        for (var section in sliders) {
          if (section.id != null) {
            featuredSliderControllers[section.id!] = PageController();
            featuredSliderIndices[section.id!] = 0;
            _startSliderAutoScroll(section.id!);
          }
        }
      }
    } catch (e) {
      print("❌ Featured Sections Hatası: $e");
    } finally {
      if (!_isDisposed) {
        isFeaturedLoading(false);
        isLoading(false);
      }
    }
  }

  /// Türkçe karakterleri ve özel karakterleri normalize et
  String _normalizeForMatch(String input) {
    const Map<String, String> turkishChars = {
      'ı': 'i',
      'İ': 'i',
      'ğ': 'g',
      'Ğ': 'g',
      'ü': 'u',
      'Ü': 'u',
      'ş': 's',
      'Ş': 's',
      'ö': 'o',
      'Ö': 'o',
      'ç': 'c',
      'Ç': 'c',
    };
    String normalized = input.toLowerCase().trim();
    turkishChars.forEach((k, v) => normalized = normalized.replaceAll(k, v));
    // Sadece harf ve rakam bırak
    return normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Kullanıcının seçtiği kaynaklara göre section'ları filtrele
  ///
  /// Mantık:
  /// 1. Kullanıcının Firestore'daki selectedSources listesini al (ID'ler)
  /// 2. ID'leri kaynak isimlerine çevir (news_sources_data.dart kullanarak)
  /// 3. Her section'daki haberleri filtrele
  /// 4. Boş kalan section'ları listeden çıkar
  List<FeaturedSectionModel> _filterSectionsByUserSources(
    List<FeaturedSectionModel> sections,
  ) {
    // Kullanıcının seçtiği kaynak ID'lerini al
    final Set<String> selectedSourceIds =
        _sourceController?.selectedSources ?? {};

    // Eğer hiç kaynak seçilmemişse, tüm haberleri göster
    if (selectedSourceIds.isEmpty) {
      print("📰 Kaynak seçimi yok - tüm haberler gösteriliyor");
      return sections.where((s) => s.news.isNotEmpty).toList();
    }

    // Seçili ID'leri normalize et (örn: "cnn_turk" -> "cnnturk")
    final Set<String> selectedIdsNormalized = selectedSourceIds
        .map((id) => _normalizeForMatch(id))
        .toSet();

    // Seçili ID'leri kaynak isimlerine çevir ve normalize et
    final Set<String> selectedNamesNormalized = selectedSourceIds
        .map((id) => getSourceById(id)?.name)
        .whereType<String>()
        .map((name) => _normalizeForMatch(name))
        .toSet();

    print(
      "🔍 Aktif kaynaklar (${selectedSourceIds.length}): IDs=$selectedIdsNormalized, Names=$selectedNamesNormalized",
    );

    // Her section'ı filtrele
    final List<FeaturedSectionModel> filteredSections = [];
    int newsWithEmptySource = 0;

    for (final section in sections) {
      // Section içindeki haberleri filtrele
      final List<NewsModel> filteredNews = section.news.where((news) {
        final String? newsSourceName = news.sourceName?.trim();
        final String? categoryName = news.categoryName?.trim();

        // "genel" seçiliyse TÜM haberleri göster (backend düzelene kadar)
        if (selectedIdsNormalized.contains('genel') ||
            selectedNamesNormalized.contains('genel')) {
          return true;
        }

        // Kaynak adını normalize et
        String? normalizedNewsSource;
        if (newsSourceName != null &&
            newsSourceName.isNotEmpty &&
            _normalizeForMatch(newsSourceName) != 'genel') {
          normalizedNewsSource = _normalizeForMatch(newsSourceName);
        }

        // Kaynak adı varsa normal eşleştirme yap
        if (normalizedNewsSource != null) {
          final bool matchesId = selectedIdsNormalized.any(
            (id) =>
                normalizedNewsSource!.contains(id) ||
                id.contains(normalizedNewsSource),
          );
          final bool matchesName = selectedNamesNormalized.any(
            (name) =>
                normalizedNewsSource!.contains(name) ||
                name.contains(normalizedNewsSource),
          );
          if (matchesId || matchesName) return true;
        }

        // Kaynak adı yoksa categoryName ile eşleştir
        newsWithEmptySource++;
        if (categoryName != null && categoryName.isNotEmpty) {
          final String normalizedCategory = _normalizeForMatch(categoryName);

          // Genişletilmiş kategori → kaynak eşleştirmesi
          final Map<String, List<String>> categoryToSourceMap = {
            'spor': [
              'aspor',
              'a_spor',
              'ntvspor',
              'ntv_spor',
              'sporx',
              'fotomac',
              'fanatik',
              'beinsports',
              'bein',
            ],
            'ekonomi': [
              'bloomberght',
              'bloomberg',
              'bigpara',
              'paraanaliz',
              'dunya',
              'ekonomi',
            ],
            'finans': ['bloomberght', 'bloomberg', 'bigpara', 'paraanaliz'],
            'teknoloji': [
              'webtekno',
              'donanimhaber',
              'shiftdelete',
              'technopat',
              'log',
              'chip',
              'tekno',
            ],
            'saglik': ['memorial', 'medicalpark', 'acibadem', 'saglik'],
            'kultur': ['kulturservisi', 'arkeofili', 'kultur', 'sanat'],
            'bilim': ['bilimfili', 'evrimagaci', 'popular', 'bilim'],
            'gundem': [
              'ntv',
              'cnnturk',
              'cnn',
              'haberturk',
              'trthaber',
              'trt',
              'ahaber',
              'a_haber',
            ],
            'dunya': ['bbc', 'dw', 'euronews', 'sputnik', 'reuters'],
            'magazin': ['magazin', 'hurriyet', 'milliyet', 'sabah'],
            'yasam': ['yasam', 'saglik', 'kadin'],
            'otomobil': ['otomobil', 'araba', 'oto'],
          };

          for (final entry in categoryToSourceMap.entries) {
            if (normalizedCategory.contains(entry.key) ||
                entry.key.contains(normalizedCategory)) {
              for (final sourceId in entry.value) {
                if (selectedIdsNormalized.any(
                      (id) => id.contains(sourceId) || sourceId.contains(id),
                    ) ||
                    selectedNamesNormalized.any(
                      (n) => n.contains(sourceId) || sourceId.contains(n),
                    )) {
                  return true;
                }
              }
            }
          }
        }

        return false;
      }).toList();

      // Eğer section'da haber kaldıysa, listeye ekle
      if (filteredNews.isNotEmpty) {
        filteredSections.add(
          FeaturedSectionModel(
            id: section.id,
            title: section.title,
            type: section.type,
            order: section.order,
            isActive: section.isActive,
            news: filteredNews,
          ),
        );
      }
    }

    final totalOriginalNews = sections.fold<int>(
      0,
      (sum, s) => sum + s.news.length,
    );
    final totalFilteredNews = filteredSections.fold<int>(
      0,
      (sum, s) => sum + s.news.length,
    );
    print(
      "📊 Filtreleme: $totalOriginalNews haber → $totalFilteredNews haber (${sections.length} section → ${filteredSections.length} section)",
    );
    if (newsWithEmptySource > 0) {
      print(
        "⚠️ Kaynak adı boş olan $newsWithEmptySource haber gösteriliyor (backend düzeltilene kadar)",
      );
    }

    return filteredSections;
  }

  void _cleanupSliderControllers() {
    for (var timer in featuredSliderTimers.values) {
      timer?.cancel();
    }
    featuredSliderTimers.clear();

    for (var controller in featuredSliderControllers.values) {
      controller.dispose();
    }
    featuredSliderControllers.clear();
    featuredSliderIndices.clear();
  }

  void _startSliderAutoScroll(int sectionId) {
    if (_isDisposed) return;

    featuredSliderTimers[sectionId]?.cancel();

    final section = sliderSections.firstWhereOrNull((s) => s.id == sectionId);
    if (section == null || section.news.isEmpty) return;

    featuredSliderTimers[sectionId] = Timer.periodic(
      const Duration(seconds: 4),
      (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        final controller = featuredSliderControllers[sectionId];
        if (controller == null || !controller.hasClients) return;

        final currentIndex = featuredSliderIndices[sectionId] ?? 0;
        final nextIndex = (currentIndex + 1) % section.news.length;

        controller.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
        featuredSliderIndices[sectionId] = nextIndex;
      },
    );
  }

  void updateSliderIndex(int sectionId, int index) {
    featuredSliderIndices[sectionId] = index;
  }

  // Refresh
  Future<void> refreshNews() async {
    if (_isDisposed) return;
    await fetchFeaturedSections();
  }
}
