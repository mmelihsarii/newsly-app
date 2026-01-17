import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Canlı Yayın Modeli
class LiveStream {
  final String id;
  final String title;
  final String url;
  final String type;
  final String? logoUrl;
  final String? sourceName;
  final String language;
  final bool isActive;

  LiveStream({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    this.logoUrl,
    this.sourceName,
    this.language = 'Turkish',
    this.isActive = true,
  });

  // API'den gelen JSON verisini modele çevirir
  factory LiveStream.fromJson(Map<String, dynamic> json) {
    return LiveStream(
      id: json['id'].toString(),
      title: json['title'] ?? json['name'] ?? '',
      url: json['url'] ?? json['link'] ?? '',
      type: json['type'] ?? 'url youtube',
      // API'den gelen görsel bazen tam URL bazen path olabilir, kontrol et
      logoUrl: json['image'] != null
          ? (json['image'].toString().startsWith('http')
                ? json['image']
                : 'https://newsly.com.tr/storage/${json['image']}')
          : null,
      sourceName: json['source_name'] ?? '',
      language: json['language_id'].toString() == '2' ? 'Turkish' : 'English',
      isActive:
          json['status'] == 1 ||
          json['status'] == '1' ||
          json['status'] == true,
    );
  }

  /// YouTube video ID'sini URL'den çıkar
  String? get youtubeVideoId {
    if (!url.contains('youtube') && !url.contains('youtu.be')) return null;

    try {
      final uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
      if (url.contains('youtu.be/')) {
        return url.split('youtu.be/').last.split('?').first;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// YouTube thumbnail URL'i
  String? get thumbnailUrl {
    final videoId = youtubeVideoId;
    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return logoUrl;
  }
}

/// Canlı Yayın Servisi (API Versiyonu)
class LiveStreamService extends GetxController {
  static LiveStreamService get to => Get.find<LiveStreamService>();

  final RxList<LiveStream> streams = <LiveStream>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  Timer? _refreshTimer;

  // API Adresi - Kendi domainin
  final String _baseUrl = 'https://newsly.com.tr/api';

  @override
  void onInit() {
    super.onInit();
    fetchStreams();
    _startAutoRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchStreams();
    });
  }

  /// Web sitesinden canlı yayınları çek
  // LiveStreamService.dart içinde fetchStreams fonksiyonunu bu şekilde güncelle:

  Future<void> fetchStreams() async {
    try {
      isLoading.value = true;
      error.value = '';

      print('📺 Canlı yayınlar çekiliyor...');

      final response = await http.post(
        Uri.parse('https://newsly.com.tr/api/get_live_streaming'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'language_id': '2'},
      );

      print('📡 Sunucu Yanıtı: ${response.statusCode}');

      // Sunucu JSON döndürüyor mu kontrol et (HTML ile başlamıyorsa)
      if (response.statusCode == 200 &&
          !response.body.trim().startsWith('<!DOCTYPE') &&
          !response.body.trim().startsWith('<html')) {
        print('📦 Gelen JSON: ${response.body}');

        final List<dynamic> data = json.decode(response.body);

        streams.value = data
            .map((json) => LiveStream.fromJson(json))
            .where((stream) => stream.url.isNotEmpty)
            .toList();

        print('✅ ${streams.length} canlı yayın API\'den yüklendi.');
      } else {
        print('⚠️ API HTML döndürdü, fallback veriler kullanılıyor...');
        _loadFallbackStreams();
      }
    } catch (e) {
      print('❌ Bağlantı hatası: $e');
      print('⚠️ Fallback veriler kullanılıyor...');
      _loadFallbackStreams();
    } finally {
      isLoading.value = false;
    }
  }

  /// API çalışmadığında kullanılacak statik yayın listesi
  void _loadFallbackStreams() {
    streams.value = [
      LiveStream(
        id: '1',
        title: 'Tele 2 Haber',
        url: 'https://www.youtube.com/watch?v=zGFeonz04as',
        type: 'url youtube',
        sourceName: 'Tele 2 Haber',
        logoUrl: 'https://img.youtube.com/vi/zGFeonz04as/hqdefault.jpg',
      ),
      LiveStream(
        id: '2',
        title: 'Halk Tv',
        url: '	https://www.youtube.com/watch?v=D39n2HRgB4s',
        type: 'url youtube',
        sourceName: 'Halk Tv',
        logoUrl: 'https://img.youtube.com/vi/D39n2HRgB4s/hqdefault.jpg',
      ),
      LiveStream(
        id: '3',
        title: 'CNN Türk Canlı',
        url: '	https://www.youtube.com/watch?v=6N8_r2uwLEc',
        type: 'url youtube',
        sourceName: 'CNN Türk',
        logoUrl: 'https://img.youtube.com/vi/6N8_r2uwLEc/hqdefault.jpg',
      ),
      LiveStream(
        id: '4',
        title: 'Sözcü TV',
        url: 'https://www.youtube.com/watch?v=ztmY_cCtUl0',
        type: 'url youtube',
        sourceName: 'Sözcü TV',
        logoUrl: 'https://img.youtube.com/vi/ztmY_cCtUl0/hqdefault.jpg',
      ),
    ];
    print('✅ ${streams.length} fallback canlı yayın yüklendi.');
  }

  @override
  Future<void> refresh() async {
    await fetchStreams();
  }
}
