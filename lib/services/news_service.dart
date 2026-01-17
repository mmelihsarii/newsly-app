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
      '.': '_',
    };

    String normalized = name.toLowerCase();
    turkishChars.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });
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

  // 1. Firestore'dan Haber Kaynaklarını Çek (Sadece is_active: true ve kullanıcı seçimleri)
  Future<List<Map<String, dynamic>>> fetchNewsSources() async {
    try {
      // Get user's selected sources
      final Set<String> selectedSet = await _getSelectedSources();

      print("🔥 Firestore'dan kaynaklar çekiliyor...");
      print("📌 Kullanıcı ${selectedSet.length} kaynak seçmiş");

      // Debug: Print some selected sources
      if (selectedSet.isNotEmpty) {
        print("📋 Seçili kaynaklar (ilk 5): ${selectedSet.take(5).toList()}");
      }

      QuerySnapshot snapshot = await _firestore
          .collection('news_sources')
          .where('is_active', isEqualTo: true)
          .get();

      var sources = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      print("📰 Firestore'da ${sources.length} aktif kaynak var");

      // Filter by user's selected sources if they have made selections
      if (selectedSet.isNotEmpty) {
        final originalCount = sources.length;

        sources = sources.where((source) {
          final sourceId = source['id'] as String?;
          final sourceName = source['name'] as String?;
          final normalizedName = sourceName != null
              ? _normalizeSourceName(sourceName)
              : '';

          // Match by ID, normalized name, or exact name (lowercase)
          final matches =
              selectedSet.contains(sourceId) ||
              selectedSet.contains(normalizedName) ||
              selectedSet.contains(sourceName?.toLowerCase());

          // Debug: Log match attempts
          if (!matches && sourceName != null) {
            print("❌ Eşleşmedi: '$sourceName' (normalized: '$normalizedName')");
          }

          return matches;
        }).toList();

        print("✅ Filtrelenmiş: $originalCount → ${sources.length} kaynak");

        // If no sources matched, it might be a mismatch issue
        if (sources.isEmpty && originalCount > 0) {
          print(
            "⚠️ UYARI: Hiç kaynak eşleşmedi! Seçili ID'ler ile Firestore isimleri uyuşmuyor olabilir.",
          );
          print(
            "📋 Firestore kaynak isimleri: ${snapshot.docs.take(5).map((d) => (d.data() as Map)['name']).toList()}",
          );
        }
      } else {
        print("✅ Tüm kaynaklar kullanılıyor: ${sources.length}");
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

    // Her kaynaktan paralel olarak veri çek
    await Future.wait(
      sources.map((source) async {
        String url = source['rss_url'] ?? '';
        String sourceName = source['name'] ?? 'Bilinmeyen Kaynak';

        if (url.isNotEmpty) {
          try {
            var fetchedNews = await _fetchRssFeed(url, sourceName);
            allNews.addAll(fetchedNews);
          } catch (e) {
            print("⚠️ $sourceName ($url) hatası: $e");
          }
        }
      }),
    );

    allNews.shuffle();
    return allNews;
  }

  // Tekil RSS Çekme ve Parse Etme
  Future<List<NewsModel>> _fetchRssFeed(String url, String sourceName) async {
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

          // Tarih formatlama
          String formattedDate = '';
          if (pubDateStr != null) {
            try {
              // RSS tarih formatı genellikle: "Mon, 01 Jan 2024 10:00:00 GMT"
              final dateTime = HttpDate.parse(pubDateStr);
              // Veya DateFormat("EEE, dd MMM yyyy HH:mm:ss z").parse(pubDateStr);
              formattedDate = DateFormat('dd MMM HH:mm').format(dateTime);
            } catch (_) {
              formattedDate = pubDateStr; // Parse edilemezse olduğu gibi göster
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
              categoryName: "Gündem",
            ),
          );
        }
      }
    } catch (e) {
      print("RSS Parse Hatası ($url): $e");
    }
    return newsList;
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
