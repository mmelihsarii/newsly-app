import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../models/source_model.dart';
import '../services/news_service.dart';
import '../services/source_service.dart';
import '../utils/news_sources_data.dart';

class NewsSearchController extends GetxController {
  final NewsService _newsService = NewsService();
  final SourceService _sourceService = SourceService();
  final TextEditingController searchTextController = TextEditingController();

  // Reaktif değişkenler
  var isSearching = false.obs;
  var searchResults = <NewsModel>[].obs;
  var suggestedResults = <NewsModel>[].obs;
  var allNews = <NewsModel>[].obs;
  var searchQuery = ''.obs;
  var hasExactMatch = false.obs;

  // ═══════════════════════════════════════════════════════════════════════════
  // GELİŞMİŞ FİLTRELER
  // ═══════════════════════════════════════════════════════════════════════════
  var isFilterActive = false.obs;
  
  // Tarih filtreleri
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  var selectedDateRange = ''.obs; // 'today', 'week', 'month', 'custom'
  
  // Kategori filtreleri
  var selectedCategories = <String>{}.obs;
  
  // Kaynak filtreleri
  var selectedSources = <String>{}.obs;
  
  // Sıralama
  var sortBy = 'date'.obs; // 'date', 'relevance'
  var sortOrder = 'desc'.obs; // 'asc', 'desc'

  // Dinamik kaynaklar (Firestore'dan)
  var dynamicSourceCategories = <SourceCategory>[].obs;
  var isSourcesLoading = false.obs;

  // Mevcut kategoriler (dinamik veya statik)
  List<dynamic> get availableCategories {
    if (dynamicSourceCategories.isNotEmpty) {
      return dynamicSourceCategories;
    }
    return kNewsSources;
  }
  
  // Tüm kaynaklar (dinamik - kategorize edilmiş)
  List<SourceModel> get allAvailableSources {
    final sources = <SourceModel>[];
    for (final cat in dynamicSourceCategories) {
      sources.addAll(cat.sources);
    }
    sources.sort((a, b) => a.name.compareTo(b.name));
    return sources;
  }

  // Eski format için uyumluluk
  List<String> get availableSources {
    if (dynamicSourceCategories.isNotEmpty) {
      return allAvailableSources.map((s) => s.name).toList();
    }
    // Fallback: haberlerden kaynak isimlerini çek
    final sources = <String>{};
    for (final news in allNews) {
      if (news.sourceName != null && news.sourceName!.isNotEmpty) {
        sources.add(news.sourceName!);
      }
    }
    return sources.toList()..sort();
  }

  @override
  void onInit() {
    super.onInit();
    _loadAllNews();
    _loadDynamicSources();
  }

  /// Firestore'dan dinamik kaynakları yükle
  Future<void> _loadDynamicSources() async {
    try {
      isSourcesLoading.value = true;
      final categories = await _sourceService.getSourcesByCategory();
      dynamicSourceCategories.value = categories;
      print('🔍 Arama filtreleri için ${categories.length} kategori, ${allAvailableSources.length} kaynak yüklendi');
    } catch (e) {
      print('❌ Dinamik kaynak yükleme hatası: $e');
    } finally {
      isSourcesLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }

  Future<void> _loadAllNews() async {
    try {
      final news = await _newsService.fetchAllNews();
      allNews.value = news;
    } catch (e) {
      print('Haberler yüklenirken hata: $e');
    }
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('İ', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('Ç', 'c');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FİLTRE FONKSİYONLARI
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Tarih aralığı seç
  void setDateRange(String range) {
    selectedDateRange.value = range;
    final now = DateTime.now();
    
    switch (range) {
      case 'today':
        startDate.value = DateTime(now.year, now.month, now.day);
        endDate.value = now;
        break;
      case 'week':
        startDate.value = now.subtract(const Duration(days: 7));
        endDate.value = now;
        break;
      case 'month':
        startDate.value = now.subtract(const Duration(days: 30));
        endDate.value = now;
        break;
      case 'custom':
        // Custom için UI'dan tarih seçilecek
        break;
      default:
        startDate.value = null;
        endDate.value = null;
    }
    
    _updateFilterStatus();
    _applyFilters();
  }

  /// Özel tarih aralığı seç
  void setCustomDateRange(DateTime start, DateTime end) {
    selectedDateRange.value = 'custom';
    startDate.value = start;
    endDate.value = end;
    _updateFilterStatus();
    _applyFilters();
  }

  /// Kategori toggle
  void toggleCategory(String categoryId) {
    if (selectedCategories.contains(categoryId)) {
      selectedCategories.remove(categoryId);
    } else {
      selectedCategories.add(categoryId);
    }
    _updateFilterStatus();
    _applyFilters();
  }

  /// Kaynak toggle
  void toggleSource(String sourceName) {
    if (selectedSources.contains(sourceName)) {
      selectedSources.remove(sourceName);
    } else {
      selectedSources.add(sourceName);
    }
    _updateFilterStatus();
    _applyFilters();
  }

  /// Sıralama değiştir
  void setSortBy(String sort) {
    sortBy.value = sort;
    _applyFilters();
  }

  /// Sıralama yönü değiştir
  void toggleSortOrder() {
    sortOrder.value = sortOrder.value == 'desc' ? 'asc' : 'desc';
    _applyFilters();
  }

  /// Tüm filtreleri temizle
  void clearFilters() {
    startDate.value = null;
    endDate.value = null;
    selectedDateRange.value = '';
    selectedCategories.clear();
    selectedSources.clear();
    sortBy.value = 'date';
    sortOrder.value = 'desc';
    isFilterActive.value = false;
    
    // Mevcut arama varsa tekrar uygula
    if (searchQuery.value.isNotEmpty) {
      search(searchQuery.value);
    } else {
      searchResults.clear();
    }
  }

  /// Filtre durumunu güncelle
  void _updateFilterStatus() {
    isFilterActive.value = startDate.value != null ||
        endDate.value != null ||
        selectedCategories.isNotEmpty ||
        selectedSources.isNotEmpty;
  }

  /// Aktif filtre sayısı
  int get activeFilterCount {
    int count = 0;
    if (startDate.value != null || endDate.value != null) count++;
    count += selectedCategories.length;
    count += selectedSources.length;
    return count;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANA ARAMA FONKSİYONU
  // ═══════════════════════════════════════════════════════════════════════════

  void search(String query) {
    searchQuery.value = query.trim();
    suggestedResults.clear();
    hasExactMatch.value = false;

    if (searchQuery.value.isEmpty && !isFilterActive.value) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;

    try {
      _applyFilters();
      
      // Filtre aktif ama arama yok ise, tüm filtrelenmiş sonuçları göster
      if (searchQuery.value.isEmpty && isFilterActive.value) {
        hasExactMatch.value = true; // Sonuçları göstermek için
      }
    } catch (e) {
      print('Arama hatası: $e');
    } finally {
      isSearching.value = false;
    }
  }
  
  /// Sadece filtreleri uygula (arama olmadan)
  void applyFiltersOnly() {
    searchQuery.value = '';
    suggestedResults.clear();
    hasExactMatch.value = true;
    isSearching.value = true;
    
    try {
      _applyFilters();
    } catch (e) {
      print('Filtre hatası: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// Filtreleri uygula
  void _applyFilters() {
    List<NewsModel> filteredNews = List.from(allNews);

    // 1. Tarih filtresi
    if (startDate.value != null) {
      filteredNews = filteredNews.where((news) {
        if (news.publishedAt == null) return false;
        return news.publishedAt!.isAfter(startDate.value!) ||
            news.publishedAt!.isAtSameMomentAs(startDate.value!);
      }).toList();
    }

    if (endDate.value != null) {
      filteredNews = filteredNews.where((news) {
        if (news.publishedAt == null) return true; // Tarihsiz haberleri dahil et
        return news.publishedAt!.isBefore(endDate.value!.add(const Duration(days: 1)));
      }).toList();
    }

    // 2. Kategori filtresi
    if (selectedCategories.isNotEmpty) {
      filteredNews = filteredNews.where((news) {
        final newsCategoryName = _normalizeText(news.categoryName ?? '');
        final newsSourceName = _normalizeText(news.sourceName ?? '');
        
        for (final catId in selectedCategories) {
          final normalizedCatId = _normalizeText(catId);
          
          // Kategori adı eşleşmesi
          if (newsCategoryName.contains(normalizedCatId) ||
              normalizedCatId.contains(newsCategoryName)) {
            return true;
          }
          
          // Kategori objesinden kaynak kontrolü
          final category = getCategoryById(catId);
          if (category != null) {
            final normalizedCatName = _normalizeText(category.name);
            if (newsCategoryName.contains(normalizedCatName) ||
                normalizedCatName.contains(newsCategoryName)) {
              return true;
            }
            
            // Kategorideki kaynakları kontrol et
            for (final source in category.sources) {
              final normalizedSourceName = _normalizeText(source.name);
              if (newsSourceName == normalizedSourceName ||
                  newsSourceName.contains(normalizedSourceName) ||
                  normalizedSourceName.contains(newsSourceName)) {
                return true;
              }
            }
          }
        }
        return false;
      }).toList();
    }

    // 3. Kaynak filtresi
    if (selectedSources.isNotEmpty) {
      filteredNews = filteredNews.where((news) {
        final newsSourceName = _normalizeText(news.sourceName ?? '');
        
        for (final selectedSource in selectedSources) {
          final normalizedSelected = _normalizeText(selectedSource);
          if (newsSourceName == normalizedSelected ||
              newsSourceName.contains(normalizedSelected) ||
              normalizedSelected.contains(newsSourceName)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    // 4. Metin araması (eğer query varsa)
    if (searchQuery.value.isNotEmpty) {
      final normalizedQuery = _normalizeText(searchQuery.value);
      final searchTerms = normalizedQuery
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toList();

      final scoredNews = filteredNews.map((news) {
        int score = 0;
        final title = _normalizeText(news.title ?? '');
        final description = _normalizeText(news.description ?? '');
        final sourceName = _normalizeText(news.sourceName ?? '');
        final categoryName = _normalizeText(news.categoryName ?? '');
        final fullText = '$title $description $sourceName $categoryName';

        for (final term in searchTerms) {
          if (term.isEmpty || term.length < 2) continue;

          if (title.contains(term)) {
            score += 15;
            if (title.startsWith(term)) score += 10;
            if (title.split(' ').contains(term)) score += 5;
          }

          if (description.contains(term)) score += 8;
          if (sourceName.contains(term)) score += 5;
          if (categoryName.contains(term)) score += 4;

          score += _calculateFuzzyScore(fullText, term);
        }

        return {'news': news, 'score': score};
      }).toList();

      // Skora göre sırala
      scoredNews.sort(
        (a, b) => ((b['score'] ?? 0) as int).compareTo((a['score'] ?? 0) as int),
      );

      final exactMatches = scoredNews
          .where((item) => (item['score'] as int) >= 10)
          .map((item) => item['news'] as NewsModel)
          .toList();

      final similarMatches = scoredNews
          .where((item) {
            final score = item['score'] as int;
            return score > 0 && score < 10;
          })
          .map((item) => item['news'] as NewsModel)
          .take(10)
          .toList();

      if (exactMatches.isNotEmpty) {
        hasExactMatch.value = true;
        filteredNews = exactMatches;
        suggestedResults.clear();
      } else if (similarMatches.isNotEmpty) {
        hasExactMatch.value = false;
        filteredNews = [];
        suggestedResults.value = similarMatches;
      } else {
        hasExactMatch.value = false;
        filteredNews = [];
        suggestedResults.value = allNews.take(5).toList();
      }
    } else if (isFilterActive.value) {
      // Arama yok ama filtre aktif - filtrelenmiş sonuçları göster
      hasExactMatch.value = true;
    }

    // 5. Sıralama
    if (sortBy.value == 'date') {
      filteredNews.sort((a, b) {
        final dateA = a.publishedAt;
        final dateB = b.publishedAt;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return sortOrder.value == 'desc'
            ? dateB.compareTo(dateA)
            : dateA.compareTo(dateB);
      });
    }
    // relevance sıralaması zaten skor bazlı yapıldı

    searchResults.value = filteredNews;
  }

  int _calculateFuzzyScore(String text, String term) {
    if (term.length < 2) return 0;
    int score = 0;

    final prefix = term.substring(0, term.length > 2 ? 2 : term.length);
    final words = text.split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.length < 2) continue;
      if (word.startsWith(prefix)) score += 2;
      if (word.contains(prefix) && !word.startsWith(prefix)) score += 1;
      if (_areSimilar(word, term)) score += 1;
    }

    return score;
  }

  bool _areSimilar(String word, String term) {
    if ((word.length - term.length).abs() > 2) return false;

    int commonChars = 0;
    for (int i = 0; i < term.length && i < word.length; i++) {
      if (word[i] == term[i]) commonChars++;
    }

    final similarity = commonChars / term.length;
    return similarity >= 0.6;
  }

  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
    searchResults.clear();
    suggestedResults.clear();
    hasExactMatch.value = false;
  }

  /// Kategori ID'sine göre kategori bul (dinamik veya statik)
  dynamic getCategoryById(String catId) {
    // Önce dinamik kategorilerde ara
    for (final cat in dynamicSourceCategories) {
      if (cat.id == catId || _normalizeText(cat.name) == _normalizeText(catId)) {
        return cat;
      }
    }
    // Statik kategorilerde ara
    for (final cat in kNewsSources) {
      if (cat.id == catId || _normalizeText(cat.name) == _normalizeText(catId)) {
        return cat;
      }
    }
    return null;
  }
}
