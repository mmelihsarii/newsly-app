import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/city_data.dart';

class InterestController extends GetxController {
  final GetStorage _storage = GetStorage();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Storage keys
  static const String _citiesKey = 'followed_cities';
  static const String _categoriesKey = 'followed_categories';

  // Takip edilen şehirler ve kategoriler
  RxList<String> followedCities = <String>[].obs;
  RxList<String> followedCategories = <String>[].obs;

  // Kategori listesi - Backend veritabanından güncellendi
  final List<Map<String, dynamic>> categories = [
    {
      'id': 1,
      'name': 'Yerel Haberler',
      'image':
          'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=400',
    },
    {
      'id': 2,
      'name': 'Son Dakika',
      'image':
          'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=400',
    },
    {
      'id': 3,
      'name': 'Gündem',
      'image':
          'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400',
    },
    {
      'id': 4,
      'name': 'Spor',
      'image':
          'https://images.unsplash.com/photo-1461896836934- voices-of-football?w=400',
    },
    {
      'id': 5,
      'name': 'Ekonomi & Finans',
      'image':
          'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=400',
    },
    {
      'id': 6,
      'name': 'Bilim & Teknoloji',
      'image':
          'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400',
    },
    {
      'id': 9,
      'name': 'Haber Ajansları',
      'image':
          'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=400',
    },
    {
      'id': 10,
      'name': 'Yabancı Kaynaklar',
      'image':
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  // Türkçe karakterleri normalize et
  String _normalizeTopicName(String name) {
    const Map<String, String> turkishChars = {
      'ı': 'i',
      'İ': 'i',
      'ğ': 'g',
      'Ğ': 'g',
      'ü': 'u',
      'Ü': 'u',
      'ş': 's',
      'Ş': 's',
      'ö': 'o',
      'Ö': 'o',
      'ç': 'c',
      'Ç': 'c',
      ' ': '_',
    };

    String normalized = name.toLowerCase();
    turkishChars.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    // Sadece alfanumerik ve alt çizgi karakterleri kalsın
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    return normalized;
  }

  // Storage'dan verileri yükle
  void _loadFromStorage() {
    // Şehirleri yükle
    final List<dynamic>? storedCities = _storage.read<List<dynamic>>(
      _citiesKey,
    );
    if (storedCities != null) {
      followedCities.value = storedCities.cast<String>();
    }

    // Kategorileri yükle
    final List<dynamic>? storedCategories = _storage.read<List<dynamic>>(
      _categoriesKey,
    );
    if (storedCategories != null) {
      followedCategories.value = storedCategories.cast<String>();
    }
  }

  // Şehirleri kaydet
  void _saveCities() {
    _storage.write(_citiesKey, followedCities.toList());
  }

  // Kategorileri kaydet
  void _saveCategories() {
    _storage.write(_categoriesKey, followedCategories.toList());
  }

  // Şehir toggle
  void toggleCity(String cityName) {
    final String topicName = 'city_${_normalizeTopicName(cityName)}';

    if (followedCities.contains(cityName)) {
      // Takipten çık
      followedCities.remove(cityName);
      _messaging.unsubscribeFromTopic(topicName);
      print('❌ $topicName konusundan ayrıldı');
    } else {
      // Takibe al
      followedCities.add(cityName);
      _messaging.subscribeToTopic(topicName);
      print('✅ $topicName konusuna abone olundu');
    }
    _saveCities();
  }

  // Kategori toggle - ID BAZLI TOPIC
  void toggleCategory(String categoryName) {
    // Kategori ID'sini bul
    final category = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => {'id': 0, 'name': categoryName},
    );
    final int categoryId = category['id'] ?? 0;
    
    // Topic adı: category_{id} formatında (backend ile uyumlu)
    final String topicName = 'category_$categoryId';

    if (followedCategories.contains(categoryName)) {
      // Takipten çık
      followedCategories.remove(categoryName);
      _messaging.unsubscribeFromTopic(topicName);
      print('❌ $topicName konusundan ayrıldı (ID: $categoryId)');
    } else {
      // Takibe al
      followedCategories.add(categoryName);
      _messaging.subscribeToTopic(topicName);
      print('✅ $topicName konusuna abone olundu (ID: $categoryId)');
    }
    _saveCategories();
    
    // Debug: Kayıtlı kategorileri göster
    print('📋 Güncel takip edilen kategoriler: ${followedCategories.toList()}');
    print('💾 Storage\'a kaydedildi: $_categoriesKey');
  }

  // Şehir takip kontrolü
  bool isCityFollowing(String cityName) {
    return followedCities.contains(cityName);
  }

  // Kategori takip kontrolü
  bool isCategoryFollowing(String categoryName) {
    return followedCategories.contains(categoryName);
  }

  // Tüm şehirleri getir
  List<Map<String, dynamic>> get allCities => CityData.cities;

  // Takip edilen toplam sayı
  int get totalFollowedCount =>
      followedCities.length + followedCategories.length;
}
