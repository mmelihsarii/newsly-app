import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../models/news_model.dart';

/// Haber önbellekleme servisi
/// - Haberleri yerel depoda saklar
/// - Belirli süre sonra cache'i geçersiz kılar
/// - Offline modda cache'den okur
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final GetStorage _storage = GetStorage();

  // Cache key'leri
  static const String _newsListKey = 'cached_news_list';
  static const String _newsCacheTimeKey = 'news_cache_time';
  static const String _sectionStructureKey = 'cached_section_structure';
  static const String _sectionCacheTimeKey = 'section_cache_time';

  // Cache süresi (dakika)
  static const int _cacheDurationMinutes = 15;

  // ═══════════════════════════════════════════════════════════════════════════
  // HABER CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Haberleri cache'e kaydet
  Future<void> cacheNews(List<NewsModel> news) async {
    try {
      final jsonList = news.map((n) => n.toJson()).toList();
      await _storage.write(_newsListKey, jsonEncode(jsonList));
      await _storage.write(_newsCacheTimeKey, DateTime.now().toIso8601String());
      print('💾 ${news.length} haber cache\'e kaydedildi');
    } catch (e) {
      print('❌ Cache kaydetme hatası: $e');
    }
  }

  /// Cache'den haberleri oku
  List<NewsModel>? getCachedNews() {
    try {
      final jsonString = _storage.read<String>(_newsListKey);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final news = jsonList.map((json) => NewsModel.fromJson(json)).toList();
      print('📦 Cache\'den ${news.length} haber okundu');
      return news;
    } catch (e) {
      print('❌ Cache okuma hatası: $e');
      return null;
    }
  }

  /// Cache geçerli mi kontrol et
  bool isNewsCacheValid() {
    try {
      final cacheTimeStr = _storage.read<String>(_newsCacheTimeKey);
      if (cacheTimeStr == null) return false;

      final cacheTime = DateTime.parse(cacheTimeStr);
      final now = DateTime.now();
      final difference = now.difference(cacheTime).inMinutes;

      final isValid = difference < _cacheDurationMinutes;
      print('⏱️ Cache yaşı: $difference dk, Geçerli: $isValid');
      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// Cache'i temizle
  Future<void> clearNewsCache() async {
    await _storage.remove(_newsListKey);
    await _storage.remove(_newsCacheTimeKey);
    print('🗑️ Haber cache\'i temizlendi');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION STRUCTURE CACHE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Section yapısını cache'e kaydet
  Future<void> cacheSectionStructure(Map<String, dynamic> structure) async {
    try {
      await _storage.write(_sectionStructureKey, jsonEncode(structure));
      await _storage.write(_sectionCacheTimeKey, DateTime.now().toIso8601String());
      print('💾 Section yapısı cache\'e kaydedildi');
    } catch (e) {
      print('❌ Section cache kaydetme hatası: $e');
    }
  }

  /// Cache'den section yapısını oku
  Map<String, dynamic>? getCachedSectionStructure() {
    try {
      final jsonString = _storage.read<String>(_sectionStructureKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Section cache okuma hatası: $e');
      return null;
    }
  }

  /// Section cache geçerli mi
  bool isSectionCacheValid() {
    try {
      final cacheTimeStr = _storage.read<String>(_sectionCacheTimeKey);
      if (cacheTimeStr == null) return false;

      final cacheTime = DateTime.parse(cacheTimeStr);
      final now = DateTime.now();
      final difference = now.difference(cacheTime).inMinutes;

      return difference < _cacheDurationMinutes * 2; // Section için daha uzun cache
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENEL CACHE YÖNETİMİ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Tüm cache'i temizle
  Future<void> clearAllCache() async {
    await clearNewsCache();
    await _storage.remove(_sectionStructureKey);
    await _storage.remove(_sectionCacheTimeKey);
    print('🗑️ Tüm cache temizlendi');
  }

  /// Cache boyutunu al (yaklaşık)
  int getCacheSize() {
    int size = 0;
    final newsJson = _storage.read<String>(_newsListKey);
    final sectionJson = _storage.read<String>(_sectionStructureKey);
    
    if (newsJson != null) size += newsJson.length;
    if (sectionJson != null) size += sectionJson.length;
    
    return size;
  }

  /// Cache bilgilerini al
  Map<String, dynamic> getCacheInfo() {
    final newsCacheTime = _storage.read<String>(_newsCacheTimeKey);
    final sectionCacheTime = _storage.read<String>(_sectionCacheTimeKey);
    
    return {
      'newsCount': getCachedNews()?.length ?? 0,
      'newsCacheTime': newsCacheTime,
      'isNewsCacheValid': isNewsCacheValid(),
      'sectionCacheTime': sectionCacheTime,
      'isSectionCacheValid': isSectionCacheValid(),
      'approximateSize': '${(getCacheSize() / 1024).toStringAsFixed(2)} KB',
    };
  }
}
