import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/news_model.dart';
import '../models/featured_section_model.dart';
import '../services/news_service.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';

class HomeController extends GetxController {
  // News Servisi
  final NewsService _newsService = NewsService();
  final ApiService _apiService = ApiService();

  // Reaktif değişkenler
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var isCarouselLoading = false.obs;
  var newsList = <NewsModel>[].obs;
  var carouselNewsList = <NewsModel>[].obs;

  // Featured Sections (Admin Panel'den gelen)
  var featuredSections = <FeaturedSectionModel>[].obs;
  var isFeaturedLoading = false.obs;

  // Carousel değişkenleri
  final PageController carouselController = PageController();
  var currentCarouselIndex = 0.obs;
  Timer? _carouselTimer;

  // Featured slider için ayrı controller'lar
  final Map<int, PageController> featuredSliderControllers = {};
  final Map<int, int> featuredSliderIndices = {};
  final Map<int, Timer?> featuredSliderTimers = {};

  // Arama state
  var isSearchOpen = false.obs;

  // Scroll Controller
  final ScrollController scrollController = ScrollController();

  @override
  void onClose() {
    _carouselTimer?.cancel();
    scrollController.dispose();
    carouselController.dispose();
    // Featured slider controller'larını temizle
    for (var controller in featuredSliderControllers.values) {
      controller.dispose();
    }
    for (var timer in featuredSliderTimers.values) {
      timer?.cancel();
    }
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    fetchFeaturedSections();
    fetchNews();
  }

  // Admin Panel'den Featured Sections çekme
  Future<void> fetchFeaturedSections() async {
    try {
      isFeaturedLoading(true);
      print("🎯 Featured Sections çekiliyor...");

      final response = await _apiService.getData(ApiConstants.getFeaturedSections);

      if (response != null) {
        List<FeaturedSectionModel> sections = [];

        // API yanıt formatına göre parse et
        if (response is List) {
          sections = response
              .map((item) => FeaturedSectionModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response is Map && response['data'] != null) {
          sections = (response['data'] as List)
              .map((item) => FeaturedSectionModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response is Map && response['sections'] != null) {
          sections = (response['sections'] as List)
              .map((item) => FeaturedSectionModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        // Sadece aktif olanları al ve sırala
        sections = sections
            .where((s) => s.isActive == true && s.news.isNotEmpty)
            .toList();
        sections.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

        featuredSections.value = sections;
        print("✅ ${sections.length} featured section yüklendi");

        // Slider'lar için controller'ları oluştur
        for (var section in sections) {
          if (section.type == 'slider' && section.id != null) {
            featuredSliderControllers[section.id!] = PageController();
            featuredSliderIndices[section.id!] = 0;
            _startFeaturedSliderAutoScroll(section.id!);
          }
        }
      }
    } catch (e) {
      print("❌ Featured Sections Hatası: $e");
    } finally {
      isFeaturedLoading(false);
    }
  }

  // Featured slider için otomatik kaydırma
  void _startFeaturedSliderAutoScroll(int sectionId) {
    featuredSliderTimers[sectionId]?.cancel();
    
    final section = featuredSections.firstWhereOrNull((s) => s.id == sectionId);
    if (section == null || section.news.isEmpty) return;

    featuredSliderTimers[sectionId] = Timer.periodic(
      const Duration(milliseconds: 3000),
      (timer) {
        final controller = featuredSliderControllers[sectionId];
        if (controller == null || !controller.hasClients) return;

        final currentIndex = featuredSliderIndices[sectionId] ?? 0;
        final nextIndex = (currentIndex + 1) % section.news.length;
        
        controller.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        featuredSliderIndices[sectionId] = nextIndex;
      },
    );
  }

  void updateFeaturedSliderIndex(int sectionId, int index) {
    featuredSliderIndices[sectionId] = index;
  }

  // Kullanıcının seçtiği kaynaklardan haber çekme
  Future<void> fetchNews() async {
    try {
      isLoading(true);
      isCarouselLoading(true);

      print("🚀 TÜM KAYNAKLARDAN haberler çekiliyor...");

      // NewsService'den haberleri çek
      var allNews = await _newsService.fetchAllNews();

      if (allNews.isNotEmpty) {
        // KRONOLOJİK SIRALAMA - KAYNAK FARKETMEZ, EN YENİ EN ÜSTTE
        allNews = _sortNewsByDateStrict(allNews);
        
        // Carousel için ilk 5 haber (en yeni haberler)
        carouselNewsList.value = allNews.take(5).toList();
        // Haber listesi
        newsList.value = allNews;

        print('✅ ${allNews.length} haber KRONOLOJİK sırayla yüklendi');
        
        // Carousel otomatik kaydırmayı başlat
        startAutoScroll();
      } else {
        print("⚠️ Hiç haber bulunamadı.");
        carouselNewsList.clear();
        newsList.clear();
      }
    } catch (e) {
      print("❌ Haber Çekme Hatası: $e");
    } finally {
      isLoading(false);
      isCarouselLoading(false);
    }
  }

  // Haberleri tarihe göre KESİN sırala (en yeni en üstte, kaynak farketmez)
  List<NewsModel> _sortNewsByDateStrict(List<NewsModel> news) {
    // Tarihi olanları ve olmayanları ayır
    final withDate = news.where((n) => n.publishedAt != null).toList();
    final withoutDate = news.where((n) => n.publishedAt == null).toList();
    
    print("📊 ${withDate.length} haber tarihli, ${withoutDate.length} tarihsiz");

    // Tarihli haberleri sırala (en yeni en üstte)
    withDate.sort((a, b) => b.publishedAt!.compareTo(a.publishedAt!));

    // Tarihsiz haberleri en sona ekle
    final sorted = [...withDate, ...withoutDate];

    // Debug: İlk 10 haberin tarihini göster
    print("📅 İlk 10 haber (kronolojik):");
    for (int i = 0; i < 10 && i < sorted.length; i++) {
      final n = sorted[i];
      final title = (n.title ?? '').length > 40 
          ? '${n.title!.substring(0, 40)}...' 
          : n.title ?? '';
      final date = n.publishedAt?.toString() ?? 'TARİH YOK';
      final source = n.sourceName ?? '';
      print("   ${i + 1}. [$source] $date - $title");
    }
    
    return sorted;
  }

  // Carousel otomatik kaydırma
  void startAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (carouselNewsList.isEmpty) {
        timer.cancel();
        return;
      }

      final nextIndex = (currentCarouselIndex.value + 1) % carouselNewsList.length;
      
      if (carouselController.hasClients) {
        carouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Manuel kaydırma yapıldığında timer'ı sıfırla
  void resetAutoScroll() {
    startAutoScroll();
  }

  // Refresh - Yenile
  Future<void> refreshNews() async {
    await fetchFeaturedSections();
    await fetchNews();
  }
}
