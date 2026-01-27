class ApiConstants {
  // Kendi panel adresini buraya yaz (Sonunda /api/ olsun)
  static const String baseUrl = "https://admin.newsly.com.tr/api/";

  // Uç Noktalar (Backend rotalarından çıkardık)
  static const String getNews =
      "get_news_by_category"; // Veya news_list, dökümana bakacağız
  static const String getCategories = "category_list";
  static const String getCities = "cities";
  static const String getFeaturedSections = "get_featured_sections";
  
  // Haber Detay
  static const String getNewsDetail = "news_detail"; // /api/news_detail?id=123
  
  // Canlı Yayınlar
  static const String getLiveStreams = "get_live_streams";
}
