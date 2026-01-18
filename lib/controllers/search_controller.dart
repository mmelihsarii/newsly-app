import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';

class NewsSearchController extends GetxController {
  final NewsService _newsService = NewsService();
  final TextEditingController searchTextController = TextEditingController();

  // Reaktif değişkenler
  var isSearching = false.obs;
  var searchResults = <NewsModel>[].obs;
  var suggestedResults = <NewsModel>[].obs; // Önerilen sonuçlar
  var allNews = <NewsModel>[].obs;
  var searchQuery = ''.obs;
  var hasExactMatch = false.obs; // Tam eşleşme var mı

  @override
  void onInit() {
    super.onInit();
    _loadAllNews();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }

  // Tüm haberleri yükle (arama için)
  Future<void> _loadAllNews() async {
    try {
      final news = await _newsService.fetchAllNews();
      allNews.value = news;
    } catch (e) {
      print('Haberler yüklenirken hata: $e');
    }
  }

  // Türkçe karakterleri normalize et
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

  // Arama yap (SEO optimized, fuzzy search)
  void search(String query) {
    searchQuery.value = query.trim();
    suggestedResults.clear();
    hasExactMatch.value = false;

    if (searchQuery.value.isEmpty) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;

    try {
      // Arama kelimelerini ayır ve normalize et
      final normalizedQuery = _normalizeText(searchQuery.value);
      final searchTerms = normalizedQuery
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toList();

      // Haberleri skorla ve filtrele
      final scoredNews = allNews.map((news) {
        int score = 0;
        final title = _normalizeText(news.title ?? '');
        final description = _normalizeText(news.description ?? '');
        final sourceName = _normalizeText(news.sourceName ?? '');
        final categoryName = _normalizeText(news.categoryName ?? '');
        final fullText = '$title $description $sourceName $categoryName';

        for (final term in searchTerms) {
          if (term.isEmpty || term.length < 2) continue;

          // Başlıkta tam eşleşme (en yüksek skor)
          if (title.contains(term)) {
            score += 15;
            // Başlangıçta varsa bonus
            if (title.startsWith(term)) score += 10;
            // Kelime olarak tam eşleşme
            if (title.split(' ').contains(term)) score += 5;
          }

          // Açıklamada eşleşme
          if (description.contains(term)) {
            score += 8;
          }

          // Kaynak adında eşleşme
          if (sourceName.contains(term)) {
            score += 5;
          }

          // Kategori adında eşleşme
          if (categoryName.contains(term)) {
            score += 4;
          }

          // Fuzzy matching - benzer kelimeler
          final fuzzyScore = _calculateFuzzyScore(fullText, term);
          score += fuzzyScore;
        }

        return {'news': news, 'score': score};
      }).toList();

      // Sonuçları skora göre sırala
      scoredNews.sort(
        (a, b) =>
            ((b['score'] ?? 0) as int).compareTo((a['score'] ?? 0) as int),
      );

      // Yüksek skorlu sonuçlar (tam eşleşme)
      final exactMatches = scoredNews
          .where((item) => (item['score'] as int) >= 10)
          .map((item) => item['news'] as NewsModel)
          .toList();

      // Düşük skorlu sonuçlar (benzer/önerilen)
      final similarMatches = scoredNews
          .where((item) {
            final score = item['score'] as int;
            return score > 0 && score < 10;
          })
          .map((item) => item['news'] as NewsModel)
          .take(10) // En fazla 10 öneri
          .toList();

      if (exactMatches.isNotEmpty) {
        hasExactMatch.value = true;
        searchResults.value = exactMatches;
        suggestedResults.clear();
      } else if (similarMatches.isNotEmpty) {
        // Tam eşleşme yok, benzer sonuçları göster
        hasExactMatch.value = false;
        searchResults.clear();
        suggestedResults.value = similarMatches;
      } else {
        // Hiç sonuç yok - popüler/son haberlerden öner
        hasExactMatch.value = false;
        searchResults.clear();
        suggestedResults.value = allNews.take(5).toList();
      }
    } catch (e) {
      print('Arama hatası: $e');
    } finally {
      isSearching.value = false;
    }
  }

  // Gelişmiş fuzzy skor hesapla
  int _calculateFuzzyScore(String text, String term) {
    if (term.length < 2) return 0;
    int score = 0;

    // Kelimenin ilk 2-3 karakteri eşleşiyorsa
    final prefix = term.substring(0, term.length > 2 ? 2 : term.length);
    final words = text.split(RegExp(r'\s+'));

    for (final word in words) {
      if (word.length < 2) continue;

      // Kelime başlangıcı eşleşiyor
      if (word.startsWith(prefix)) {
        score += 2;
      }

      // Kelime içinde eşleşme
      if (word.contains(prefix) && !word.startsWith(prefix)) {
        score += 1;
      }

      // Levenshtein-benzeri benzerlik (basit)
      if (_areSimilar(word, term)) {
        score += 1;
      }
    }

    return score;
  }

  // İki kelimenin benzer olup olmadığını kontrol et
  bool _areSimilar(String word, String term) {
    if ((word.length - term.length).abs() > 2) return false;

    // Ortak karakter sayısı
    int commonChars = 0;
    for (int i = 0; i < term.length && i < word.length; i++) {
      if (word[i] == term[i]) commonChars++;
    }

    // %60'tan fazla eşleşme varsa benzer say
    final similarity = commonChars / term.length;
    return similarity >= 0.6;
  }

  // Aramayı temizle
  void clearSearch() {
    searchTextController.clear();
    searchQuery.value = '';
    searchResults.clear();
    suggestedResults.clear();
    hasExactMatch.value = false;
  }
}
