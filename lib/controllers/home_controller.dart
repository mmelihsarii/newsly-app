import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/news_model.dart';
import '../models/featured_section_model.dart';
import '../services/api_service.dart';
import '../services/news_service.dart';
import '../utils/api_constants.dart';
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
  var newsSections = <FeaturedSectionModel>[].obs; // type: breaking_news, horizontal_list vs.
  var isFeaturedLoading = false.obs;
  
  // RSS'ten gelen haberler (kullanıcı seçimine göre filtrelenmiş)
  var rssNews = <NewsModel>[].obs;
  
  // Pagination için
  static const int _pageSize = 15;
  var _allRssNews = <NewsModel>[];
  var displayedNewsCount = 15.obs;
  var isLoadingMore = false.obs;
  var hasMoreNews = true.obs;

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

  // Panel'den gelen section başlıkları (haberler RSS'ten gelecek)
  String _sliderTitle = 'Öne Çıkanlar';
  String _newsTitle = 'Haberler';
  int _sliderId = 1;
  int _newsId = 2;

  @override
  void onInit() {
    super.onInit();
    _apiService = ApiService();
    _newsService = Get.find<NewsService>();
    scrollController = ScrollController();
    
    scrollController.addListener(_onScroll);

    if (Get.isRegistered<SourceSelectionController>()) {
      _sourceController = Get.find<SourceSelectionController>();
    } else {
      _sourceController = Get.put(SourceSelectionController());
    }

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
    final stopwatch = Stopwatch()..start();
    
    isLoading.value = true;
    isFeaturedLoading.value = true;
    
    try {
      // Panel'den section başlıklarını çek (BEKLE)
      await _fetchSectionTitles();
      
      // RSS'ten haberleri çek
      await fetchRssNews();
      
      // Arka planda taze veri çek
      _refreshInBackground();
    } finally {
      isLoading.value = false;
      isFeaturedLoading.value = false;
      print("🚀 İlk yükleme: ${stopwatch.elapsedMilliseconds}ms");
    }
  }
  
  /// Arka planda taze veri çek
  Future<void> _refreshInBackground() async {
    if (_isDisposed) return;
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (_isDisposed) return;
    
    try {
      print("🔄 Arka planda taze haberler çekiliyor...");
      final freshNews = await _newsService.fetchAllNews(forceRefresh: true);
      
      if (!_isDisposed && freshNews.isNotEmpty) {
        _allRssNews = freshNews;
        _updateDisplayedNews();
        print("✅ Arka plan yenileme tamamlandı: ${freshNews.length} haber");
      }
    } catch (e) {
      print("⚠️ Arka plan yenileme hatası: $e");
    }
  }

  /// Panel'den section başlıklarını çek (sadece başlıklar - haberler RSS'ten)
  Future<void> _fetchSectionTitles() async {
    if (_isDisposed) return;

    try {
      print("🎯 Panel'den section başlıkları çekiliyor...");
      print("🌐 API URL: ${ApiConstants.baseUrl}${ApiConstants.getFeaturedSections}");

      final response = await _apiService.getData(
        ApiConstants.getFeaturedSections,
      );

      if (_isDisposed) return;

      print("📦 API Response: $response");
      print("📦 Response type: ${response.runtimeType}");

      if (response != null) {
        dynamic sectionsData;
        
        if (response is Map) {
          print("📦 Response keys: ${response.keys.toList()}");
          
          if (response['success'] == true && response['data'] != null) {
            sectionsData = response['data'];
          } else if (response['data'] != null) {
            sectionsData = response['data'];
          } else {
            // Direkt response'u kullan
            sectionsData = [response];
          }
        } else if (response is List) {
          sectionsData = response;
        }
        
        print("📦 sectionsData: $sectionsData");
        
        if (sectionsData is List && sectionsData.isNotEmpty) {
          print("📦 ${sectionsData.length} section bulundu");
          
          // Her section'ı logla
          for (int i = 0; i < sectionsData.length; i++) {
            final section = sectionsData[i];
            print("   Section $i: $section");
          }
          
          // İlk section'ı slider başlığı olarak kullan
          final first = sectionsData[0] as Map<String, dynamic>;
          _sliderTitle = first['title'] ?? first['name'] ?? first['section_title'] ?? 'Öne Çıkanlar';
          _sliderId = first['id'] ?? 1;
          print("✅ Slider başlığı: $_sliderTitle (id: $_sliderId)");
          
          // İkinci section'ı news başlığı olarak kullan
          if (sectionsData.length > 1) {
            final second = sectionsData[1] as Map<String, dynamic>;
            _newsTitle = second['title'] ?? second['name'] ?? second['section_title'] ?? 'Haberler';
            _newsId = second['id'] ?? 2;
            print("✅ News başlığı: $_newsTitle (id: $_newsId)");
          }
        } else {
          print("⚠️ sectionsData boş veya List değil");
        }
      } else {
        print("⚠️ API response null");
      }
    } catch (e, stack) {
      print("❌ Section başlıkları hatası: $e");
      print("❌ Stack: $stack");
    }
  }

  /// RSS kaynaklarından haberleri çek
  Future<void> fetchRssNews({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    
    try {
      print("📡 RSS haberler çekiliyor... (forceRefresh: $forceRefresh)");
      final news = await _newsService.fetchAllNews(forceRefresh: forceRefresh);
      
      if (!_isDisposed) {
        rssNews.value = news;
        print("✅ RSS'ten ${news.length} haber yüklendi");
        
        if (news.isNotEmpty) {
          _buildSectionsFromRss(news);
        }
      }
    } catch (e) {
      print("❌ RSS haber çekme hatası: $e");
    }
  }

  /// RSS haberlerinden slider ve news section'ları oluştur
  void _buildSectionsFromRss(List<NewsModel> news) {
    if (news.isEmpty) {
      print("⚠️ RSS'ten haber gelmedi");
      return;
    }

    print("🔄 RSS haberleri section'lara bölünüyor...");
    print("   Toplam haber: ${news.length}");

    // Eski controller'ları temizle
    _cleanupSliderControllers();

    // Slider için ilk 10 haber
    int sliderNewsCount = news.length > 10 ? 10 : (news.length > 3 ? news.length ~/ 3 : news.length);
    final sliderNews = news.take(sliderNewsCount).toList();
    
    // Slider section oluştur
    sliderSections.value = [
      FeaturedSectionModel(
        id: _sliderId,
        title: _sliderTitle,
        type: 'slider',
        order: 0,
        isActive: true,
        news: sliderNews,
      )
    ];
    
    // Slider controller oluştur
    featuredSliderControllers[_sliderId] = PageController();
    featuredSliderIndices[_sliderId] = 0;
    _startSliderAutoScroll(_sliderId);
    
    print("✅ Slider: $_sliderTitle (${sliderNews.length} haber)");

    // Kalan haberler için news section
    final remainingNews = news.skip(sliderNewsCount).toList();
    
    if (remainingNews.isNotEmpty) {
      _allRssNews = remainingNews;
      
      final totalNewsCount = _allRssNews.length;
      final initialCount = totalNewsCount < _pageSize ? totalNewsCount : _pageSize;
      
      displayedNewsCount.value = initialCount;
      hasMoreNews.value = totalNewsCount > _pageSize;
      
      final initialNews = _allRssNews.take(initialCount).toList();
      
      newsSections.value = [
        FeaturedSectionModel(
          id: _newsId,
          title: _newsTitle,
          type: 'news_list',
          order: 1,
          isActive: true,
          news: initialNews,
        )
      ];
      
      print("✅ News: $_newsTitle (ilk $initialCount / $totalNewsCount haber)");
    } else {
      hasMoreNews.value = false;
      _allRssNews = [];
    }

    print("🎯 Section'lar hazır!");
  }

  /// Daha fazla haber yükle (infinite scroll için)
  Future<void> loadMoreNews() async {
    if (_isDisposed) return;
    if (isLoadingMore.value) return;
    if (!hasMoreNews.value) return;
    if (_allRssNews.isEmpty) return;
    
    if (displayedNewsCount.value >= _allRssNews.length) {
      hasMoreNews.value = false;
      return;
    }

    isLoadingMore.value = true;

    final newCount = displayedNewsCount.value + _pageSize;
    final actualCount = newCount > _allRssNews.length ? _allRssNews.length : newCount;
    
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

    print("📰 +${_pageSize} haber: $actualCount / ${_allRssNews.length}");
  }
  
  /// Gösterilen haberleri güncelle
  void _updateDisplayedNews() {
    if (_allRssNews.isEmpty) return;
    
    // Slider'ı güncelle
    int sliderNewsCount = _allRssNews.length > 10 ? 10 : (_allRssNews.length > 3 ? _allRssNews.length ~/ 3 : _allRssNews.length);
    
    if (sliderSections.isNotEmpty) {
      final sliderNews = _allRssNews.take(sliderNewsCount).toList();
      sliderSections[0] = FeaturedSectionModel(
        id: _sliderId,
        title: _sliderTitle,
        type: 'slider',
        order: 0,
        isActive: true,
        news: sliderNews,
      );
    }
    
    // News section'ı güncelle
    final remainingNews = _allRssNews.skip(sliderNewsCount).toList();
    if (remainingNews.isNotEmpty && newsSections.isNotEmpty) {
      final totalNewsCount = remainingNews.length;
      final currentCount = displayedNewsCount.value;
      final actualCount = currentCount > totalNewsCount ? totalNewsCount : currentCount;
      
      final updatedNews = remainingNews.take(actualCount).toList();
      
      newsSections[0] = FeaturedSectionModel(
        id: _newsId,
        title: _newsTitle,
        type: 'news_list',
        order: 1,
        isActive: true,
        news: updatedNews,
      );
      
      hasMoreNews.value = actualCount < totalNewsCount;
    }
  }

  /// Scroll listener
  void _onScroll() {
    if (_isDisposed) return;
    if (isLoadingMore.value) return;
    if (!hasMoreNews.value) return;
    
    if (!scrollController.hasClients) return;
    
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    
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

  // Refresh
  Future<void> refreshNews() async {
    if (_isDisposed) return;
    
    final stopwatch = Stopwatch()..start();
    print("🔄 Haberler yenileniyor...");
    
    isLoading.value = true;
    isFeaturedLoading.value = true;
    
    try {
      await _fetchSectionTitles();
      await fetchRssNews(forceRefresh: true);
    } finally {
      isLoading.value = false;
      isFeaturedLoading.value = false;
      print("✅ Yenileme tamamlandı: ${stopwatch.elapsedMilliseconds}ms");
    }
  }
}
