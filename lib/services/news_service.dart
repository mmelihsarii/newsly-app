// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import '../models/news_model.dart';
import 'cache_service.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetStorage _storage = GetStorage();
  final CacheService _cacheService = CacheService();

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

  // Seçili kaynaklar cache'i
  Set<String>? _cachedSelectedSources;
  DateTime? _selectedSourcesCacheTime;
  static const int _selectedSourcesCacheDuration = 60; // 60 saniye

  /// Seçili kaynaklar cache'ini temizle (giriş/çıkış sonrası çağrılmalı)
  void clearSelectedSourcesCache() {
    _cachedSelectedSources = null;
    _selectedSourcesCacheTime = null;
    print('🗑️ Seçili kaynaklar cache\'i temizlendi');
  }

  // Misafir kullanıcılar için varsayılan kaynaklar
  static const List<String> _defaultGuestSources = [
    'Sözcü',
    'Halk TV',
    'Halk Tv',
    'HalkTV',
    'halktv',
    'CNN Türk',
    'Cnn Türk',
    'A Haber',
    'NTV',
    'Ntv',
    'Fotomaç',
    'Ajans Spor',
    'Ekonomi Gazetesi',
  ];

  /// Get user's selected sources from Firestore or local storage (CACHED)
  Future<Set<String>> _getSelectedSources() async {
    // Cache kontrolü - 60 saniye içinde tekrar Firestore'a gitme
    if (_cachedSelectedSources != null && _selectedSourcesCacheTime != null) {
      final age = DateTime.now().difference(_selectedSourcesCacheTime!).inSeconds;
      if (age < _selectedSourcesCacheDuration) {
        return _cachedSelectedSources!;
      }
    }

    Set<String> selectedSet = {};

    // Giriş yapmış kullanıcı için önce Firestore'dan oku
    if (_userId != null) {
      try {
        final doc = await _firestore.collection('users').doc(_userId).get();
        if (doc.exists) {
          final data = doc.data();
          final List<dynamic>? firestoreSources = data?['selectedSources'];
          if (firestoreSources != null && firestoreSources.isNotEmpty) {
            selectedSet = firestoreSources.cast<String>().toSet();
            // Local storage'a da kaydet (senkronizasyon)
            _storage.write('selected_sources', selectedSet.toList());
            _cachedSelectedSources = selectedSet;
            _selectedSourcesCacheTime = DateTime.now();
            print('☁️ Firestore\'dan ${selectedSet.length} kaynak yüklendi');
            return selectedSet;
          }
        }
      } catch (e) {
        print('⚠️ Firestore okuma hatası: $e');
      }
    }

    // Firestore'da yoksa veya hata olduysa local storage'dan oku
    final List<dynamic>? localSources = _storage.read<List<dynamic>>('selected_sources');
    if (localSources != null && localSources.isNotEmpty) {
      selectedSet = localSources.cast<String>().toSet();
      _cachedSelectedSources = selectedSet;
      _selectedSourcesCacheTime = DateTime.now();
      print('📱 Local storage\'dan ${selectedSet.length} kaynak yüklendi');
      return selectedSet;
    }

    // Hiç kaynak seçilmemişse (misafir kullanıcı) varsayılan kaynakları kullan
    if (selectedSet.isEmpty) {
      selectedSet = _defaultGuestSources.toSet();
      print('👤 Misafir kullanıcı - varsayılan ${selectedSet.length} kaynak kullanılıyor');
    }

    _cachedSelectedSources = selectedSet;
    _selectedSourcesCacheTime = DateTime.now();
    return selectedSet;
  }

  // 1. Firestore'dan Haber Kaynaklarını Çek (Kullanıcı seçimlerine göre)
  Future<List<Map<String, dynamic>>> fetchNewsSources({bool fetchAll = false}) async {
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

      // fetchAll true ise filtreleme yapma - TÜM kaynakları döndür
      if (fetchAll) {
        print("🌐 TÜM KAYNAKLAR döndürülüyor: ${sources.length} kaynak");
        return sources;
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

          // Check if any selected source matches - SADECE TAM EŞLEŞME
          for (final selected in selectedSet) {
            final normalizedSelected = _normalizeSourceName(selected);

            // Exact match checks ONLY - partial match YOK
            if (sourceId == selected ||
                sourceName?.toLowerCase() == selected.toLowerCase() ||
                normalizedSourceName == normalizedSelected ||
                normalizedSourceId == normalizedSelected) {
              return true;
            }
          }

          return false;
        }).toList();

        print("✅ Filtrelenmiş: $originalCount → ${sources.length} kaynak");
      } else {
        // Kullanıcı seçimi yoksa - misafir için varsayılan kaynaklar
        // Giriş yapmış kullanıcı için boş liste (kaynak seçmesi gerekiyor)
        if (_userId != null) {
          print("⚠️ Giriş yapmış kullanıcı kaynak seçmemiş - boş liste döndürülüyor");
          return [];
        } else {
          // Misafir kullanıcı - varsayılan kaynaklar - SADECE TAM EŞLEŞME
          final defaultSources = [
            'sozcu', 'sözcü',
            'halk_tv', 'halktv', 'halk tv', 'halk-tv',
            'cnn_turk', 'cnnturk', 'cnn türk', 'cnn-turk',
            'a_haber', 'ahaber', 'a haber', 'a-haber',
            'ntv',
            'fotomac', 'fotomaç',
            'ajansspor', 'ajans spor', 'ajans_spor',
            'ekonomi_gazetesi', 'ekonomigazetesi', 'ekonomi gazetesi',
          ];
          sources = sources.where((source) {
            final String? sourceName = source['name'] as String?;
            if (sourceName == null) return false;
            final normalized = _normalizeSourceName(sourceName);
            final nameLower = sourceName.toLowerCase();
            // SADECE TAM EŞLEŞME
            return defaultSources.any((d) => 
              normalized == d || 
              nameLower == d
            );
          }).toList();
          print("✅ Misafir kullanıcı - varsayılan ${sources.length} kaynak");
        }
      }

      return sources;
    } catch (e) {
      print("❌ Kaynak çekme hatası: $e");
      return [];
    }
  }

  // 2. Tüm kaynaklardan haberleri çek ve birleştir
  Future<List<NewsModel>> fetchAllNews({bool forceRefresh = false, bool fetchAllSources = false}) async {
    final stopwatch = Stopwatch()..start();
    
    // Cache kontrolü - force refresh değilse ve cache geçerliyse cache'den oku
    // fetchAllSources true ise cache kullanma (bildirim için tüm haberler lazım)
    if (!forceRefresh && !fetchAllSources && _cacheService.isNewsCacheValid()) {
      final cachedNews = _cacheService.getCachedNews();
      if (cachedNews != null && cachedNews.isNotEmpty) {
        print("⚡ Cache'den ${cachedNews.length} haber yüklendi (${stopwatch.elapsedMilliseconds}ms)");
        return cachedNews;
      }
    }

    List<NewsModel> allNews = [];
    List<Map<String, dynamic>> sources = await fetchNewsSources(fetchAll: fetchAllSources);

    if (sources.isEmpty) {
      print("⚠️ Hiç aktif kaynak bulunamadı.");
      final cachedNews = _cacheService.getCachedNews();
      if (cachedNews != null && cachedNews.isNotEmpty) {
        print("📦 Kaynak yok, eski cache kullanılıyor");
        return cachedNews;
      }
      return [];
    }

    print("🚀 ${sources.length} kaynaktan haberler çekiliyor...");

    // PARALEL ve TIMEOUT'lu istek - max 5 saniye bekle
    final results = await Future.wait(
      sources.map((source) async {
        String url = source['url'] ?? source['rss_url'] ?? '';
        String sourceName = source['name'] ?? 'Bilinmeyen Kaynak';
        String categoryName = source['category'] ?? 'Gündem';

        if (url.isEmpty) return <NewsModel>[];

        try {
          return await _fetchRssFeed(url, sourceName, categoryName)
              .timeout(const Duration(seconds: 5), onTimeout: () {
            print("⏱️ Timeout: $sourceName");
            return <NewsModel>[];
          });
        } catch (e) {
          return <NewsModel>[];
        }
      }),
      eagerError: false, // Bir hata olsa bile diğerlerini bekle
    );

    // Sonuçları birleştir
    for (final news in results) {
      allNews.addAll(news);
    }

    print("📰 ${allNews.length} haber çekildi (${stopwatch.elapsedMilliseconds}ms)");

    // KRONOLOJİK SIRALAMA
    allNews = _sortNewsByDate(allNews);

    // Cache'e kaydet
    if (allNews.isNotEmpty) {
      _cacheService.cacheNews(allNews); // await kaldırıldı - arka planda kaydet
    }

    stopwatch.stop();
    print("✅ Toplam süre: ${stopwatch.elapsedMilliseconds}ms");

    return allNews;
  }

  /// Cache'i temizle ve yeniden yükle
  Future<List<NewsModel>> refreshNews() async {
    await _cacheService.clearNewsCache();
    return fetchAllNews(forceRefresh: true);
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

  // Tekil RSS Çekme ve Parse Etme - HIZLI + UTF-8 DÜZELTME
  Future<List<NewsModel>> _fetchRssFeed(
    String url,
    String sourceName,
    String categoryName,
  ) async {
    List<NewsModel> newsList = [];
    try {
      // HttpClient kullan - bazı sunucular bozuk Content-Type header'ı gönderiyor
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      client.autoUncompress = true; // Gzip desteği
      
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true; // Redirect'leri takip et
      request.maxRedirects = 5;
      request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36');
      request.headers.set('Accept', 'application/rss+xml, application/xml, text/xml, */*');
      
      final response = await request.close().timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        // Response body'yi oku
        final bytes = await response.fold<List<int>>(
          <int>[],
          (List<int> previous, List<int> element) => previous..addAll(element),
        );
        
        // UTF-8 encoding düzeltmesi
        String body = _fixEncoding('', bytes);
        
        final document = XmlDocument.parse(body);
        
        // Hem <item> (RSS) hem <entry> (Atom) formatını destekle
        // findAllElements namespace'siz arar, bu yüzden manuel arama da yapalım
        Iterable<XmlElement> items = document.findAllElements('item');
        
        if (items.isEmpty) {
          // Atom format - entry tag'ını ara
          items = document.findAllElements('entry');
        }
        
        if (items.isEmpty) {
          // Namespace'li Atom feed'leri için - root altındaki entry'leri bul
          final root = document.rootElement;
          // feed > entry veya channel > item yapısını kontrol et
          if (root.name.local == 'feed' || root.name.local == 'rss') {
            final channel = root.findElements('channel').firstOrNull ?? root;
            items = channel.childElements.where((e) => 
              e.name.local == 'entry' || e.name.local == 'item'
            );
          }
        }
        
        print('📰 $sourceName: ${items.length} haber bulundu');

        for (var item in items) {
          // Title - innerText yerine text kullan ve HTML temizle
          String? title = item.findElements('title').singleOrNull?.innerText;
          
          // Eğer title CDATA içindeyse veya HTML içeriyorsa temizle
          if (title != null) {
            // CDATA wrapper'ı kaldır
            title = title.replaceAll(RegExp(r'<!\[CDATA\['), '');
            title = title.replaceAll(RegExp(r'\]\]>'), '');
            // HTML tag'larını kaldır
            title = title.replaceAll(RegExp(r'<[^>]*>'), '');
            title = title.trim();
          }
          
          // Description - RSS: description, Atom: summary veya content
          String? description = item.findElements('description').singleOrNull?.innerText;
          if (description == null || description.isEmpty) {
            description = item.findElements('summary').singleOrNull?.innerText;
          }
          if (description == null || description.isEmpty) {
            description = item.findElements('content').singleOrNull?.innerText;
          }
          
          // Link - RSS: link içeriği, Atom: link href attribute
          String? link = item.findElements('link').singleOrNull?.innerText;
          if (link == null || link.isEmpty) {
            final linkElement = item.findElements('link').firstOrNull;
            link = linkElement?.getAttribute('href');
          }
          
          // PubDate - RSS: pubDate, Atom: published veya updated
          String? pubDateStr = item.findElements('pubDate').singleOrNull?.innerText;
          if (pubDateStr == null || pubDateStr.isEmpty) {
            pubDateStr = item.findElements('published').singleOrNull?.innerText;
          }
          if (pubDateStr == null || pubDateStr.isEmpty) {
            pubDateStr = item.findElements('updated').singleOrNull?.innerText;
          }

          // Metin düzeltme - encoding sorunlarını çöz
          title = _fixTurkishText(title);
          description = _fixTurkishText(description);

          // Resim bulma - GELİŞTİRİLMİŞ
          String? imageUrl = _extractImageAdvanced(item, description, link);
          
          // RSS'te görsel yoksa Firebase Storage'dan kaynak görseli kullan
          if (imageUrl == null || imageUrl.isEmpty) {
            imageUrl = _getSourceFallbackImageUrl(sourceName);
          }

          // Tarih parse etme - RAW DateTime
          DateTime? publishedAt;
          String formattedDate = '';
          
          if (pubDateStr != null && pubDateStr.isNotEmpty) {
            publishedAt = _parseRssDate(pubDateStr);
            if (publishedAt != null) {
              // Türkçe locale ile formatla - "27 Oca 14:30" formatında
              try {
                formattedDate = DateFormat('dd MMM HH:mm', 'tr_TR').format(publishedAt);
              } catch (e) {
                // Locale hatası - basit format kullan
                formattedDate = '${publishedAt.day}/${publishedAt.month} ${publishedAt.hour}:${publishedAt.minute.toString().padLeft(2, '0')}';
              }
            } else {
              // Parse edilemezse ham string'i kullan
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
      } else {
        print('❌ HTTP ${response.statusCode}: $sourceName');
      }
      
      client.close();
    } catch (e) {
      print('❌ RSS hatası ($sourceName): $e');
    }
    return newsList;
  }

  /// Response encoding'ini düzelt - AGRESIF UTF-8 DÜZELTME
  String _fixEncoding(String body, List<int> bodyBytes) {
    // 1. Önce bodyBytes'ı direkt UTF-8 olarak decode et
    try {
      final utf8Body = utf8.decode(bodyBytes, allowMalformed: false);
      // Başarılı ve temiz UTF-8 - direkt kullan
      return utf8Body;
    } catch (_) {
      // UTF-8 decode başarısız - devam et
    }
    
    // 2. allowMalformed ile UTF-8 dene
    String utf8Body;
    try {
      utf8Body = utf8.decode(bodyBytes, allowMalformed: true);
    } catch (_) {
      utf8Body = body;
    }
    
    // 3. Eğer body'de bozuk UTF-8 pattern'leri varsa düzelt
    // Bu pattern'ler UTF-8'in Latin-1 olarak yanlış decode edildiğini gösterir
    if (_hasCorruptedUtf8Patterns(utf8Body)) {
      // Latin-1 olarak decode edip UTF-8 byte sequence'larını düzelt
      try {
        final latin1Body = latin1.decode(bodyBytes);
        final fixed = _fixLatin1ToUtf8(latin1Body);
        if (!_hasCorruptedUtf8Patterns(fixed)) {
          return fixed;
        }
      } catch (_) {}
    }
    
    // 4. Windows-1254 dene
    if (_hasCorruptedUtf8Patterns(utf8Body)) {
      try {
        final win1254Body = _decodeWindows1254(bodyBytes);
        if (!_hasCorruptedUtf8Patterns(win1254Body)) {
          return win1254Body;
        }
      } catch (_) {}
    }
    
    return utf8Body;
  }
  
  /// Bozuk UTF-8 pattern'leri var mı kontrol et
  bool _hasCorruptedUtf8Patterns(String text) {
    // Yaygın bozuk pattern'ler
    const corruptedPatterns = [
      'Ã¶', 'Ã¼', 'Ã§', 'ÄŸ', 'Ä±', 'ÅŸ', // Türkçe
      'Ã–', 'Ãœ', 'Ã‡', 'Ä', 'Ä°', 'Å', // Türkçe büyük
      'Ã¢', 'Ã®', 'Ã»', // Diğer
      '\u0080', '\u0081', '\u008A', '\u009F', // Kontrol karakterleri
    ];
    
    for (final pattern in corruptedPatterns) {
      if (text.contains(pattern)) {
        return true;
      }
    }
    
    // Replacement character kontrolü
    if (text.contains('�') || text.contains('\uFFFD')) {
      return true;
    }
    
    return false;
  }
  
  /// Latin-1 olarak yanlış decode edilmiş UTF-8 metni düzelt
  String _fixLatin1ToUtf8(String text) {
    // UTF-8 byte sequence'ları Latin-1 olarak okunmuş
    // Örnek: "ş" (UTF-8: C5 9F) -> "Å\u009F" (Latin-1)
    final buffer = StringBuffer();
    int i = 0;
    
    while (i < text.length) {
      final c1 = text.codeUnitAt(i);
      
      // 2-byte UTF-8 sequence (C0-DF başlangıç)
      if (c1 >= 0xC0 && c1 <= 0xDF && i + 1 < text.length) {
        final c2 = text.codeUnitAt(i + 1);
        if (c2 >= 0x80 && c2 <= 0xBF) {
          // Valid 2-byte UTF-8 sequence
          final codePoint = ((c1 & 0x1F) << 6) | (c2 & 0x3F);
          buffer.writeCharCode(codePoint);
          i += 2;
          continue;
        }
      }
      
      // 3-byte UTF-8 sequence (E0-EF başlangıç)
      if (c1 >= 0xE0 && c1 <= 0xEF && i + 2 < text.length) {
        final c2 = text.codeUnitAt(i + 1);
        final c3 = text.codeUnitAt(i + 2);
        if (c2 >= 0x80 && c2 <= 0xBF && c3 >= 0x80 && c3 <= 0xBF) {
          // Valid 3-byte UTF-8 sequence
          final codePoint = ((c1 & 0x0F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F);
          buffer.writeCharCode(codePoint);
          i += 3;
          continue;
        }
      }
      
      // Normal karakter
      buffer.writeCharCode(c1);
      i++;
    }
    
    return buffer.toString();
  }

  /// Windows-1254 (Türkçe) encoding decode
  String _decodeWindows1254(List<int> bytes) {
    // Windows-1254 Türkçe karakter tablosu
    const windows1254Map = {
      0x80: '\u20AC', // €
      0x82: '\u201A', // ‚
      0x83: '\u0192', // ƒ
      0x84: '\u201E', // „
      0x85: '\u2026', // …
      0x86: '\u2020', // †
      0x87: '\u2021', // ‡
      0x88: '\u02C6', // ˆ
      0x89: '\u2030', // ‰
      0x8A: '\u0160', // Š
      0x8B: '\u2039', // ‹
      0x8C: '\u0152', // Œ
      0x91: '\u2018', // '
      0x92: '\u2019', // '
      0x93: '\u201C', // "
      0x94: '\u201D', // "
      0x95: '\u2022', // •
      0x96: '\u2013', // –
      0x97: '\u2014', // —
      0x98: '\u02DC', // ˜
      0x99: '\u2122', // ™
      0x9A: '\u0161', // š
      0x9B: '\u203A', // ›
      0x9C: '\u0153', // œ
      0x9F: '\u0178', // Ÿ
      0xD0: '\u011E', // Ğ
      0xDD: '\u0130', // İ
      0xDE: '\u015E', // Ş
      0xF0: '\u011F', // ğ
      0xFD: '\u0131', // ı
      0xFE: '\u015F', // ş
    };
    
    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte < 0x80) {
        buffer.writeCharCode(byte);
      } else if (windows1254Map.containsKey(byte)) {
        buffer.write(windows1254Map[byte]);
      } else if (byte >= 0xA0 && byte <= 0xFF) {
        // Latin-1 supplement
        buffer.writeCharCode(byte);
      } else {
        buffer.writeCharCode(byte);
      }
    }
    return buffer.toString();
  }

  /// String içindeki UTF-8 byte sequence'larını düzelt
  /// Latin-1 olarak yanlış decode edilmiş UTF-8 karakterleri tespit edip düzeltir
  String _tryFixUtf8InLatin1(String text) {
    String result = text;
    
    // === ADIM 1: Bilinen bozuk pattern'leri düzelt ===
    final utf8Patterns = <String, String>{
      // Türkçe karakterler - TÜM OLASI KOMBİNASYONLAR
      // ı (U+0131) - UTF-8: C4 B1
      '\u00C4\u00B1': 'ı',
      'Ä±': 'ı',
      'Ä\u00B1': 'ı',
      
      // İ (U+0130) - UTF-8: C4 B0
      '\u00C4\u00B0': 'İ',
      'Ä°': 'İ',
      'Ä\u00B0': 'İ',
      
      // ğ (U+011F) - UTF-8: C4 9F
      '\u00C4\u009F': 'ğ',
      'ÄŸ': 'ğ',
      'Ä\u009F': 'ğ',
      
      // Ğ (U+011E) - UTF-8: C4 9E
      '\u00C4\u009E': 'Ğ',
      'Ä': 'Ğ',
      'Ä\u009E': 'Ğ',
      
      // ş (U+015F) - UTF-8: C5 9F
      '\u00C5\u009F': 'ş',
      'ÅŸ': 'ş',
      'Å\u009F': 'ş',
      
      // Ş (U+015E) - UTF-8: C5 9E
      '\u00C5\u009E': 'Ş',
      'Å': 'Ş',
      'Å\u009E': 'Ş',
      
      // ö (U+00F6) - UTF-8: C3 B6
      '\u00C3\u00B6': 'ö',
      'Ã¶': 'ö',
      'Ã\u00B6': 'ö',
      
      // Ö (U+00D6) - UTF-8: C3 96
      '\u00C3\u0096': 'Ö',
      'Ã–': 'Ö',
      'Ã\u0096': 'Ö',
      
      // ü (U+00FC) - UTF-8: C3 BC
      '\u00C3\u00BC': 'ü',
      'Ã¼': 'ü',
      'Ã\u00BC': 'ü',
      
      // Ü (U+00DC) - UTF-8: C3 9C
      '\u00C3\u009C': 'Ü',
      'Ãœ': 'Ü',
      'Ã\u009C': 'Ü',
      
      // ç (U+00E7) - UTF-8: C3 A7
      '\u00C3\u00A7': 'ç',
      'Ã§': 'ç',
      'Ã\u00A7': 'ç',
      
      // Ç (U+00C7) - UTF-8: C3 87
      '\u00C3\u0087': 'Ç',
      'Ã‡': 'Ç',
      'Ã\u0087': 'Ç',
      
      // â (U+00E2) - UTF-8: C3 A2
      '\u00C3\u00A2': 'â',
      'Ã¢': 'â',
      
      // î (U+00EE) - UTF-8: C3 AE
      '\u00C3\u00AE': 'î',
      'Ã®': 'î',
      
      // û (U+00FB) - UTF-8: C3 BB
      '\u00C3\u00BB': 'û',
      'Ã»': 'û',
    };
    
    // Tüm pattern'leri uygula
    utf8Patterns.forEach((wrong, correct) {
      result = result.replaceAll(wrong, correct);
    });
    
    // === ADIM 2: Regex ile kalan UTF-8 sequence'ları düzelt ===
    // Ã, Ä, Å ile başlayan 2-byte sequence'lar
    result = result.replaceAllMapped(
      RegExp(r'[\u00C0-\u00DF]([\u0080-\u00BF])'),
      (match) {
        final c1 = match.group(0)!.codeUnitAt(0);
        final c2 = match.group(1)!.codeUnitAt(0);
        final codePoint = ((c1 & 0x1F) << 6) | (c2 & 0x3F);
        return String.fromCharCode(codePoint);
      },
    );
    
    // === ADIM 3: Tek başına kalan kontrol karakterlerini temizle ===
    // 0x80-0x9F aralığındaki kontrol karakterleri (Türkçe karakterlerden sonra kalabilir)
    result = result.replaceAll(RegExp(r'[\u0080-\u009F]'), '');
    
    return result;
  }

  /// Türkçe metin düzeltme - TÜM encoding sorunlarını çöz
  String? _fixTurkishText(String? text) {
    if (text == null || text.isEmpty) return text;
    
    String fixed = text;
    
    // === -1. HTML TAG'LARINI TEMİZLE ===
    // Anchor tag'ları ve diğer HTML'i kaldır
    fixed = fixed.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // === 0. ÖNCE UTF-8 BYTE SEQUENCE DÜZELTMESİ ===
    // Latin-1 olarak yanlış decode edilmiş UTF-8 karakterleri
    fixed = _tryFixUtf8InLatin1(fixed);
    
    // === 1. UTF-8 DOUBLE ENCODING DÜZELTMELERİ ===
    // UTF-8 olarak encode edilmiş metin tekrar Latin-1 olarak okunmuş
    final utf8DoubleEncoded = {
      // Türkçe karakterler - UTF-8 double encoded - TÜM VARYASYONLAR
      'Ä±': 'ı',      // ı (dotless i)
      'Ä°': 'İ',      // İ (dotted I)
      'ÄŸ': 'ğ',      // ğ
      'Ä': 'Ğ',      // Ğ
      'Ã¼': 'ü',      // ü
      'Ãœ': 'Ü',      // Ü
      'ÅŸ': 'ş',      // ş
      'Å': 'Ş',      // Ş
      'Ã¶': 'ö',      // ö
      'Ã–': 'Ö',      // Ö
      'Ã§': 'ç',      // ç
      'Ã‡': 'Ç',      // Ç
      
      // Alternatif bozuk pattern'ler
      'Ã¶': 'ö',
      'Ã¼': 'ü',
      'Ã§': 'ç',
      'Ã¢': 'â',
      'Ã®': 'î',
      'Ã»': 'û',
      
      // Diğer yaygın karakterler
      'Ã¨': 'è',      // è
      'Ã©': 'é',      // é
      'Ã ': 'à',      // à
      'Ã¡': 'á',      // á
      'Ã¤': 'ä',      // ä
      'Ã«': 'ë',      // ë
      'Ã¯': 'ï',      // ï
      'Ã²': 'ò',      // ò
      'Ã³': 'ó',      // ó
      'Ãº': 'ú',      // ú
      'Ã¹': 'ù',      // ù
      'Ã½': 'ý',      // ý
      'Ã¿': 'ÿ',      // ÿ
      'Ã±': 'ñ',      // ñ
      
      // Özel karakterler
      'â€™': "'",     // '
      'â€œ': '"',     // "
      'â€': '"',     // "
      'â€"': '–',     // –
      'â€"': '—',     // —
      'â€¦': '...',   // …
      'â€¢': '•',     // •
      'Â°': '°',      // °
      'Â»': '»',      // »
      'Â«': '«',      // «
      'Â½': '½',      // ½
      'Â¼': '¼',      // ¼
      'Â¾': '¾',      // ¾
      'Â©': '©',      // ©
      'Â®': '®',      // ®
      'â„¢': '™',     // ™
      'Â´': "'",      // ´
      'Â': '',        // Boş karakter temizle
    };
    
    // === 2. WINDOWS-1254 YANLIŞ DECODE DÜZELTMELERİ ===
    final windows1254Fixes = {
      'Ý': 'İ',       // İ
      'ý': 'ı',       // ı
      'Þ': 'Ş',       // Ş
      'þ': 'ş',       // ş
      'Ð': 'Ğ',       // Ğ
      'ð': 'ğ',       // ğ
    };
    
    // === 3. HTML ENTITY DÜZELTMELERİ ===
    final htmlEntities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&#39;': "'",
      '&nbsp;': ' ',
      '&ndash;': '–',
      '&mdash;': '—',
      '&lsquo;': ''',
      '&rsquo;': ''',
      '&ldquo;': '"',
      '&rdquo;': '"',
      '&hellip;': '...',
      '&bull;': '•',
      '&copy;': '©',
      '&reg;': '®',
      '&trade;': '™',
      '&deg;': '°',
      '&plusmn;': '±',
      '&frac12;': '½',
      '&frac14;': '¼',
      '&frac34;': '¾',
      '&times;': '×',
      '&divide;': '÷',
      '&euro;': '€',
      '&pound;': '£',
      '&yen;': '¥',
      '&cent;': '¢',
      // Türkçe HTML entities
      '&#305;': 'ı',
      '&#304;': 'İ',
      '&#287;': 'ğ',
      '&#286;': 'Ğ',
      '&#252;': 'ü',
      '&#220;': 'Ü',
      '&#351;': 'ş',
      '&#350;': 'Ş',
      '&#246;': 'ö',
      '&#214;': 'Ö',
      '&#231;': 'ç',
      '&#199;': 'Ç',
    };
    
    // === 4. BOZUK KARAKTER DİZİLERİ - KAPSAMLI ===
    final brokenSequences = {
      // 2-byte UTF-8 sequences yanlış decode edilmiş
      '\u00C3\u00B6': 'ö',  // ö
      '\u00C3\u00BC': 'ü',  // ü
      '\u00C3\u00A7': 'ç',  // ç
      '\u00C3\u0096': 'Ö',  // Ö
      '\u00C3\u009C': 'Ü',  // Ü
      '\u00C3\u0087': 'Ç',  // Ç
      '\u00C4\u00B1': 'ı',  // ı
      '\u00C4\u009F': 'ğ',  // ğ
      '\u00C5\u009F': 'ş',  // ş
      '\u00C4\u00B0': 'İ',  // İ
      '\u00C4\u009E': 'Ğ',  // Ğ
      '\u00C5\u009E': 'Ş',  // Ş
      '\u00C3\u00A2': 'â',  // â
      '\u00C3\u00AE': 'î',  // î
      '\u00C3\u00BB': 'û',  // û
      
      // Visible bozuk karakterler
      'Ã¶': 'ö',
      'Ã¼': 'ü', 
      'Ã§': 'ç',
      'Ä\u009F': 'ğ',
      'Ä\u00B1': 'ı',
      'Å\u009F': 'ş',
      'Ä\u00B0': 'İ',
      'Ã\u0096': 'Ö',
      'Ã\u009C': 'Ü',
      'Ã\u0087': 'Ç',
      'Ä\u009E': 'Ğ',
      'Å\u009E': 'Ş',
      
      // Ã ile başlayan bozuk diziler
      'Ã¶': 'ö',
      'Ã¼': 'ü',
      'Ã§': 'ç',
      'Ã–': 'Ö',
      'Ãœ': 'Ü',
      'Ã‡': 'Ç',
      'Ã¢': 'â',
      'Ã®': 'î',
      'Ã»': 'û',
      
      // Ä ile başlayan bozuk diziler
      'Ä±': 'ı',
      'ÄŸ': 'ğ',
      'Ä°': 'İ',
      'Ä': 'Ğ',
      
      // Å ile başlayan bozuk diziler
      'ÅŸ': 'ş',
      'Å': 'Ş',
    };
    
    // Tüm düzeltmeleri uygula - SIRALI
    // Önce bozuk sequence'ları düzelt
    brokenSequences.forEach((wrong, correct) {
      fixed = fixed.replaceAll(wrong, correct);
    });
    
    utf8DoubleEncoded.forEach((wrong, correct) {
      fixed = fixed.replaceAll(wrong, correct);
    });
    
    windows1254Fixes.forEach((wrong, correct) {
      fixed = fixed.replaceAll(wrong, correct);
    });
    
    htmlEntities.forEach((entity, char) {
      fixed = fixed.replaceAll(entity, char);
    });
    
    // === 5. REGEX İLE KALAN HTML ENTITY'LERİ TEMİZLE ===
    // &#123; formatındaki entity'ler
    fixed = fixed.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        try {
          final code = int.parse(match.group(1)!);
          return String.fromCharCode(code);
        } catch (_) {
          return match.group(0)!;
        }
      },
    );
    
    // &#x1F4A9; formatındaki hex entity'ler
    fixed = fixed.replaceAllMapped(
      RegExp(r'&#x([0-9A-Fa-f]+);'),
      (match) {
        try {
          final code = int.parse(match.group(1)!, radix: 16);
          return String.fromCharCode(code);
        } catch (_) {
          return match.group(0)!;
        }
      },
    );
    
    // === 6. CDATA VE HTML TAG TEMİZLİĞİ ===
    fixed = fixed.replaceAll(RegExp(r'<!\[CDATA\['), '');
    fixed = fixed.replaceAll(RegExp(r'\]\]>'), '');
    
    // === 7. FAZLA BOŞLUKLARI TEMİZLE ===
    fixed = fixed.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // === 8. REPLACEMENT CHARACTER TEMİZLE ===
    fixed = fixed.replaceAll('�', '');
    fixed = fixed.replaceAll('\uFFFD', '');
    
    // === 9. KALAN KONTROL KARAKTERLERİNİ TEMİZLE ===
    // 0x00-0x1F ve 0x7F-0x9F aralığındaki kontrol karakterleri
    // (tab, newline, carriage return hariç)
    fixed = fixed.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');
    
    // === 10. SON KONTROL - Hala bozuk karakter var mı? ===
    // Ã, Ä, Å karakterleri tek başına kaldıysa temizle
    if (fixed.contains('Ã') || fixed.contains('Ä') || fixed.contains('Å')) {
      // Son bir deneme daha - byte-level düzeltme
      fixed = _finalEncodingFix(fixed);
    }
    
    return fixed;
  }
  
  /// Son encoding düzeltme denemesi
  String _finalEncodingFix(String text) {
    String result = text;
    
    // Kalan bozuk pattern'leri manuel düzelt
    // Ã + herhangi bir karakter = muhtemelen bozuk UTF-8
    result = result.replaceAllMapped(
      RegExp(r'Ã([\x80-\xBF])'),
      (match) {
        final secondByte = match.group(1)!.codeUnitAt(0);
        // UTF-8 2-byte decode: 110xxxxx 10xxxxxx
        final codePoint = ((0xC3 & 0x1F) << 6) | (secondByte & 0x3F);
        return String.fromCharCode(codePoint);
      },
    );
    
    result = result.replaceAllMapped(
      RegExp(r'Ä([\x80-\xBF])'),
      (match) {
        final secondByte = match.group(1)!.codeUnitAt(0);
        final codePoint = ((0xC4 & 0x1F) << 6) | (secondByte & 0x3F);
        return String.fromCharCode(codePoint);
      },
    );
    
    result = result.replaceAllMapped(
      RegExp(r'Å([\x80-\xBF])'),
      (match) {
        final secondByte = match.group(1)!.codeUnitAt(0);
        final codePoint = ((0xC5 & 0x1F) << 6) | (secondByte & 0x3F);
        return String.fromCharCode(codePoint);
      },
    );
    
    return result;
  }

  // Güçlü RSS tarih parse fonksiyonu
  DateTime? _parseRssDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    // 1. ISO 8601 formatı: "2024-01-18T10:30:00Z" veya "2024-01-18T10:30:00+03:00"
    try {
      final result = DateTime.parse(dateStr);
      return result;
    } catch (_) {}

    // 2. RFC 822 formatı: "Mon, 01 Jan 2024 10:00:00 GMT" veya "+0300"
    // VEYA 2 haneli yıl: "Tue, 25 Jan 28 15:49:04 +0300"
    try {
      // Türkçe karakterler için genişletilmiş regex
      final rfc822Regex = RegExp(
        r'([a-zA-ZğüşöçıİĞÜŞÖÇ]+),?\s+(\d{1,2})\s+([a-zA-ZğüşöçıİĞÜŞÖÇ]+)\s+(\d{2,4})\s+(\d{2}):(\d{2}):?(\d{2})?\s*([\+\-]?\d{4}|GMT|UTC)?',
        caseSensitive: false,
      );
      final match = rfc822Regex.firstMatch(dateStr);
      if (match != null) {
        final day = int.parse(match.group(2)!);
        final monthStr = match.group(3)!;
        var year = int.parse(match.group(4)!);
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final second = match.group(7) != null ? int.parse(match.group(7)!) : 0;
        
        // 2 haneli yıl düzeltmesi
        if (year < 100) {
          year = 2000 + year;
        }
        
        // Gelecek tarih düzeltmesi - Mynet gibi siteler yanlış yıl gönderebilir
        // Eğer tarih gelecekte ise (1 günden fazla), şimdiki yıla çevir
        final now = DateTime.now();
        final month = _monthStringToNumber(monthStr);
        if (month > 0) {
          var result = DateTime.utc(year, month, day, hour, minute, second);
          
          // Eğer 1 günden fazla gelecekte ise, muhtemelen yanlış yıl
          if (result.isAfter(now.add(const Duration(days: 1)))) {
            // Şimdiki yıla çevir
            result = DateTime.utc(now.year, month, day, hour, minute, second);
            // Hala gelecekte ise geçen yıla çevir
            if (result.isAfter(now.add(const Duration(days: 1)))) {
              result = DateTime.utc(now.year - 1, month, day, hour, minute, second);
            }
          }
          
          return result;
        }
      }
    } catch (_) {}

    // 3. Sadece tarih: "2024-01-18" veya "18-01-2024" veya "18/01/2024"
    try {
      // YYYY-MM-DD
      final ymdRegex = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})');
      var match = ymdRegex.firstMatch(dateStr);
      if (match != null) {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      }
      
      // DD-MM-YYYY veya DD/MM/YYYY
      final dmyRegex = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})');
      match = dmyRegex.firstMatch(dateStr);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      }
    } catch (_) {}

    // 4. Türkçe format: "18 Ocak 2025 14:30" veya "18 Ocak 2025"
    try {
      // Türkçe karakterler için genişletilmiş regex
      final turkishRegex = RegExp(
        r'(\d{1,2})\s+([a-zA-ZğüşöçıİĞÜŞÖÇ]+)\s+(\d{4})(?:\s+(\d{2}):(\d{2}))?',
      );
      final match = turkishRegex.firstMatch(dateStr);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;
        final year = int.parse(match.group(3)!);
        final hour = match.group(4) != null ? int.parse(match.group(4)!) : 0;
        final minute = match.group(5) != null ? int.parse(match.group(5)!) : 0;
        
        final month = _monthStringToNumber(monthStr);
        if (month > 0) {
          return DateTime(year, month, day, hour, minute);
        }
      }
    } catch (_) {}

    // 5. Unix timestamp (saniye veya milisaniye)
    try {
      final timestamp = int.tryParse(dateStr);
      if (timestamp != null) {
        // Milisaniye mi saniye mi kontrol et
        if (timestamp > 1000000000000) {
          // Milisaniye
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else if (timestamp > 1000000000) {
          // Saniye
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
    } catch (_) {}

    // 6. Kısa format: "25 Jan 14:30" (yıl yok)
    try {
      // Türkçe karakterler için genişletilmiş regex
      final shortRegex = RegExp(r'(\d{1,2})\s+([a-zA-ZğüşöçıİĞÜŞÖÇ]+)\s+(\d{2}):(\d{2})');
      final match = shortRegex.firstMatch(dateStr);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;
        final hour = int.parse(match.group(3)!);
        final minute = int.parse(match.group(4)!);
        
        final month = _monthStringToNumber(monthStr);
        if (month > 0) {
          final now = DateTime.now();
          return DateTime(now.year, month, day, hour, minute);
        }
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

  /// GELİŞMİŞ GÖRSEL ÇEKME - 20+ FARKLI KAYNAK DESTEĞİ
  String? _extractImageAdvanced(XmlElement item, String? description, String? link) {
    String? imageUrl;
    
    // === 1. ENCLOSURE (En yaygın RSS görsel formatı) ===
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final url = enclosure.getAttribute('url');
      final type = enclosure.getAttribute('type') ?? '';
      if (url != null && url.isNotEmpty) {
        // Sadece resim tiplerini kabul et
        if (type.isEmpty || type.startsWith('image/')) {
          imageUrl = url;
        }
      }
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 2. MEDIA:CONTENT (Media RSS standardı) ===
    final mediaContents = item.findAllElements('media:content');
    for (final media in mediaContents) {
      final url = media.getAttribute('url');
      final medium = media.getAttribute('medium') ?? '';
      final type = media.getAttribute('type') ?? '';
      if (url != null && url.isNotEmpty) {
        if (medium == 'image' || type.startsWith('image/') || medium.isEmpty) {
          imageUrl = url;
          break;
        }
      }
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 3. MEDIA:THUMBNAIL ===
    final mediaThumbnails = item.findAllElements('media:thumbnail');
    for (final thumb in mediaThumbnails) {
      final url = thumb.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        imageUrl = url;
        break;
      }
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 4. MEDIA:GROUP İÇİNDEKİ GÖRSELLER ===
    final mediaGroups = item.findAllElements('media:group');
    for (final group in mediaGroups) {
      // media:content
      final content = group.findElements('media:content').firstOrNull;
      if (content != null) {
        final url = content.getAttribute('url');
        if (url != null && url.isNotEmpty) {
          imageUrl = url;
          break;
        }
      }
      // media:thumbnail
      final thumb = group.findElements('media:thumbnail').firstOrNull;
      if (thumb != null) {
        final url = thumb.getAttribute('url');
        if (url != null && url.isNotEmpty) {
          imageUrl = url;
          break;
        }
      }
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 5. IMAGE ELEMENT (Bazı RSS'lerde direkt) ===
    final imageElement = item.findElements('image').firstOrNull;
    if (imageElement != null) {
      // URL attribute
      final urlAttr = imageElement.getAttribute('url');
      if (urlAttr != null && urlAttr.isNotEmpty) {
        imageUrl = urlAttr;
      }
      // İç metin
      if (imageUrl == null) {
        final innerUrl = imageElement.innerText.trim();
        if (innerUrl.isNotEmpty && innerUrl.startsWith('http')) {
          imageUrl = innerUrl;
        }
      }
      // url child element
      if (imageUrl == null) {
        final urlChild = imageElement.findElements('url').firstOrNull;
        if (urlChild != null) {
          imageUrl = urlChild.innerText.trim();
        }
      }
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 6. ITUNES:IMAGE (Podcast/Haber RSS) ===
    final itunesImage = item.findElements('itunes:image').firstOrNull;
    if (itunesImage != null) {
      final url = itunesImage.getAttribute('href') ?? itunesImage.innerText.trim();
      if (url.isNotEmpty) {
        imageUrl = url;
      }
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 7. CONTENT:ENCODED İÇİNDEKİ GÖRSELLER ===
    final contentEncoded = item.findElements('content:encoded').firstOrNull?.innerText;
    if (contentEncoded != null && contentEncoded.isNotEmpty) {
      imageUrl = _extractImageFromHtml(contentEncoded);
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 8. DESCRIPTION İÇİNDEKİ GÖRSELLER ===
    if (description != null && description.isNotEmpty) {
      imageUrl = _extractImageFromHtml(description);
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 9. SUMMARY İÇİNDEKİ GÖRSELLER ===
    final summary = item.findElements('summary').firstOrNull?.innerText;
    if (summary != null && summary.isNotEmpty) {
      imageUrl = _extractImageFromHtml(summary);
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 10. ATOM:LINK REL="ENCLOSURE" ===
    final atomLinks = item.findAllElements('link');
    for (final atomLink in atomLinks) {
      final rel = atomLink.getAttribute('rel');
      final type = atomLink.getAttribute('type') ?? '';
      final href = atomLink.getAttribute('href');
      if (rel == 'enclosure' && href != null && type.startsWith('image/')) {
        imageUrl = href;
        break;
      }
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 11. FEATURED IMAGE / POST THUMBNAIL ===
    final featuredImage = item.findElements('featured_image').firstOrNull?.innerText ??
                          item.findElements('post-thumbnail').firstOrNull?.innerText ??
                          item.findElements('thumbnail').firstOrNull?.innerText;
    if (featuredImage != null && featuredImage.isNotEmpty) {
      imageUrl = featuredImage;
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 12. OG:IMAGE META (Bazı RSS'ler bunu içerir) ===
    final ogImage = item.findElements('og:image').firstOrNull?.innerText;
    if (ogImage != null && ogImage.isNotEmpty) {
      imageUrl = ogImage;
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 13. GUID'DEN GÖRSEL ÇIKARMA (Bazı siteler GUID'e resim koyar) ===
    final guid = item.findElements('guid').firstOrNull?.innerText;
    if (guid != null && _isValidImageUrl(guid)) {
      imageUrl = guid;
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // === 14. LINK'TEN DOMAIN BAZLI GÖRSEL TAHMİNİ ===
    if (link != null && link.isNotEmpty) {
      imageUrl = _guessImageFromLink(link);
    }
    if (_isValidImageUrl(imageUrl)) return _cleanImageUrl(imageUrl!);
    
    // Görsel bulunamadı - null dön, fallback _fetchRssFeed'de uygulanacak
    return null;
  }
  
  /// Firebase Storage'dan kaynak görseli URL'si oluştur
  /// Kaynak ID'sine göre görsel çeker
  String _getSourceFallbackImageUrl(String sourceName) {
    // Kaynak adını normalize et (Halk TV -> halk_tv)
    final normalizedName = _normalizeSourceName(sourceName);
    
    // Firebase Storage bucket URL'si
    const storageBucket = 'newsly-70ef9.firebasestorage.app';
    
    // source_logos klasöründen kaynak adıyla eşleşen görseli çek
    // PNG formatı varsayılan
    return 'https://firebasestorage.googleapis.com/v0/b/$storageBucket/o/source_logos%2F$normalizedName.png?alt=media';
  }

  /// HTML içeriğinden görsel URL çıkar
  String? _extractImageFromHtml(String html) {
    // Birden fazla pattern dene
    final patterns = <RegExp>[
      // Standart img tag
      RegExp(r'''<img[^>]+src=["']([^"']+)["']''', caseSensitive: false),
      // data-src (lazy loading)
      RegExp(r'''<img[^>]+data-src=["']([^"']+)["']''', caseSensitive: false),
      // data-lazy-src
      RegExp(r'''<img[^>]+data-lazy-src=["']([^"']+)["']''', caseSensitive: false),
      // srcset (ilk URL'yi al)
      RegExp(r'''<img[^>]+srcset=["']([^\s"']+)''', caseSensitive: false),
      // background-image CSS
      RegExp(r'''background-image:\s*url\(["']?([^"')\s]+)["']?\)''', caseSensitive: false),
      // figure > img
      RegExp(r'''<figure[^>]*>.*?<img[^>]+src=["']([^"']+)["']''', caseSensitive: false),
      // picture > source
      RegExp(r'''<source[^>]+srcset=["']([^\s"']+)''', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final url = match.group(1);
        if (url != null && _isValidImageUrl(url)) {
          return url;
        }
      }
    }
    
    return null;
  }

  /// Link'ten domain bazlı görsel tahmini
  String? _guessImageFromLink(String link) {
    try {
      final uri = Uri.parse(link);
      final host = uri.host.toLowerCase();
      
      // Bazı siteler için bilinen görsel URL pattern'leri
      // Bu genellikle çalışmaz ama bazı siteler için işe yarayabilir
      
      // Örnek: Haber sitelerinin CDN pattern'leri
      // Bu kısım site bazlı özelleştirilebilir
      
      return null; // Şimdilik null dön
    } catch (_) {
      return null;
    }
  }

  /// Görsel URL'sinin geçerli olup olmadığını kontrol et
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    // URL formatı kontrolü
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }
    
    // Minimum uzunluk
    if (url.length < 10) return false;
    
    // Bilinen görsel uzantıları
    final lowerUrl = url.toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'];
    final hasImageExtension = imageExtensions.any((ext) => lowerUrl.contains(ext));
    
    // Bilinen görsel CDN'leri
    final imageCdns = [
      'cdn.', 'img.', 'image.', 'images.', 'media.', 'static.',
      'assets.', 'upload.', 'uploads.', 'photo.', 'photos.',
      'pic.', 'pics.', 'thumb.', 'thumbnail.', 'i.', 'im.',
      'cloudinary.com', 'imgix.net', 'cloudfront.net', 'akamaized.net',
      'wp-content/uploads', 'files/', 'resim/', 'gorsel/', 'foto/',
    ];
    final isFromCdn = imageCdns.any((cdn) => lowerUrl.contains(cdn));
    
    // Görsel uzantısı veya CDN'den geliyorsa geçerli
    if (hasImageExtension || isFromCdn) {
      return true;
    }
    
    // Query string'de görsel parametresi var mı
    if (lowerUrl.contains('image=') || lowerUrl.contains('img=') || 
        lowerUrl.contains('photo=') || lowerUrl.contains('pic=')) {
      return true;
    }
    
    return false;
  }

  /// Görsel URL'sini temizle ve optimize et
  String _cleanImageUrl(String url) {
    String cleaned = url.trim();
    
    // HTML entity decode
    cleaned = cleaned.replaceAll('&amp;', '&');
    
    // Protokol düzeltme
    if (cleaned.startsWith('//')) {
      cleaned = 'https:$cleaned';
    }
    
    // Boşlukları encode et
    cleaned = cleaned.replaceAll(' ', '%20');
    
    // Bazı siteler için boyut optimizasyonu
    // Küçük thumbnail yerine büyük resim al
    cleaned = cleaned.replaceAll(RegExp(r'-\d+x\d+\.'), '.'); // WordPress thumbnail
    cleaned = cleaned.replaceAll(RegExp(r'_thumb\.'), '.'); // Generic thumbnail
    cleaned = cleaned.replaceAll(RegExp(r'\?.*w=\d+'), ''); // Width parameter
    
    return cleaned;
  }

  String? _extractImage(XmlElement item, String? description) {
    // Eski fonksiyon - geriye uyumluluk için
    return _extractImageAdvanced(item, description, null);
  }
}

// Dart'ın built-in HttpDate parser'ı için extension veya import gerekebilir mi?
// HttpDate 'dart:io' içindedir. Eğer web ise çalışmaz. intl ile deneyelim.
// HttpDate yerine intl kullanacağım.
// Ancak HttpDate parse işlemi çok standarttır.
// RSS date format (RFC 822) parsed by HttpDate usually works.
