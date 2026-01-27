import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for news source from Firestore news_sources collection
class SourceModel {
  final String id;
  final String name;
  final String category;
  final String rssUrl;
  final bool isActive;

  SourceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.rssUrl,
    required this.isActive,
  });

  /// Create from Firestore document
  factory SourceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SourceModel(
      id: doc.id,
      name: _fixEncoding(data['name'] ?? ''),
      category: _fixEncoding(data['category'] ?? 'Gündem'),
      rssUrl: data['rss_url'] ?? data['url'] ?? '',
      isActive: data['is_active'] ?? true,
    );
  }

  /// Create from Map (for local data)
  factory SourceModel.fromMap(Map<String, dynamic> map, String docId) {
    return SourceModel(
      id: docId,
      name: _fixEncoding(map['name'] ?? ''),
      category: _fixEncoding(map['category'] ?? 'Gündem'),
      rssUrl: map['rss_url'] ?? map['url'] ?? '',
      isActive: map['is_active'] ?? true,
    );
  }
  
  /// Encoding sorunlarını düzelt
  static String _fixEncoding(String text) {
    if (text.isEmpty) return text;
    
    String fixed = text;
    
    // UTF-8 double encoding düzeltmeleri
    final fixes = {
      // Türkçe karakterler
      'Ä±': 'ı', 'Ä°': 'İ', 'ÄŸ': 'ğ', 'Ä': 'Ğ',
      'Ã¼': 'ü', 'Ãœ': 'Ü', 'ÅŸ': 'ş', 'Å': 'Ş',
      'Ã¶': 'ö', 'Ã–': 'Ö', 'Ã§': 'ç', 'Ã‡': 'Ç',
      'Ã¢': 'â', 'Ã®': 'î', 'Ã»': 'û',
      // Byte sequence düzeltmeleri
      '\u00C4\u00B1': 'ı', '\u00C4\u009F': 'ğ', '\u00C5\u009F': 'ş',
      '\u00C4\u00B0': 'İ', '\u00C4\u009E': 'Ğ', '\u00C5\u009E': 'Ş',
      '\u00C3\u00B6': 'ö', '\u00C3\u00BC': 'ü', '\u00C3\u00A7': 'ç',
      '\u00C3\u0096': 'Ö', '\u00C3\u009C': 'Ü', '\u00C3\u0087': 'Ç',
      // Windows-1254 düzeltmeleri
      'Ý': 'İ', 'ý': 'ı', 'Þ': 'Ş', 'þ': 'ş', 'Ð': 'Ğ', 'ð': 'ğ',
      // HTML entities
      '&amp;': '&', '&apos;': "'", '&quot;': '"',
      '&#305;': 'ı', '&#304;': 'İ', '&#287;': 'ğ', '&#286;': 'Ğ',
      '&#252;': 'ü', '&#220;': 'Ü', '&#351;': 'ş', '&#350;': 'Ş',
      '&#246;': 'ö', '&#214;': 'Ö', '&#231;': 'ç', '&#199;': 'Ç',
    };
    
    fixes.forEach((wrong, correct) {
      fixed = fixed.replaceAll(wrong, correct);
    });
    
    // Kalan bozuk Ã, Ä, Å pattern'lerini düzelt
    fixed = fixed.replaceAllMapped(
      RegExp(r'[\u00C0-\u00C5]([\u0080-\u00BF])'),
      (match) {
        final c1 = match.group(0)!.codeUnitAt(0);
        final c2 = match.group(1)!.codeUnitAt(0);
        final codePoint = ((c1 & 0x1F) << 6) | (c2 & 0x3F);
        return String.fromCharCode(codePoint);
      },
    );
    
    // Kontrol karakterlerini temizle
    fixed = fixed.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');
    
    return fixed.trim();
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'rss_url': rssUrl,
      'is_active': isActive,
    };
  }

  @override
  String toString() => 'SourceModel(id: $id, name: $name, category: $category)';
}

/// Category model for grouping sources
class SourceCategory {
  final String id;
  final String name;
  final List<SourceModel> sources;

  SourceCategory({
    required this.id,
    required this.name,
    required this.sources,
  });
}
