class ApiConstants {
  // Kendi panel adresini buraya yaz (Sonunda /api/ olsun)
  static const String baseUrl = "https://admin.newsly.com.tr/api/";

  // Uç Noktalar (Backend rotalarından çıkardık)
  static const String getNews =
      "get_news_by_category"; // Veya news_list, dökümana bakacağız
  static const String getCategories = "category_list";
  static const String getCities = "cities";
  static const String getFeaturedSections = "get_featured_sections";
}
