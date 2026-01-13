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

  // Kategori listesi (category_selection_view'dan alındı)
  final List<Map<String, String>> categories = [
    {
      'name': 'Bilim',
      'image':
          'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400',
    },
    {
      'name': 'Teknoloji',
      'image':
          'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400',
    },
    {
      'name': 'Spor',
      'image':
          'https://images.unsplash.com/photo-1461896836934-voices-of-football?w=400',
    },
    {
      'name': 'Gündem',
      'image':
          'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=400',
    },
    {
      'name': 'Ekonomi',
      'image':
          'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=400',
    },
    {
      'name': 'Sağlık',
      'image':
          'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=400',
    },
    {
      'name': 'Kültür & Sanat',
      'image':
          'https://images.unsplash.com/photo-1541367777708-7905fe3296c0?w=400',
    },
    {
      'name': 'Eğitim',
      'image':
          'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=400',
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

  // Kategori toggle
  void toggleCategory(String categoryName) {
    final String topicName = 'category_${_normalizeTopicName(categoryName)}';

    if (followedCategories.contains(categoryName)) {
      // Takipten çık
      followedCategories.remove(categoryName);
      _messaging.unsubscribeFromTopic(topicName);
      print('❌ $topicName konusundan ayrıldı');
    } else {
      // Takibe al
      followedCategories.add(categoryName);
      _messaging.subscribeToTopic(topicName);
      print('✅ $topicName konusuna abone olundu');
    }
    _saveCategories();
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
