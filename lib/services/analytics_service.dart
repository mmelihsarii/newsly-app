import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics Servisi
/// Kullanıcı davranışlarını ve uygulama kullanımını takip eder
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  /// Kullanıcı ID'sini ayarla (giriş yapınca)
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserId error: $e');
    }
  }

  /// Kullanıcı özelliği ayarla
  Future<void> setUserProperty({required String name, required String? value}) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics setUserProperty error: $e');
    }
  }

  /// Ekran görüntüleme
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('Analytics logScreenView error: $e');
    }
  }

  /// Haber okuma
  Future<void> logNewsRead({
    required String newsId,
    required String newsTitle,
    required String category,
    required String source,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'news_read',
        parameters: {
          'news_id': newsId,
          'news_title': newsTitle.length > 100 ? newsTitle.substring(0, 100) : newsTitle,
          'category': category,
          'source': source,
        },
      );
    } catch (e) {
      debugPrint('Analytics logNewsRead error: $e');
    }
  }

  /// Haber paylaşma
  Future<void> logNewsShare({
    required String newsId,
    required String newsTitle,
    required String method,
  }) async {
    try {
      await _analytics.logShare(
        contentType: 'news',
        itemId: newsId,
        method: method,
      );
    } catch (e) {
      debugPrint('Analytics logNewsShare error: $e');
    }
  }

  /// Haber kaydetme
  Future<void> logNewsSave({required String newsId, required String newsTitle}) async {
    try {
      await _analytics.logEvent(
        name: 'news_save',
        parameters: {
          'news_id': newsId,
          'news_title': newsTitle.length > 100 ? newsTitle.substring(0, 100) : newsTitle,
        },
      );
    } catch (e) {
      debugPrint('Analytics logNewsSave error: $e');
    }
  }

  /// Kategori seçimi
  Future<void> logCategorySelect({required String category}) async {
    try {
      await _analytics.logEvent(
        name: 'category_select',
        parameters: {'category': category},
      );
    } catch (e) {
      debugPrint('Analytics logCategorySelect error: $e');
    }
  }

  /// Kaynak seçimi
  Future<void> logSourceSelect({required String source, required bool selected}) async {
    try {
      await _analytics.logEvent(
        name: 'source_select',
        parameters: {
          'source': source,
          'selected': selected ? 'true' : 'false',
        },
      );
    } catch (e) {
      debugPrint('Analytics logSourceSelect error: $e');
    }
  }

  /// Arama yapma
  Future<void> logSearch({required String searchTerm}) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
    } catch (e) {
      debugPrint('Analytics logSearch error: $e');
    }
  }

  /// Giriş yapma
  Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics logLogin error: $e');
    }
  }

  /// Kayıt olma
  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics logSignUp error: $e');
    }
  }

  /// Canlı yayın izleme
  Future<void> logLiveStreamWatch({required String channelName}) async {
    try {
      await _analytics.logEvent(
        name: 'live_stream_watch',
        parameters: {'channel': channelName},
      );
    } catch (e) {
      debugPrint('Analytics logLiveStreamWatch error: $e');
    }
  }

  /// Şehir seçimi (yerel haberler)
  Future<void> logCitySelect({required String city}) async {
    try {
      await _analytics.logEvent(
        name: 'city_select',
        parameters: {'city': city},
      );
    } catch (e) {
      debugPrint('Analytics logCitySelect error: $e');
    }
  }

  /// Tema değiştirme
  Future<void> logThemeChange({required bool isDark}) async {
    try {
      await _analytics.logEvent(
        name: 'theme_change',
        parameters: {'theme': isDark ? 'dark' : 'light'},
      );
    } catch (e) {
      debugPrint('Analytics logThemeChange error: $e');
    }
  }

  /// Özel event
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logCustomEvent error: $e');
    }
  }
}
