import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/news_model.dart';
import '../services/api_service.dart';

class HomeController extends GetxController {
  // API Servisi
  final ApiService _apiService = ApiService();

  // Reaktif değişkenler
  var isLoading = false.obs;
  var newsList = <NewsModel>[].obs;

  // Carousel değişkenleri
  final PageController carouselController = PageController();
  var currentCarouselIndex = 0.obs;

  // Kategori değişkenleri
  var selectedCategoryIndex = 0.obs;
  final List<String> categories = const [
    'Latest',
    'Business',
    'Sports',
    'Politics',
    'Health',
    'Tech',
  ];

  void changeCategory(int index) {
    selectedCategoryIndex.value = index;
  }

  @override
  void onClose() {
    carouselController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    fetchNews(); // Sayfa açılınca haberleri çek
  }

  void fetchNews() async {
    try {
      isLoading(true);
      print("🚀 Haberler İsteniyor...");

      var response = await _apiService.postData("get_news", {
        'language_id': '2',
        'access_key': '6808',
        'get_user_news': '0',
        'limit': '20',
        'offset': '0',
        'order': 'DESC',
      });

      print("📡 API Cevabı: $response");

      if (response != null && response['error'] == false) {
        var list = response['data'] as List;
        newsList.value = list.map((item) => NewsModel.fromJson(item)).toList();
      } else {
        print("API Boş veya Hatalı: $response");
      }
    } catch (e) {
      print("Haber Çekme Hatası: $e");
    } finally {
      isLoading(false);
    }
  }
}
