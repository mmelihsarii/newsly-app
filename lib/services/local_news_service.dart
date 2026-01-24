// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import '../models/news_model.dart';

/// Yerel haber kaynağı modeli
class LocalSource {
  final String id;
  final String name;
  final String rssUrl;
  final bool isActive;
  final String category;

  LocalSource({
    required this.id,
    required this.name,
    required this.rssUrl,
    this.isActive = true,
    this.category = 'Yerel Haberler',
  });

  factory LocalSource.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LocalSource(
      id: doc.id,
      name: data['name'] ?? '',
      rssUrl: data['rss_url'] ?? data['url'] ?? '',
      isActive: data['is_active'] ?? true,
      category: data['category'] ?? 'Yerel Haberler',
    );
  }
}

/// Yerel Haber Servisi - news_sources koleksiyonundan "Yerel Haberler" kategorisini çeker
class LocalNewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache
  List<LocalSource>? _cachedSources;
  DateTime? _cacheTime;
  static const int _cacheDurationMinutes = 30;

  // Yerel haber kategorileri (Firestore'daki category alanı ile TAM eşleşmeli)
  static const List<String> localCategories = [
    'Yerel Haberler',
    'Yerel',
    'yerel haberler',
    'yerel',
    'Local',
    'local',
    'Yerel_Haberler',
    'yerel_haberler',
  ];

  /// news_sources koleksiyonundan yerel haber kaynaklarını çek
  Future<List<LocalSource>> fetchLocalSources({bool forceRefresh = false}) async {
    // Cache kontrolü
    if (!forceRefresh && _cachedSources != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!).inMinutes;
      if (age < _cacheDurationMinutes) {
        print('📦 Cache\'den ${_cachedSources!.length} yerel kaynak yüklendi');
        return _cachedSources!;
      }
    }

    try {
      print('🔍 Firestore news_sources\'dan yerel kaynaklar sorgulanıyor...');
      
      // news_sources koleksiyonundan aktif olanları çek
      QuerySnapshot snapshot = await _firestore
          .collection('news_sources')
          .where('is_active', isEqualTo: true)
          .get();

      List<LocalSource> sources = [];

      if (snapshot.docs.isNotEmpty) {
        print('📊 Toplam ${snapshot.docs.length} aktif kaynak bulundu');
        
        // Debug: Tüm kategorileri listele
        final allCategories = <String>{};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final cat = data['category']?.toString() ?? '';
          if (cat.isNotEmpty) allCategories.add(cat);
        }
        print('📁 Mevcut kategoriler: $allCategories');
        
        // Kategorisi SADECE "Yerel Haberler" veya "Yerel" olanları filtrele
        sources = snapshot.docs
            .map((doc) => LocalSource.fromFirestore(doc))
            .where((s) => _isLocalCategory(s.category) && s.rssUrl.isNotEmpty)
            .toList();
        
        print('☁️ news_sources\'dan ${sources.length} yerel kaynak bulundu');
        
        // Debug: Bulunan kaynakları listele
        for (var s in sources) {
          print('   📍 ${s.name} (${s.category}) - ${s.rssUrl}');
        }
      } else {
        print('⚠️ Firestore\'da hiç aktif kaynak yok!');
      }

      if (sources.isEmpty) {
        print('⚠️ Yerel haber kategorisinde kaynak bulunamadı');
        print('💡 news_sources koleksiyonuna category: "Yerel Haberler" olan kaynaklar ekleyin');
      }

      // Alfabetik sırala
      sources.sort((a, b) => a.name.compareTo(b.name));

      // Cache'e kaydet
      _cachedSources = sources;
      _cacheTime = DateTime.now();

      return sources;
    } catch (e) {
      print('❌ Yerel kaynak çekme hatası: $e');
      return _cachedSources ?? [];
    }
  }

  /// Kategori yerel mi kontrol et - SADECE TAM EŞLEŞMELİ
  bool _isLocalCategory(String category) {
    if (category.isEmpty) return false;
    
    final normalizedCategory = _normalizeText(category);
    
    // SADECE tam eşleşme kontrolü - "Yerel Haberler" veya "Yerel"
    // "Bilim Teknoloji", "Spor" vs. dahil DEĞİL
    for (final localCat in localCategories) {
      if (normalizedCategory == _normalizeText(localCat)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Türkçe karakterleri normalize et
  String _normalizeText(String text) {
    const Map<String, String> turkishChars = {
      'ı': 'i', 'İ': 'i', 'ğ': 'g', 'Ğ': 'g',
      'ü': 'u', 'Ü': 'u', 'ş': 's', 'Ş': 's',
      'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
    };

    String normalized = text.toLowerCase().trim();
    turkishChars.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
    // Alt çizgi ve boşlukları kaldır
    normalized = normalized.replaceAll('_', '').replaceAll(' ', '');
    return normalized;
  }

  /// Belirli bir kaynağın haberlerini çek
  Future<List<NewsModel>> fetchNewsForSource(String sourceName, String rssUrl) async {
    if (rssUrl.isEmpty) {
      print('⚠️ RSS URL boş: $sourceName');
      return [];
    }

    try {
      print('📡 $sourceName haberleri çekiliyor...');
      
      final response = await http.get(Uri.parse(rssUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final news = _parseRssFeed(response.body, sourceName);
        print('✅ $sourceName: ${news.length} haber');
        return news;
      }
    } catch (e) {
      print('❌ $sourceName haber çekme hatası: $e');
    }

    return [];
  }

  /// RSS XML'i parse et
  List<NewsModel> _parseRssFeed(String xmlData, String sourceName) {
    final List<NewsModel> news = [];

    try {
      final document = XmlDocument.parse(xmlData);
      final items = document.findAllElements('item').take(20);

      for (var item in items) {
        final title = item.findElements('title').singleOrNull?.innerText;
        final description = item.findElements('description').singleOrNull?.innerText;
        final link = item.findElements('link').singleOrNull?.innerText;
        final pubDateStr = item.findElements('pubDate').singleOrNull?.innerText;

        String? imageUrl = _extractImage(item, description);

        DateTime? publishedAt;
        String formattedDate = '';
        
        if (pubDateStr != null && pubDateStr.isNotEmpty) {
          publishedAt = _parseRssDate(pubDateStr);
          if (publishedAt != null) {
            formattedDate = DateFormat('dd MMM HH:mm').format(publishedAt);
          } else {
            formattedDate = pubDateStr;
          }
        }

        if (title != null && title.isNotEmpty) {
          news.add(
            NewsModel(
              id: (news.length + 1).toString(),
              title: _cleanHtml(title),
              description: description != null ? _cleanHtml(description) : null,
              image: imageUrl,
              date: formattedDate,
              categoryName: 'Yerel Haberler',
              sourceName: sourceName,
              sourceUrl: link,
              publishedAt: publishedAt,
            ),
          );
        }
      }
    } catch (e) {
      print('RSS parse hatası: $e');
    }

    return news;
  }

  String? _extractImage(XmlElement item, String? description) {
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final url = enclosure.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    final mediaContent = item.findElements('media:content').firstOrNull;
    if (mediaContent != null) {
      final url = mediaContent.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
    if (mediaThumbnail != null) {
      final url = mediaThumbnail.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    if (description != null) {
      // Resim URL'sini description içinden çıkar
      final imgRegex = RegExp(r'<img[^>]+src="([^"]+)"');
      final imgMatch = imgRegex.firstMatch(description);
      if (imgMatch != null) {
        return imgMatch.group(1);
      }
      // Tek tırnak ile de dene
      final imgRegex2 = RegExp(r"<img[^>]+src='([^']+)'");
      final imgMatch2 = imgRegex2.firstMatch(description);
      if (imgMatch2 != null) {
        return imgMatch2.group(1);
      }
    }

    return null;
  }

  DateTime? _parseRssDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    try { return DateTime.parse(dateStr); } catch (_) {}

    try {
      final rfc822Regex = RegExp(
        r'(\w+),?\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+(\d{2}):(\d{2}):?(\d{2})?\s*([\+\-]?\d{4}|GMT|UTC)?',
        caseSensitive: false,
      );
      final match = rfc822Regex.firstMatch(dateStr);
      if (match != null) {
        final day = int.parse(match.group(2)!);
        final monthStr = match.group(3)!;
        final year = int.parse(match.group(4)!);
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final second = match.group(7) != null ? int.parse(match.group(7)!) : 0;
        final month = _monthToNumber(monthStr);
        return DateTime.utc(year, month, day, hour, minute, second);
      }
    } catch (_) {}

    return null;
  }

  int _monthToNumber(String month) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
