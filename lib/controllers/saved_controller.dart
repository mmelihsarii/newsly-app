import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/news_model.dart';

class SavedController extends GetxController {
  final GetStorage _storage = GetStorage();
  static const String _storageKey = 'saved_news';

  // Kaydedilen haberler listesi
  RxList<NewsModel> savedNewsList = <NewsModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedNews();
  }

  // Storage'dan kaydedilen haberleri yükle
  void _loadSavedNews() {
    final String? storedData = _storage.read<String>(_storageKey);
    if (storedData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(storedData);
        savedNewsList.value = jsonList
            .map((json) => NewsModel.fromStorageJson(json))
            .toList();
      } catch (e) {
        print('Kaydedilen haberler yüklenirken hata: $e');
      }
    }
  }

  // Değişiklikleri storage'a kaydet
  void _saveToStorage() {
    try {
      final List<Map<String, dynamic>> jsonList = savedNewsList
          .map((news) => news.toStorageJson())
          .toList();
      _storage.write(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('Haberler kaydedilirken hata: $e');
    }
  }

  // Haber kaydet veya kaldır
  void toggleSave(NewsModel news) {
    final existingIndex = savedNewsList.indexWhere(
      (n) => n.title == news.title || (n.id != null && n.id == news.id),
    );

    if (existingIndex != -1) {
      savedNewsList.removeAt(existingIndex);
    } else {
      savedNewsList.insert(0, news); // En yeni en üstte
    }
    _saveToStorage();
  }

  // Haberin kaydedilip kaydedilmediğini kontrol et
  bool isSaved(NewsModel news) {
    return savedNewsList.any(
      (n) => n.title == news.title || (n.id != null && n.id == news.id),
    );
  }

  // Haberi kaldır
  void removeNews(NewsModel news) {
    savedNewsList.removeWhere(
      (n) => n.title == news.title || (n.id != null && n.id == news.id),
    );
    _saveToStorage();
  }

  // Tüm kaydedilenleri temizle
  void clearAll() {
    savedNewsList.clear();
    _saveToStorage();
  }
}
