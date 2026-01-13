import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../utils/city_data.dart';
import '../models/news_model.dart';

class LocalController extends GetxController {
  final Dio _dio = Dio();

  // Şehir listesi
  var cityList = <Map<String, dynamic>>[].obs;
  var selectedCity = Rxn<Map<String, dynamic>>();

  // Haber listesi
  var localNewsList = <NewsModel>[].obs;

  // Loading states
  var isCitiesLoading = false.obs;
  var isNewsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCities();
  }

  /// Şehirleri statik listeden yükle
  void loadCities() {
    cityList.assignAll(CityData.cities);

    // İlk şehri varsayılan olarak seç
    if (cityList.isNotEmpty) {
      selectedCity.value = cityList.first;
      fetchLocalNews();
    }
  }

  /// Seçilen şehrin haberlerini RSS'den çek
  Future<void> fetchLocalNews() async {
    if (selectedCity.value == null) return;

    try {
      isNewsLoading.value = true;
      localNewsList.clear();

      final rssLink = selectedCity.value!['rss'];

      if (rssLink == null || rssLink.isEmpty) {
        print('RSS linki bulunamadı');
        return;
      }

      // RSS feed'i çek ve parse et
      final response = await _dio.get(rssLink);

      if (response.statusCode == 200) {
        final xmlData = response.data.toString();
        localNewsList.value = _parseRssFeed(xmlData);
      }
    } catch (e) {
      print('Yerel haber çekme hatası: $e');
    } finally {
      isNewsLoading.value = false;
    }
  }

  /// Şehir seç
  void selectCity(Map<String, dynamic> city) {
    selectedCity.value = city;
    fetchLocalNews();
  }

  /// RSS XML'i parse et
  List<NewsModel> _parseRssFeed(String xmlData) {
    final List<NewsModel> news = [];

    try {
      // Regex handles <item> tags with attributes (e.g. <item rdf:about="...">)
      final itemRegex = RegExp(r'<item[^>]*>(.*?)</item>', dotAll: true);
      final items = itemRegex.allMatches(xmlData);

      for (final item in items) {
        final itemContent = item.group(1) ?? '';

        // Title
        final titleMatch = RegExp(
          r'<title><!\[CDATA\[(.*?)\]\]></title>|<title>(.*?)</title>',
          dotAll: true,
        ).firstMatch(itemContent);
        final title = titleMatch?.group(1) ?? titleMatch?.group(2) ?? '';

        // Link
        final linkMatch = RegExp(
          r'<link>(.*?)</link>',
          dotAll: true,
        ).firstMatch(itemContent);
        final link = linkMatch?.group(1) ?? '';

        // Description
        final descMatch = RegExp(
          r'<description><!\[CDATA\[(.*?)\]\]></description>|<description>(.*?)</description>',
          dotAll: true,
        ).firstMatch(itemContent);
        final description = descMatch?.group(1) ?? descMatch?.group(2) ?? '';

        // PubDate
        final pubDateMatch = RegExp(
          r'<pubDate>(.*?)</pubDate>',
          dotAll: true,
        ).firstMatch(itemContent);
        final pubDate = pubDateMatch?.group(1) ?? '';

        // Image extraction
        String imageUrl = '';

        // 1. Try media:content or media:thumbnail
        final mediaMatch = RegExp(
          r'<(?:media:)?(?:content|thumbnail)[^>]*url=["\u0027]([^"\u0027]+)["\u0027]',
          caseSensitive: false,
        ).firstMatch(itemContent);
        if (mediaMatch != null) {
          imageUrl = mediaMatch.group(1) ?? '';
        }

        // 2. If no image, try enclosure with image type
        if (imageUrl.isEmpty) {
          final enclosureMatch = RegExp(
            r'<enclosure[^>]*url=["\u0027]([^"\u0027]+)["\u0027][^>]*type=["\u0027]image/',
            caseSensitive: false,
          ).firstMatch(itemContent);
          if (enclosureMatch != null) {
            imageUrl = enclosureMatch.group(1) ?? '';
          }
        }

        // 3. Fallback: Any url attribute ending with image extension
        if (imageUrl.isEmpty) {
          final urlMatch = RegExp(
            r'url=["\u0027]([^"\u0027]+\.(?:jpg|jpeg|png|gif|webp))["\u0027]',
            caseSensitive: false,
          ).firstMatch(itemContent);
          if (urlMatch != null) {
            imageUrl = urlMatch.group(1) ?? '';
          }
        }

        // 4. Try img tag in description (if description exists)
        if (imageUrl.isEmpty && description.isNotEmpty) {
          final imgMatch = RegExp(
            r'<img[^>]+src=["\u0027]([^"\u0027]+)["\u0027]',
            caseSensitive: false,
          ).firstMatch(description);
          if (imgMatch != null) {
            imageUrl = imgMatch.group(1) ?? '';
          }
        }

        if (title.isNotEmpty) {
          news.add(
            NewsModel(
              id: (news.length + 1).toString(),
              title: _cleanHtml(title),
              description: _cleanHtml(description),
              image: imageUrl,
              date: _formatDate(pubDate),
              categoryName: selectedCity.value?['name'] ?? 'Yerel',
              sourceUrl: link,
            ),
          );
        }
      }
    } catch (e) {
      print('RSS parse hatası: $e');
    }

    return news;
  }

  /// HTML taglarını temizle
  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  /// Tarih formatla
  String _formatDate(String pubDate) {
    try {
      // "Mon, 13 Jan 2026 01:30:00 +0300" formatından "13 Ocak 2026" formatına
      if (pubDate.isEmpty) return '';

      final parts = pubDate.split(' ');
      if (parts.length >= 4) {
        final day = parts[1];
        final month = _getMonthName(parts[2]);
        final year = parts[3];
        return '$day $month $year';
      }
      return pubDate;
    } catch (e) {
      return pubDate;
    }
  }

  String _getMonthName(String month) {
    const months = {
      'Jan': 'Ocak',
      'Feb': 'Şubat',
      'Mar': 'Mart',
      'Apr': 'Nisan',
      'May': 'Mayıs',
      'Jun': 'Haziran',
      'Jul': 'Temmuz',
      'Aug': 'Ağustos',
      'Sep': 'Eylül',
      'Oct': 'Ekim',
      'Nov': 'Kasım',
      'Dec': 'Aralık',
    };
    return months[month] ?? month;
  }
}
