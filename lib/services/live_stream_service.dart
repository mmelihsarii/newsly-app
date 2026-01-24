import 'dart:async';
import 'package:get/get.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

/// Canlı Yayın Modeli
class LiveStream {
  final String id;
  final String title;
  final String url;
  final String type;
  final String? thumbnailUrl;
  final String? logoUrl;
  final String? sourceName;
  final String? description;
  final bool isActive;
  final int order;

  LiveStream({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.logoUrl,
    this.sourceName,
    this.description,
    this.isActive = true,
    this.order = 0,
  });

  /// Admin Panel API'den gelen JSON'ı modele çevir
  factory LiveStream.fromJson(Map<String, dynamic> json) {
    // URL'i al
    String streamUrl = json['url'] ?? json['link'] ?? '';
    
    // Thumbnail: Önce image, sonra thumbnail, sonra YouTube'dan otomatik
    String? thumbnail = json['image'] ?? json['thumbnail'];
    if (thumbnail == null || thumbnail.isEmpty) {
      // YouTube ise otomatik thumbnail oluştur
      final videoId = _extractYoutubeId(streamUrl);
      if (videoId != null) {
        thumbnail = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }
    
    return LiveStream(
      id: json['id'].toString(),
      title: json['title'] ?? json['name'] ?? '',
      url: streamUrl,
      type: json['type'] ?? 'youtube',
      thumbnailUrl: thumbnail,
      logoUrl: json['logo'],
      sourceName: json['source_name'] ?? json['channel_name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] == true || 
                json['status'] == 1 || 
                json['status'] == '1' ||
                json['status'] == true,
      order: json['order'] ?? 0,
    );
  }

  /// YouTube video ID'sini URL'den çıkar
  static String? _extractYoutubeId(String url) {
    if (!url.contains('youtube') && !url.contains('youtu.be')) return null;

    try {
      final uri = Uri.parse(url);
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
      if (url.contains('youtu.be/')) {
        return url.split('youtu.be/').last.split('?').first;
      }
      // /live/ formatı için
      if (url.contains('/live/')) {
        return url.split('/live/').last.split('?').first;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// YouTube video ID'si (instance method)
  String? get youtubeVideoId => _extractYoutubeId(url);

  /// YouTube mu kontrol et
  bool get isYoutube => url.contains('youtube') || url.contains('youtu.be');
}

/// Canlı Yayın Servisi - Admin Panel API'ye Bağlı
class LiveStreamService extends GetxController {
  static LiveStreamService get to => Get.find<LiveStreamService>();

  final ApiService _apiService = ApiService();
  
  final RxList<LiveStream> streams = <LiveStream>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  Timer? _refreshTimer;

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

  /// Her 5 dakikada bir otomatik yenile
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchStreams();
    });
  }

  /// Admin Panel'den canlı yayınları çek
  Future<void> fetchStreams() async {
    try {
      isLoading.value = true;
      error.value = '';

      print('📺 Admin Panel\'den canlı yayınlar çekiliyor...');

      final response = await _apiService.getData(ApiConstants.getLiveStreams);

      if (response != null) {
        List<LiveStream> fetchedStreams = [];

        // Response formatını kontrol et
        if (response is Map && response['success'] == true && response['data'] != null) {
          // { success: true, data: [...] } formatı
          final List<dynamic> data = response['data'];
          fetchedStreams = data
              .map((json) => LiveStream.fromJson(json as Map<String, dynamic>))
              .where((stream) => stream.url.isNotEmpty && stream.isActive)
              .toList();
        } else if (response is List) {
          // Direkt liste formatı
          fetchedStreams = response
              .map((json) => LiveStream.fromJson(json as Map<String, dynamic>))
              .where((stream) => stream.url.isNotEmpty && stream.isActive)
              .toList();
        }

        // Sırala (order'a göre)
        fetchedStreams.sort((a, b) => a.order.compareTo(b.order));

        streams.value = fetchedStreams;
        print('✅ Admin Panel\'den ${streams.length} canlı yayın yüklendi.');

        // Eğer hiç yayın yoksa fallback kullan
        if (streams.isEmpty) {
          print('⚠️ Admin Panel\'de aktif yayın yok, fallback kullanılıyor...');
          _loadFallbackStreams();
        }
      } else {
        print('⚠️ API yanıt vermedi, fallback kullanılıyor...');
        _loadFallbackStreams();
      }
    } catch (e) {
      print('❌ Canlı yayın çekme hatası: $e');
      error.value = 'Canlı yayınlar yüklenemedi';
      _loadFallbackStreams();
    } finally {
      isLoading.value = false;
    }
  }

  /// API çalışmadığında kullanılacak statik yayın listesi
  void _loadFallbackStreams() {
    streams.value = [
      LiveStream(
        id: 'fallback_1',
        title: 'Tele 2 Haber',
        url: 'https://www.youtube.com/watch?v=zGFeonz04as',
        type: 'youtube',
        sourceName: 'Tele 2 Haber',
        thumbnailUrl: 'https://img.youtube.com/vi/zGFeonz04as/hqdefault.jpg',
        order: 1,
      ),
      LiveStream(
        id: 'fallback_2',
        title: 'Halk TV',
        url: 'https://www.youtube.com/watch?v=D39n2HRgB4s',
        type: 'youtube',
        sourceName: 'Halk TV',
        thumbnailUrl: 'https://img.youtube.com/vi/D39n2HRgB4s/hqdefault.jpg',
        order: 2,
      ),
      LiveStream(
        id: 'fallback_3',
        title: 'CNN Türk Canlı',
        url: 'https://www.youtube.com/watch?v=6N8_r2uwLEc',
        type: 'youtube',
        sourceName: 'CNN Türk',
        thumbnailUrl: 'https://img.youtube.com/vi/6N8_r2uwLEc/hqdefault.jpg',
        order: 3,
      ),
      LiveStream(
        id: 'fallback_4',
        title: 'Sözcü TV',
        url: 'https://www.youtube.com/watch?v=ztmY_cCtUl0',
        type: 'youtube',
        sourceName: 'Sözcü TV',
        thumbnailUrl: 'https://img.youtube.com/vi/ztmY_cCtUl0/hqdefault.jpg',
        order: 4,
      ),
    ];
    print('✅ ${streams.length} fallback canlı yayın yüklendi.');
  }

  /// Manuel yenileme
  @override
  Future<void> refresh() async {
    await fetchStreams();
  }
}
