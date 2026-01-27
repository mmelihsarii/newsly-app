// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Yerel Haber Servisi
class LocalNewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache
  List<LocalSource>? _cachedSources;
  DateTime? _cacheTime;
  static const int _cacheDurationMinutes = 30;

  /// Firestore'dan "Yerel Haberler" kategorisindeki kaynakları çek
  Future<List<LocalSource>> fetchLocalSources({bool forceRefresh = false}) async {
    // Cache kontrolü
    if (!forceRefresh && _cachedSources != null && _cacheTime != null) {
      final age = DateTime.now().difference(_cacheTime!).inMinutes;
      if (age < _cacheDurationMinutes) {
        return _cachedSources!;
      }
    }

    try {
      print('🔍 Firestore\'dan yerel kaynaklar çekiliyor...');
      
      // news_sources koleksiyonundan aktif olanları çek
      QuerySnapshot snapshot = await _firestore
          .collection('news_sources')
          .where('is_active', isEqualTo: true)
          .get();

      List<LocalSource> sources = [];

      if (snapshot.docs.isNotEmpty) {
        print('📊 Toplam ${snapshot.docs.length} aktif kaynak bulundu');
        
        // Tüm kaynakları kontrol et
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final category = data['category']?.toString() ?? '';
          final name = data['name']?.toString() ?? '';
          final rssUrl = data['rss_url']?.toString() ?? data['url']?.toString() ?? '';
          
          // Kategori kontrolü - "Yerel Haberler" veya "Yerel" içeren
          if (_isLocalCategory(category) && rssUrl.isNotEmpty) {
            sources.add(LocalSource(
              id: doc.id,
              name: name,
              rssUrl: rssUrl,
              isActive: true,
              category: category,
            ));
          }
        }
        
        print('✅ ${sources.length} yerel kaynak filtrelendi');
        
        // Debug: İlk 10 kaynağı listele
        for (var i = 0; i < sources.length && i < 10; i++) {
          print('   📍 ${sources[i].name}');
        }
        if (sources.length > 10) {
          print('   ... ve ${sources.length - 10} kaynak daha');
        }
      } else {
        print('⚠️ Firestore\'da hiç aktif kaynak yok');
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

  /// Kategori yerel mi kontrol et
  bool _isLocalCategory(String category) {
    if (category.isEmpty) return false;
    
    final normalized = _normalizeText(category);
    
    // "Yerel Haberler", "Yerel", "yerel_haberler" vb. eşleşmeler
    return normalized.contains('yerel') || 
           normalized == 'local' ||
           normalized.contains('local') ||
           normalized == 'yerelhaberler' ||
           normalized == 'yerel_haberler';
  }

  /// Belirli bir kaynağın haberlerini çek
  Future<List<NewsModel>> fetchNewsForSource(String sourceName, String rssUrl) async {
    if (rssUrl.isEmpty) return [];

    try {
      print('📡 $sourceName haberleri çekiliyor...');
      
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final request = await client.getUrl(Uri.parse(rssUrl));
      request.headers.set('User-Agent', 'Mozilla/5.0');
      request.headers.set('Accept', 'application/rss+xml, application/xml, text/xml, */*');
      
      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          <int>[],
          (List<int> previous, List<int> element) => previous..addAll(element),
        );
        
        // UTF-8 decode with fallback
        String body;
        try {
          body = utf8.decode(bytes, allowMalformed: true);
        } catch (_) {
          body = String.fromCharCodes(bytes);
        }
        
        // Türkçe karakter düzeltmesi
        body = _fixTurkishEncoding(body);
        
        final news = _parseRssFeed(body, sourceName);
        print('✅ $sourceName: ${news.length} haber');
        client.close();
        return news;
      }
      
      client.close();
    } catch (e) {
      print('❌ $sourceName haber çekme hatası: $e');
    }

    return [];
  }
  
  /// Türkçe karakter encoding sorunlarını düzelt
  String _fixTurkishEncoding(String text) {
    // UTF-8 double encoding düzeltmeleri
    final fixes = {
      'Ä±': 'ı', 'Ä°': 'İ', 'ÄŸ': 'ğ', 'Ä': 'Ğ',
      'Ã¼': 'ü', 'Ãœ': 'Ü', 'ÅŸ': 'ş', 'Å': 'Ş',
      'Ã¶': 'ö', 'Ã–': 'Ö', 'Ã§': 'ç', 'Ã‡': 'Ç',
      'â€™': "'", 'â€œ': '"', 'â€': '"',
      'â€"': '–', 'â€"': '—', 'â€¦': '...',
    };
    
    String result = text;
    fixes.forEach((wrong, correct) {
      result = result.replaceAll(wrong, correct);
    });
    
    return result;
  }

  /// RSS XML'i parse et
  List<NewsModel> _parseRssFeed(String xmlData, String sourceName) {
    final List<NewsModel> news = [];

    try {
      final document = XmlDocument.parse(xmlData);
      
      // RSS ve Atom formatlarını destekle
      var items = document.findAllElements('item');
      if (items.isEmpty) {
        items = document.findAllElements('entry');
      }

      for (var item in items.take(20)) {
        final title = item.findElements('title').singleOrNull?.innerText;
        final description = item.findElements('description').singleOrNull?.innerText ??
                           item.findElements('summary').singleOrNull?.innerText;
        
        String? link = item.findElements('link').singleOrNull?.innerText;
        if (link == null || link.isEmpty) {
          link = item.findElements('link').firstOrNull?.getAttribute('href');
        }
        
        final pubDateStr = item.findElements('pubDate').singleOrNull?.innerText ??
                          item.findElements('published').singleOrNull?.innerText;

        String? imageUrl = _extractImage(item, description);

        DateTime? publishedAt;
        String formattedDate = '';
        
        if (pubDateStr != null && pubDateStr.isNotEmpty) {
          publishedAt = _parseRssDate(pubDateStr);
          if (publishedAt != null) {
            // Türkçe locale ile formatla
            try {
              formattedDate = DateFormat('dd MMM HH:mm', 'tr_TR').format(publishedAt);
            } catch (_) {
              formattedDate = '${publishedAt.day}/${publishedAt.month} ${publishedAt.hour}:${publishedAt.minute.toString().padLeft(2, '0')}';
            }
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
    // enclosure
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final url = enclosure.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    // media:content
    final mediaContent = item.findElements('media:content').firstOrNull;
    if (mediaContent != null) {
      final url = mediaContent.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    // media:thumbnail
    final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
    if (mediaThumbnail != null) {
      final url = mediaThumbnail.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    // Description içinden img src
    if (description != null) {
      final imgRegex = RegExp(r'<img[^>]+src=["' "'" r']([^"' "'" r']+)["' "'" r']');
      final match = imgRegex.firstMatch(description);
      if (match != null) return match.group(1);
    }

    return null;
  }

  DateTime? _parseRssDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    try { return DateTime.parse(dateStr); } catch (_) {}

    try {
      // Türkçe karakterler için genişletilmiş regex
      final rfc822Regex = RegExp(
        r'([a-zA-ZğüşöçıİĞÜŞÖÇ]+),?\s+(\d{1,2})\s+([a-zA-ZğüşöçıİĞÜŞÖÇ]+)\s+(\d{4})\s+(\d{2}):(\d{2}):?(\d{2})?\s*([\+\-]?\d{4}|GMT|UTC)?',
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
      // İngilizce
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      // Türkçe
      'oca': 1, 'ocak': 1, 'şub': 2, 'şubat': 2, 'mart': 3,
      'nis': 4, 'nisan': 4, 'mayıs': 5, 'haz': 6, 'haziran': 6,
      'tem': 7, 'temmuz': 7, 'ağu': 8, 'ağustos': 8,
      'eyl': 9, 'eylül': 9, 'eki': 10, 'ekim': 10,
      'kas': 11, 'kasım': 11, 'ara': 12, 'aralık': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<!\[CDATA\['), '')
        .replaceAll(RegExp(r'\]\]>'), '')
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
    normalized = normalized.replaceAll('_', '').replaceAll(' ', '');
    return normalized;
  }
}
