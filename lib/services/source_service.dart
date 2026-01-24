import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import '../models/source_model.dart';

/// Service for managing news sources from Firestore
class SourceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetStorage _storage = GetStorage();

  // Cache keys
  static const String _sourcesKey = 'cached_sources';
  static const String _sourcesCacheTimeKey = 'sources_cache_time';
  static const int _cacheDurationMinutes = 30;

  String? get _userId => _auth.currentUser?.uid;

  /// Stream of active sources from Firestore (real-time updates)
  Stream<List<SourceModel>> getSourcesStream() {
    return _db
        .collection('news_sources')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final sources = snapshot.docs
          .map((doc) => SourceModel.fromFirestore(doc))
          .toList();
      
      // Cache locally
      _cacheSources(sources);
      
      return sources;
    });
  }

  /// Get sources grouped by category (real-time stream)
  Stream<List<SourceCategory>> getSourcesByCategoryStream() {
    return getSourcesStream().map((sources) => _groupByCategory(sources));
  }

  /// Get sources once (with cache)
  Future<List<SourceModel>> getSources({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _isCacheValid()) {
      final cached = _getCachedSources();
      if (cached.isNotEmpty) {
        print('📦 Cache\'den ${cached.length} kaynak yüklendi');
        return cached;
      }
    }

    try {
      print('🔍 Firestore news_sources sorgulanıyor...');
      
      // First try without is_active filter to see all documents
      final allSnapshot = await _db.collection('news_sources').get();
      print('📊 Toplam döküman sayısı: ${allSnapshot.docs.length}');
      
      // Log first few documents for debugging
      for (var i = 0; i < allSnapshot.docs.length && i < 3; i++) {
        final doc = allSnapshot.docs[i];
        print('📄 Döküman ${doc.id}: ${doc.data()}');
      }
      
      // Now filter active ones
      final sources = allSnapshot.docs
          .map((doc) => SourceModel.fromFirestore(doc))
          .where((source) => source.isActive)
          .toList();

      // Cache locally
      if (sources.isNotEmpty) {
        _cacheSources(sources);
      }
      
      print('☁️ Firestore\'dan ${sources.length} aktif kaynak yüklendi');
      return sources;
    } catch (e) {
      print('❌ Kaynak yükleme hatası: $e');
      print('❌ Hata detayı: ${e.toString()}');
      // Return cached data on error
      return _getCachedSources();
    }
  }

  /// Get sources grouped by category
  Future<List<SourceCategory>> getSourcesByCategory({bool forceRefresh = false}) async {
    final sources = await getSources(forceRefresh: forceRefresh);
    return _groupByCategory(sources);
  }

  /// Group sources by category
  List<SourceCategory> _groupByCategory(List<SourceModel> sources) {
    final Map<String, List<SourceModel>> grouped = {};
    
    for (final source in sources) {
      final category = source.category.isNotEmpty ? source.category : 'Diğer';
      
      // Skip "Genel" category
      if (category.toLowerCase() == 'genel') continue;
      
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(source);
    }

    // Sort categories and sources alphabetically
    final categories = grouped.entries.map((entry) {
      // Sort sources alphabetically by name
      final sortedSources = entry.value..sort((a, b) => a.name.compareTo(b.name));
      return SourceCategory(
        id: _normalizeId(entry.key),
        name: entry.key,
        sources: sortedSources,
      );
    }).toList();

    // Sort categories alphabetically by name
    categories.sort((a, b) => a.name.compareTo(b.name));
    
    return categories;
  }

  /// Get user's followed source IDs
  Future<List<String>> getUserFollowedSources() async {
    if (_userId == null) {
      // Return from local storage for guests
      final local = _storage.read<List<dynamic>>('selected_sources');
      return local?.cast<String>() ?? [];
    }

    try {
      final doc = await _db.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data();
        final sources = data?['selectedSources'] ?? data?['followed_source_ids'];
        if (sources != null) {
          return (sources as List<dynamic>).cast<String>();
        }
      }
    } catch (e) {
      print('❌ Kullanıcı kaynakları yükleme hatası: $e');
    }
    
    return [];
  }

  /// Save user's followed source IDs
  Future<void> saveUserFollowedSources(List<String> sourceIds) async {
    // Always save locally
    _storage.write('selected_sources', sourceIds);

    if (_userId == null) return;

    try {
      await _db.collection('users').doc(_userId).set({
        'selectedSources': sourceIds,
        'followed_source_ids': sourceIds, // Backward compatibility
        'selectedSourcesUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('☁️ ${sourceIds.length} kaynak Firestore\'a kaydedildi');
    } catch (e) {
      print('❌ Kaynak kaydetme hatası: $e');
    }
  }

  /// Toggle a source selection
  Future<void> toggleSource(String sourceId, List<String> currentSelection) async {
    final newSelection = List<String>.from(currentSelection);
    
    if (newSelection.contains(sourceId)) {
      newSelection.remove(sourceId);
    } else {
      newSelection.add(sourceId);
    }
    
    await saveUserFollowedSources(newSelection);
  }

  // ==================== CACHE HELPERS ====================

  void _cacheSources(List<SourceModel> sources) {
    final data = sources.map((s) => {
      'id': s.id,
      'name': s.name,
      'category': s.category,
      'rss_url': s.rssUrl,
      'is_active': s.isActive,
    }).toList();
    
    _storage.write(_sourcesKey, data);
    _storage.write(_sourcesCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  List<SourceModel> _getCachedSources() {
    final data = _storage.read<List<dynamic>>(_sourcesKey);
    if (data == null) return [];
    
    return data.map((item) {
      final map = Map<String, dynamic>.from(item);
      return SourceModel.fromMap(map, map['id'] ?? '');
    }).toList();
  }

  bool _isCacheValid() {
    final cacheTime = _storage.read<int>(_sourcesCacheTimeKey);
    if (cacheTime == null) return false;
    
    final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
    return age < _cacheDurationMinutes * 60 * 1000;
  }

  /// Normalize category name to ID
  String _normalizeId(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('&', '')
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }
}
