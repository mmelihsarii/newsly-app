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
      name: data['name'] ?? '',
      category: data['category'] ?? 'Gündem',
      rssUrl: data['rss_url'] ?? data['url'] ?? '',
      isActive: data['is_active'] ?? true,
    );
  }

  /// Create from Map (for local data)
  factory SourceModel.fromMap(Map<String, dynamic> map, String docId) {
    return SourceModel(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Gündem',
      rssUrl: map['rss_url'] ?? map['url'] ?? '',
      isActive: map['is_active'] ?? true,
    );
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
