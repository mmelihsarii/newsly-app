import 'news_model.dart';

class FeaturedSectionModel {
  final int? id;
  final String? title;
  final String? type; // 'slider', 'horizontal_list', 'breaking_news', etc.
  final int? order;
  final bool? isActive;
  final List<NewsModel> news;

  FeaturedSectionModel({
    this.id,
    this.title,
    this.type,
    this.order,
    this.isActive,
    this.news = const [],
  });

  factory FeaturedSectionModel.fromJson(Map<String, dynamic> json) {
    List<NewsModel> newsList = [];
    
    if (json['news'] != null && json['news'] is List) {
      newsList = (json['news'] as List)
          .map((item) => NewsModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return FeaturedSectionModel(
      id: json['id'],
      title: json['title'],
      type: json['type'] ?? json['section_type'] ?? 'horizontal_list',
      order: json['order'] ?? json['sort_order'] ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      news: newsList,
    );
  }
}
