import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/news_model.dart';
import '../models/featured_section_model.dart';
import '../services/api_service.dart';
import '../services/news_service.dart';
import '../utils/api_constants.dart';
import '../utils/news_sources_data.dart';
import 'source_selection_controller.dart';

class HomeController extends GetxController {
  // Services
  late final ApiService _apiService;
  late final NewsService _newsService;

  // Source Selection Controller
  SourceSelectionController? _sourceController;

  // Reaktif değişkenler
  var isLoading = false.obs;

  // Featured Sections (Admin Panel'den gelen)
  var sliderSections = <FeaturedSectionModel>[].obs; // type: slider
  var newsSections =
      <FeaturedSectionModel>[].obs; // type: breaking_news, horizontal_list vs.
  var isFeaturedLoading = false.obs;
  
  // RSS'ten gelen haberler (kullanıcı seçimine göre filtrelenmiş)
  var rssNews = <NewsModel>[].obs;
  
  // Pagination için
  static const int _pageSize = 15; // Her seferde 15 haber
  var _allRssNews = <NewsModel>[]; // Tüm haberler (bellekte)
  var displayedNewsCount = 15.obs; // Şu an gösterilen haber sayısı
  var isLoadingMore = false.obs; // Daha fazla yükleniyor mu?
  var hasMoreNews = true.obs; // Daha fazla haber var mı?

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
    _newsService = NewsService();
    scrollController = ScrollController();
    
    // Scroll listener - infinite scroll için
    scrollController.addListener(_onScroll);

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
          _loadInitialData();
        }
      });
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Tek seferde yükle - önce her şeyi hazırla, sonra göster
    isLoading.value = true;
    isFeaturedLoading.value = true;
    
    try {
      // 1. API'den section yapısını çek (haberler olmadan)
      await _fetchSectionStructure();
      
      // 2. RSS'ten haberleri çek ve section'lara bağla
      await fetchRssNews();
    } finally {
      isLoading.value = false;
      isFeaturedLoading.value = false;
    }
  }

  /// Sadece section yapısını çek (haberleri gösterme)
  Future<void> _fetchSectionStructure() async {
    if (_isDisposed) return;

    try {
      print("🎯 Panel'den section yapısı çekiliyor...");

      final response = await _apiService.getData(
        ApiConstants.getFeaturedSections,
      );

      if (_isDisposed) return;

      if (response != null) {
        List<FeaturedSectionModel> allSections = [];

        if (response is List) {
          allSections = response
              .map((item) => FeaturedSectionModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response is Map && response['data'] != null) {
          allSections = (response['data'] as List)
              .map((item) => FeaturedSectionModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        // Aktif olanları filtrele ve sırala
        allSections = allSections.where((s) => s.isActive == true).toList();
        allSections.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

        // Section yapısını kaydet (haberler boş olacak, RSS'ten dolacak)
        final sliders = allSections.where((s) => s.type == 'slider').toList();
        final newsLists = allSections.where((s) => s.type != 'slider').toList();

        // Boş section'lar olarak kaydet (henüz gösterme)
        _tempSliderSections = sliders;
        _tempNewsSections = newsLists;

        print("📋 ${sliders.length} slider, ${newsLists.length} news section yapısı alındı");
      }
    } catch (e) {
      print("❌ Section yapısı hatası: $e");
    }
  }

  // Geçici section yapıları (RSS haberleri gelene kadar)
  List<FeaturedSectionModel> _tempSliderSections = [];
  List<FeaturedSectionModel> _tempNewsSections = [];

  /// RSS kaynaklarından haberleri çek (kullanıcı seçimine göre filtrelenmiş)
  /// [forceRefresh] true ise cache'i atlar ve taze veri çeker
  Future<void> fetchRssNews({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    
    try {
      print("📡 RSS haberler çekiliyor... (forceRefresh: $forceRefresh)");
      final news = await _newsService.fetchAllNews(forceRefresh: forceRefresh);
      
      if (!_isDisposed) {
        rssNews.value = news;
        print("✅ RSS'ten ${news.length} haber yüklendi");
        
        // RSS haberlerini FeaturedSection olarak ekle (eğer varsa)
        if (news.isNotEmpty) {
          _addRssNewsToSections(news);
        }
      }
    } catch (e) {
      print("❌ RSS haber çekme hatası: $e");
    }
  }

  /// RSS haberlerini FeaturedSections'a bağla ve TEK SEFERDE göster
  /// Pagination: Sadece ilk 15 haber gösterilir, kaydırdıkça daha fazla yüklenir
  void _addRssNewsToSections(List<NewsModel> news) {
    if (news.isEmpty) {
      print("⚠️ RSS'ten haber gelmedi");
      return;
    }

    print("🔄 RSS haberleri FeaturedSections'a bağlanıyor...");
    print("   Section yapısı: ${_tempSliderSections.length} slider, ${_tempNewsSections.length} news");
    print("   RSS haber sayısı: ${news.length}");

    // Eski controller'ları temizle
    _cleanupSliderControllers();

    // Slider section'larını RSS haberleriyle doldur (ilk 10 haber)
    if (_tempSliderSections.isNotEmpty) {
      final sliderNews = news.take(10).toList();
      final oldSlider = _tempSliderSections.first;
      
      sliderSections.value = [
        FeaturedSectionModel(
          id: oldSlider.id,
          title: oldSlider.title,
          type: oldSlider.type,
          order: oldSlider.order,
          isActive: oldSlider.isActive,
          news: sliderNews,
        )
      ];
      
      // Slider controller oluştur
      if (oldSlider.id != null) {
        featuredSliderControllers[oldSlider.id!] = PageController();
        featuredSliderIndices[oldSlider.id!] = 0;
        _startSliderAutoScroll(oldSlider.id!);
      }
      
      print("✅ Slider: ${oldSlider.title} (${sliderNews.length} haber)");
    }

    // News section - PAGINATION ile
    if (_tempNewsSections.isNotEmpty && news.length > 10) {
      // Tüm haberleri sakla (slider hariç)
      _allRssNews = news.skip(10).toList();
      
      // Pagination state'i sıfırla
      final totalNewsCount = _allRssNews.length;
      final initialCount = totalNewsCount < _pageSize ? totalNewsCount : _pageSize;
      
      displayedNewsCount.value = initialCount;
      hasMoreNews.value = totalNewsCount > _pageSize;
      
      // Sadece ilk haberleri göster (15 veya daha az)
      final initialNews = _allRssNews.take(initialCount).toList();
      final oldSection = _tempNewsSections.first;
      
      newsSections.value = [
        FeaturedSectionModel(
          id: oldSection.id,
          title: oldSection.title,
          type: oldSection.type,
          order: oldSection.order,
          isActive: oldSection.isActive,
          news: initialNews,
        )
      ];
      
      print("✅ News: ${oldSection.title} (ilk $initialCount / $totalNewsCount haber, hasMore: ${hasMoreNews.value})");
    } else {
      // Haber yok veya çok az
      hasMoreNews.value = false;
      _allRssNews = [];
    }

    print("🎯 Tamamlandı! Ekranda gösteriliyor.");
  }

  /// Daha fazla haber yükle (infinite scroll için)
  Future<void> loadMoreNews() async {
    // Güvenlik kontrolleri
    if (_isDisposed) return;
    if (isLoadingMore.value) return;
    if (!hasMoreNews.value) return;
    if (_allRssNews.isEmpty) return;
    
    // Zaten tüm haberler gösteriliyorsa çık
    if (displayedNewsCount.value >= _allRssNews.length) {
      hasMoreNews.value = false;
      return;
    }

    isLoadingMore.value = true;
    
    // Loading indicator'ın görünmesi için kısa gecikme
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_isDisposed) {
      isLoadingMore.value = false;
      return;
    }

    // Yeni haber sayısını hesapla
    final newCount = displayedNewsCount.value + _pageSize;
    final actualCount = newCount > _allRssNews.length ? _allRssNews.length : newCount;
    
    // Haberleri güncelle
    final updatedNews = _allRssNews.take(actualCount).toList();
    
    if (newsSections.isNotEmpty) {
      final oldSection = newsSections.first;
      newsSections[0] = FeaturedSectionModel(
        id: oldSection.id,
        title: oldSection.title,
        type: oldSection.type,
        order: oldSection.order,
        isActive: oldSection.isActive,
        news: updatedNews,
      );
    }

    displayedNewsCount.value = actualCount;
    hasMoreNews.value = actualCount < _allRssNews.length;
    isLoadingMore.value = false;

    print("📰 Daha fazla haber yüklendi: $actualCount / ${_allRssNews.length}");
  }

  /// Scroll listener - sayfa sonuna TAM gelince daha fazla yükle
  void _onScroll() {
    if (_isDisposed) return;
    if (isLoadingMore.value) return;
    if (!hasMoreNews.value) return;
    
    // Scroll pozisyonunu kontrol et
    if (!scrollController.hasClients) return;
    
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    
    // Tam sona gelince yükle (son 50 piksel - daha hassas)
    if (maxScroll > 0 && currentScroll >= maxScroll - 50) {
      print("📜 Sayfa sonuna gelindi, daha fazla yükleniyor...");
      loadMoreNews();
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    
    scrollController.removeListener(_onScroll);

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

  // Refresh - Cache'i temizle ve yeniden yükle
  Future<void> refreshNews() async {
    if (_isDisposed) return;
    print(
      "🔄 Haberler yenileniyor... Mevcut kaynaklar: ${_sourceController?.selectedSources}",
    );
    
    // Tek seferde yükle - önce her şeyi hazırla, sonra göster
    isLoading.value = true;
    isFeaturedLoading.value = true;
    
    try {
      // 1. API'den section yapısını çek (haberler olmadan)
      await _fetchSectionStructure();
      
      // 2. RSS'ten haberleri çek - forceRefresh ile cache'i atla
      await fetchRssNews(forceRefresh: true);
    } finally {
      isLoading.value = false;
      isFeaturedLoading.value = false;
    }
  }
}
