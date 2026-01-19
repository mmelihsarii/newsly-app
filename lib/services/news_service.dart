// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import '../models/news_model.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetStorage _storage = GetStorage();

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Normalize source name to match IDs (e.g., "Hürriyet" -> "hurriyet")
  String _normalizeSourceName(String name) {
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
      ' ': '_',
      '-': '_',
      '.': '',
      ',': '',
      '&': '',
      '(': '',
      ')': '',
      '[': '',
      ']': '',
      '/': '_',
      '\\': '_',
    };

    String normalized = name.toLowerCase().trim();
    turkishChars.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    // Remove multiple underscores
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');

    // Remove leading/trailing underscores
    normalized = normalized.replaceAll(RegExp(r'^_+|_+$'), '');

    // Keep only alphanumeric and underscore
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    return normalized;
  }

  /// Get user's selected sources from Firestore or local storage
  Future<Set<String>> _getSelectedSources() async {
    Set<String> selectedSet = {};

    // Try Firestore first for logged-in users
    if (_userId != null) {
      try {
        final doc = await _firestore.collection('users').doc(_userId).get();
        if (doc.exists) {
          final data = doc.data();
          final List<dynamic>? firestoreSources = data?['selectedSources'];
          if (firestoreSources != null && firestoreSources.isNotEmpty) {
            selectedSet = firestoreSources.cast<String>().toSet();
            print(
              '☁️ Firestore\'dan ${selectedSet.length} seçili kaynak okundu',
            );
            return selectedSet;
          }
        }
      } catch (e) {
        print('⚠️ Firestore okuma hatası, yerel depo kullanılıyor: $e');
      }
    }

    // Fallback to local storage
    final List<dynamic>? localSources = _storage.read<List<dynamic>>(
      'selected_sources',
    );
    if (localSources != null && localSources.isNotEmpty) {
      selectedSet = localSources.cast<String>().toSet();
      print('📱 Yerel depodan ${selectedSet.length} seçili kaynak okundu');
    }

    return selectedSet;
  }

  // 1. Firestore'dan Haber Kaynaklarını Çek (Kullanıcı seçimlerine göre)
  Future<List<Map<String, dynamic>>> fetchNewsSources() async {
    try {
      // Get user's selected sources
      final Set<String> selectedSet = await _getSelectedSources();

      print("🔥 Firestore'dan kaynaklar çekiliyor...");
      print("📌 Kullanıcı ${selectedSet.length} kaynak seçmiş");

      QuerySnapshot snapshot = await _firestore
          .collection('news_sources')
          .where('is_active', isEqualTo: true)
          .get();

      var sources = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      print("📰 Firestore'da ${sources.length} aktif kaynak var");

      if (sources.isEmpty) {
        print("❌ FIRESTORE'DA HİÇ KAYNAK YOK!");
        print(
          "⚠️ Realtime Database'deki kaynakları Firestore'a taşıman gerekiyor!",
        );
        return [];
      }

      // Filter by user's selected sources if they have made selections
      if (selectedSet.isNotEmpty) {
        final originalCount = sources.length;

        sources = sources.where((source) {
          // id alanı int veya String olabilir, her ikisini de destekle
          final dynamic rawId = source['id'];
          final String? sourceId = rawId?.toString();
          final String? sourceName = source['name'] as String?;

          if (sourceId == null && sourceName == null) {
            return false;
          }

          // Normalize both for comparison
          final normalizedSourceName = sourceName != null
              ? _normalizeSourceName(sourceName)
              : '';
          final normalizedSourceId = sourceId != null
              ? _normalizeSourceName(sourceId)
              : '';

          // Check if any selected source matches - STRICT matching
          for (final selected in selectedSet) {
            final normalizedSelected = _normalizeSourceName(selected);

            // Exact match checks
            if (sourceId == selected ||
                sourceName?.toLowerCase() == selected.toLowerCase() ||
                normalizedSourceName == normalizedSelected ||
                normalizedSourceId == normalizedSelected) {
              return true;
            }

            // Prefix match (e.g., "ntv" matches "ntv_spor" but not "mynet")
            if (normalizedSourceName.startsWith(normalizedSelected) ||
                normalizedSelected.startsWith(normalizedSourceName)) {
              // Only if the shorter one is at least 3 chars (avoid "a" matching "aspor")
              if (normalizedSelected.length >= 3 &&
                  normalizedSourceName.length >= 3) {
                return true;
              }
            }
          }

          return false;
        }).toList();

        print("✅ Filtrelenmiş: $originalCount → ${sources.length} kaynak");
      } else {
        print(
          "✅ Kullanıcı seçimi yok, tüm kaynaklar kullanılıyor: ${sources.length}",
        );
      }

      return sources;
    } catch (e) {
      print("❌ Kaynak çekme hatası: $e");
      return [];
    }
  }

  // 2. Tüm kaynaklardan haberleri çek ve birleştir
  Future<List<NewsModel>> fetchAllNews() async {
    List<NewsModel> allNews = [];
    List<Map<String, dynamic>> sources = await fetchNewsSources();

    if (sources.isEmpty) {
      print("⚠️ Hiç aktif kaynak bulunamadı.");
      return [];
    }

    print("🚀 ${sources.length} kaynaktan haberler çekiliyor...");

    // Her kaynaktan paralel olarak veri çek
    await Future.wait(
      sources.map((source) async {
        String url = source['url'] ?? source['rss_url'] ?? '';
        String sourceName = source['name'] ?? 'Bilinmeyen Kaynak';
        String categoryName = source['category'] ?? 'Gündem';

        if (url.isNotEmpty) {
          try {
            var fetchedNews = await _fetchRssFeed(
              url,
              sourceName,
              categoryName,
            );
            allNews.addAll(fetchedNews);
          } catch (e) {
            print("⚠️ $sourceName ($url) hatası: $e");
          }
        }
      }),
    );

    print("📰 Toplam ${allNews.length} haber çekildi");

    // KRONOLOJİK SIRALAMA - En yeni haberler en üstte
    allNews = _sortNewsByDate(allNews);
    print("📅 Haberler kronolojik olarak sıralandı");

    return allNews;
  }

  // Haberleri tarihe göre sırala (en yeni en üstte)
  List<NewsModel> _sortNewsByDate(List<NewsModel> news) {
    // Tarihi olan haberleri say
    int withDate = news.where((n) => n.publishedAt != null).length;
    int withoutDate = news.length - withDate;
    print("📊 Tarih bilgisi: $withDate haber tarihli, $withoutDate tarihsiz");

    news.sort((a, b) {
      final dateA = a.publishedAt;
      final dateB = b.publishedAt;
      
      // Her iki tarih de varsa karşılaştır
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA); // Descending (yeniden eskiye)
      }
      
      // Sadece biri varsa, tarihi olan üste gelsin
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      
      // İkisi de yoksa sıralama değişmesin
      return 0;
    });

    // İlk 5 haberin tarihini logla
    if (news.isNotEmpty) {
      print("📅 İlk 5 haber tarihi:");
      for (int i = 0; i < 5 && i < news.length; i++) {
        final n = news[i];
        final titlePreview = (n.title != null && n.title!.length > 30) 
            ? '${n.title!.substring(0, 30)}...' 
            : (n.title ?? '');
        print("   ${i + 1}. ${n.publishedAt?.toIso8601String() ?? 'TARİH YOK'} - $titlePreview");
      }
    }
    
    return news;
  }

  // Tekil RSS Çekme ve Parse Etme
  Future<List<NewsModel>> _fetchRssFeed(
    String url,
    String sourceName,
    String categoryName,
  ) async {
    List<NewsModel> newsList = [];
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        for (var item in items) {
          final title = item.findElements('title').singleOrNull?.innerText;
          final description = item
              .findElements('description')
              .singleOrNull
              ?.innerText;
          final link = item.findElements('link').singleOrNull?.innerText;
          final pubDateStr = item
              .findElements('pubDate')
              .singleOrNull
              ?.innerText;

          // Resim bulma
          String? imageUrl = _extractImage(item, description);

          // Tarih parse etme - RAW DateTime
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

          newsList.add(
            NewsModel(
              title: title,
              description: description,
              date: formattedDate,
              sourceUrl: link,
              sourceName: sourceName,
              image: imageUrl,
              categoryName: categoryName,
              publishedAt: publishedAt,
            ),
          );
        }
      }
    } catch (e) {
      print("RSS Parse Hatası ($url): $e");
    }
    return newsList;
  }

  // Güçlü RSS tarih parse fonksiyonu
  DateTime? _parseRssDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    // 1. ISO 8601 formatı: "2024-01-18T10:30:00Z" veya "2024-01-18T10:30:00+03:00"
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // 2. RFC 822 formatı: "Mon, 01 Jan 2024 10:00:00 GMT" veya "Mon, 01 Jan 2024 10:00:00 +0300"
    try {
      return HttpDate.parse(dateStr);
    } catch (_) {}

    // 3. Manuel RFC 822 parse (daha esnek)
    try {
      // "Sat, 18 Jan 2025 14:30:00 +0300" formatı
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
        
        final month = _monthStringToNumber(monthStr);
        
        return DateTime.utc(year, month, day, hour, minute, second);
      }
    } catch (_) {}

    // 4. Türkçe format: "18 Ocak 2025 14:30"
    try {
      final turkishRegex = RegExp(
        r'(\d{1,2})\s+(\w+)\s+(\d{4})\s+(\d{2}):(\d{2})',
      );
      final match = turkishRegex.firstMatch(dateStr);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        
        final month = _monthStringToNumber(monthStr);
        
        return DateTime(year, month, day, hour, minute);
      }
    } catch (_) {}

    return null;
  }

  // Ay string'ini sayıya çevir
  int _monthStringToNumber(String month) {
    final monthLower = month.toLowerCase();
    const months = {
      // İngilizce
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
      // Türkçe
      'oca': 1, 'ocak': 1,
      'şub': 2, 'şubat': 2,
      'mart': 3,
      'nis': 4, 'nisan': 4,
      'mayıs': 5,
      'haz': 6, 'haziran': 6,
      'tem': 7, 'temmuz': 7,
      'ağu': 8, 'ağustos': 8,
      'eyl': 9, 'eylül': 9,
      'eki': 10, 'ekim': 10,
      'kas': 11, 'kasım': 11,
      'ara': 12, 'aralık': 12,
    };
    return months[monthLower] ?? 1;
  }

  String? _extractImage(XmlElement item, String? description) {
    // 1. Enclosure
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final url = enclosure.getAttribute('url');
      if (url != null) return url;
    }

    // 2. Media:content
    final mediaContent = item.findElements('media:content').firstOrNull;
    if (mediaContent != null) {
      final url = mediaContent.getAttribute('url');
      if (url != null) return url;
    }

    // 3. Description içindeki <img>
    if (description != null) {
      RegExp exp = RegExp(r'<img[^>]+src="([^">]+)"');
      var matches = exp.allMatches(description);
      if (matches.isNotEmpty) {
        return matches.first.group(1);
      }
    }

    // 4. content:encoded içindeki <img>
    final contentEncoded = item
        .findElements('content:encoded')
        .firstOrNull
        ?.innerText;
    if (contentEncoded != null) {
      RegExp exp = RegExp(r'<img[^>]+src="([^">]+)"');
      var matches = exp.allMatches(contentEncoded);
      if (matches.isNotEmpty) {
        return matches.first.group(1);
      }
    }

    return null;
  }
}

// Dart'ın built-in HttpDate parser'ı için extension veya import gerekebilir mi?
// HttpDate 'dart:io' içindedir. Eğer web ise çalışmaz. intl ile deneyelim.
// HttpDate yerine intl kullanacağım.
// Ancak HttpDate parse işlemi çok standarttır.
// RSS date format (RFC 822) parsed by HttpDate usually works.
