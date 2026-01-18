import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart' as xml;
import '../models/news_model.dart';
import '../controllers/interest_controller.dart';
import '../utils/city_data.dart';
import '../services/api_service.dart';

class FollowController extends GetxController {
  final ApiService _apiService = ApiService();
  final Dio _dio = Dio();

  var isLoading = false.obs;
  var newsList = <NewsModel>[].obs;
  var errorMessage = ''.obs;

  InterestController get interestController => Get.find<InterestController>();

  @override
  void onInit() {
    super.onInit();
    fetchFollowedNews();
  }

  // Takip edilen kaynaklardan haberleri çek
  Future<void> fetchFollowedNews() async {
    try {
      isLoading(true);
      errorMessage('');
      newsList.clear();

      final List<NewsModel> allNews = [];

      // 1. Takip edilen şehirlerden RSS haberleri çek
      final followedCities = interestController.followedCities;
      for (final cityName in followedCities) {
        final cityData = CityData.cities.firstWhere(
          (c) => c['name'] == cityName,
          orElse: () => {},
        );
        if (cityData.isNotEmpty && cityData['rss'] != null) {
          final rssNews = await _fetchRssNews(cityData['rss'], cityName);
          allNews.addAll(rssNews);
        }
      }

      // 2. Takip edilen kategorilerden API haberleri çek
      final followedCategories = interestController.followedCategories;
      for (final categoryName in followedCategories) {
        final categoryNews = await _fetchCategoryNews(categoryName);
        allNews.addAll(categoryNews);
      }

      // Tarihe göre sırala (en yeni en üstte)
      allNews.sort((a, b) {
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

      // Duplicate kontrolü (aynı başlık)
      final seen = <String>{};
      final uniqueNews = <NewsModel>[];
      for (final news in allNews) {
        if (news.title != null && !seen.contains(news.title)) {
          seen.add(news.title!);
          uniqueNews.add(news);
        }
      }

      newsList.value = uniqueNews.take(50).toList(); // Max 50 haber
    } catch (e) {
      print('FollowController Hata: $e');
      errorMessage('Haberler yüklenirken bir hata oluştu');
    } finally {
      isLoading(false);
    }
  }

  // RSS'ten haber çek
  Future<List<NewsModel>> _fetchRssNews(String rssUrl, String cityName) async {
    try {
      final response = await _dio.get(
        rssUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final document = xml.XmlDocument.parse(response.data);
      final items = document.findAllElements('item');

      return items.take(10).map((item) {
        String? imageUrl;

        // enclosure'dan resim al
        final enclosure = item.findElements('enclosure').firstOrNull;
        if (enclosure != null) {
          imageUrl = enclosure.getAttribute('url');
        }

        // media:content'ten resim al
        if (imageUrl == null) {
          final mediaContent = item.findElements('media:content').firstOrNull;
          if (mediaContent != null) {
            imageUrl = mediaContent.getAttribute('url');
          }
        }

        return NewsModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: item.findElements('title').firstOrNull?.innerText,
          description: item.findElements('description').firstOrNull?.innerText,
          image: imageUrl,
          date: item.findElements('pubDate').firstOrNull?.innerText,
          categoryName: cityName,
          sourceUrl: item.findElements('link').firstOrNull?.innerText,
        );
      }).toList();
    } catch (e) {
      print('RSS Hata ($cityName): $e');
      return [];
    }
  }

  // Kategori ismi -> ID eşleştirmesi (Backend veritabanından)
  static const Map<String, int> _categoryIds = {
    'Yerel Haberler': 1,
    'Son Dakika': 2,
    'Gündem': 3,
    'Spor': 4,
    'Ekonomi': 5,
    'Ekonomi & Finans': 5,
    'Bilim': 6,
    'Teknoloji': 6,
    'Bilim & Teknoloji': 6,
    'Haber Ajansları': 9,
    'Yabancı Kaynaklar': 10,
  };

  // API'den kategori haberleri çek
  Future<List<NewsModel>> _fetchCategoryNews(String categoryName) async {
    try {
      // Kategori ID'sini bul
      final categoryId = _categoryIds[categoryName];
      if (categoryId == null) {
        print('Kategori ID bulunamadı: $categoryName');
        return [];
      }

      final response = await _apiService.postData('get_news', {
        'language_id': '2',
        'access_key': '6808',
        'category_id': categoryId.toString(),
        'limit': '10',
        'offset': '0',
      });

      if (response != null && response['error'] == false) {
        final list = response['data'] as List;
        return list.map((item) => NewsModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('API Hata ($categoryName): $e');
      return [];
    }
  }

  // Takip edilen var mı?
  bool get hasFollowedItems =>
      interestController.followedCities.isNotEmpty ||
      interestController.followedCategories.isNotEmpty;
}
