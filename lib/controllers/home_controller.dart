import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/news_model.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  // API Servisi
  final ApiService _apiService = ApiService();

  // Reaktif değişkenler
  var isLoading = false.obs;
  var isLoadingMore = false.obs; // Infinite scroll için
  var isCarouselLoading = false.obs;
  var newsList = <NewsModel>[].obs;
  var carouselNewsList = <NewsModel>[].obs;

  // Pagination değişkenleri
  var currentOffset = 0.obs;
  var hasMoreData = true.obs;
  static const int _pageLimit = 20; // Her seferde 20 haber

  // Carousel değişkenleri
  final PageController carouselController = PageController();
  var currentCarouselIndex = 0.obs;

  // Kategori değişkenleri
  var selectedCategoryIndex = 0.obs;

  // Kategoriler ve ID'leri (Backend veritabanından)
  final List<Map<String, dynamic>> categories = const [
    {'name': 'Son Dakika', 'id': 2},
    {'name': 'Gündem', 'id': 3},
    {'name': 'Spor', 'id': 4},
    {'name': 'Ekonomi', 'id': 5},
    {'name': 'Bilim & Teknoloji', 'id': 6},
    {'name': 'Haber Ajansları', 'id': 9},
    {'name': 'Yabancı Kaynaklar', 'id': 10},
  ];

  // Seçili kategorinin ID'sini getir
  int get selectedCategoryId => categories[selectedCategoryIndex.value]['id'];

  // Seçili kategorinin ismini getir
  String get selectedCategoryName =>
      categories[selectedCategoryIndex.value]['name'];

  void changeCategory(int index) {
    selectedCategoryIndex.value = index;
    // Kategori değişince pagination sıfırla
    currentOffset.value = 0;
    hasMoreData.value = true;
    newsList.clear();
    fetchNewsByCategory(categories[index]['id']);
  }

  // Scroll Controller
  final ScrollController scrollController = ScrollController();

  @override
  void onClose() {
    scrollController.dispose();
    carouselController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();

    // Scroll listener ekle
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        // Listenin sonuna yaklaşıldı
        if (selectedCategoryIndex.value == 0) {
          loadMoreNews();
        } else {
          loadMoreNewsByCategory();
        }
      }
    });

    fetchNews();
  }

  // Genel haber çekme (ana sayfa için - ilk yükleme)
  void fetchNews() async {
    try {
      isLoading(true);
      isCarouselLoading(true);
      currentOffset.value = 0;
      hasMoreData.value = true;

      print("🚀 Haberler İsteniyor... (offset: 0)");

      var response = await _apiService.postData("get_news", {
        'language_id': '2',
        'access_key': '6808',
        'get_user_news': '0',
        'limit': _pageLimit.toString(),
        'offset': '0',
        'order': 'DESC',
      });

      print("📡 API Cevabı alındı");

      if (response != null && response['error'] == false) {
        var list = response['data'] as List;
        var allNews = list.map((item) => NewsModel.fromJson(item)).toList();

        // Carousel için ilk 5 haber
        carouselNewsList.value = allNews.take(5).toList();
        // Haber listesi
        newsList.value = allNews;
        currentOffset.value = allNews.length;

        // Eğer gelen veri sayfa limitinden azsa, daha fazla veri yok
        if (allNews.length < _pageLimit) {
          hasMoreData.value = false;
        }

        print('📰 ${allNews.length} haber yüklendi');
      } else {
        print("API Boş veya Hatalı: $response");
      }
    } catch (e) {
      print("Haber Çekme Hatası: $e");
    } finally {
      isLoading(false);
      isCarouselLoading(false);
    }
  }

  // Daha fazla haber yükle (infinite scroll)
  Future<void> loadMoreNews() async {
    // Zaten yükleme yapılıyorsa veya daha fazla veri yoksa çık
    if (isLoadingMore.value || !hasMoreData.value) return;

    try {
      isLoadingMore(true);

      print(
        "🔄 Daha fazla haber yükleniyor... (offset: ${currentOffset.value})",
      );

      var response = await _apiService.postData("get_news", {
        'language_id': '2',
        'access_key': '6808',
        'get_user_news': '0',
        'limit': _pageLimit.toString(),
        'offset': currentOffset.value.toString(),
        'order': 'DESC',
      });

      if (response != null && response['error'] == false) {
        var list = response['data'] as List;
        var moreNews = list.map((item) => NewsModel.fromJson(item)).toList();

        if (moreNews.isNotEmpty) {
          newsList.addAll(moreNews);
          currentOffset.value += moreNews.length;
          print(
            '📰 +${moreNews.length} haber eklendi (toplam: ${newsList.length})',
          );
        }

        // Eğer gelen veri sayfa limitinden azsa, daha fazla veri yok
        if (moreNews.length < _pageLimit) {
          hasMoreData.value = false;
          print('⏹️ Tüm haberler yüklendi');
        }
      }
    } catch (e) {
      print("Daha Fazla Haber Yükleme Hatası: $e");
    } finally {
      isLoadingMore(false);
    }
  }

  // Kategoriye göre haber çekme (ilk yükleme)
  void fetchNewsByCategory(int categoryId) async {
    try {
      isLoading(true);
      currentOffset.value = 0;
      hasMoreData.value = true;

      print("🚀 Kategori Haberleri İsteniyor... (ID: $categoryId, offset: 0)");

      var response = await _apiService.postData("get_news", {
        'language_id': '2',
        'access_key': '6808',
        'category_id': categoryId.toString(),
        'limit': _pageLimit.toString(),
        'offset': '0',
        'order': 'DESC',
      });

      print("📡 Kategori API Cevabı alındı");

      if (response != null && response['error'] == false) {
        var list = response['data'] as List;
        var allNews = list.map((item) => NewsModel.fromJson(item)).toList();

        newsList.value = allNews;
        currentOffset.value = allNews.length;

        if (allNews.length < _pageLimit) {
          hasMoreData.value = false;
        }

        print('📰 ${allNews.length} kategori haberi yüklendi');
      } else {
        print("Kategori API Boş veya Hatalı: $response");
        newsList.clear();
      }
    } catch (e) {
      print("Kategori Haber Çekme Hatası: $e");
    } finally {
      isLoading(false);
    }
  }

  // Kategoriye göre daha fazla haber yükle
  Future<void> loadMoreNewsByCategory() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    try {
      isLoadingMore(true);
      final categoryId = selectedCategoryId;

      print(
        "🔄 Daha fazla kategori haberi... (ID: $categoryId, offset: ${currentOffset.value})",
      );

      var response = await _apiService.postData("get_news", {
        'language_id': '2',
        'access_key': '6808',
        'category_id': categoryId.toString(),
        'limit': _pageLimit.toString(),
        'offset': currentOffset.value.toString(),
        'order': 'DESC',
      });

      if (response != null && response['error'] == false) {
        var list = response['data'] as List;
        var moreNews = list.map((item) => NewsModel.fromJson(item)).toList();

        if (moreNews.isNotEmpty) {
          newsList.addAll(moreNews);
          currentOffset.value += moreNews.length;
          print('📰 +${moreNews.length} kategori haberi eklendi');
        }

        if (moreNews.length < _pageLimit) {
          hasMoreData.value = false;
        }
      }
    } catch (e) {
      print("Daha Fazla Kategori Haberi Hatası: $e");
    } finally {
      isLoadingMore(false);
    }
  }

  // Refresh - Yenile
  Future<void> refreshNews() async {
    if (selectedCategoryIndex.value == 0) {
      fetchNews();
    } else {
      fetchNewsByCategory(selectedCategoryId);
    }
  }
}
