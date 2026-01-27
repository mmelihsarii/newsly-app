import 'news_model.dart';

class FeaturedSectionModel {
  final int? id;
  final String? title;
  final String? type; // 'slider', 'horizontal_list', 'breaking_news', 'grid', etc.
  final int? order;
  final bool? isActive;
  final String? styleApp; // style_1, style_2, ... style_6
  final String? styleWeb;
  final String? backgroundColor;
  final String? textColor;
  final int? itemCount;
  final List<NewsModel> news;

  FeaturedSectionModel({
    this.id,
    this.title,
    this.type,
    this.order,
    this.isActive,
    this.styleApp,
    this.styleWeb,
    this.backgroundColor,
    this.textColor,
    this.itemCount,
    this.news = const [],
  });

  factory FeaturedSectionModel.fromJson(Map<String, dynamic> json) {
    List<NewsModel> newsList = [];
    
    // Haberler farklı key'lerde olabilir
    final newsData = json['news'] ?? json['items'] ?? json['articles'] ?? json['featured_news'];
    
    if (newsData != null && newsData is List) {
      newsList = newsData
          .map((item) {
            if (item is Map<String, dynamic>) {
              return NewsModel.fromJson(item);
            }
            return null;
          })
          .whereType<NewsModel>()
          .toList();
    }

    // Style'a göre type belirle (Panel'deki mantık)
    String? styleApp = json['style_app'] ?? json['styleApp'];
    String type = json['type'] ?? 'horizontal_list';
    
    // Eğer type gelmemişse style'dan belirle
    if (json['type'] == null && styleApp != null) {
      if (styleApp == 'style_1' || styleApp == 'style_6') {
        type = 'slider';
      } else if (styleApp == 'style_4') {
        type = 'breaking_news';
      } else {
        type = 'horizontal_list';
      }
    }

    return FeaturedSectionModel(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? json['section_title'],
      type: type,
      order: json['order'] ?? json['row_order'] ?? json['sort_order'] ?? json['position'] ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['active'] == 1 || json['active'] == true,
      styleApp: styleApp,
      styleWeb: json['style_web'] ?? json['styleWeb'],
      backgroundColor: json['background_color'] ?? json['bg_color'],
      textColor: json['text_color'],
      itemCount: json['item_count'] ?? json['limit'],
      news: newsList,
    );
  }
}
