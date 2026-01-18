import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/news_model.dart';
import '../services/api_service.dart';
import '../views/news_detail_page.dart';

/// Bildirim modeli
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic>? data;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.data,
    this.isRead = false,
  });
}

class NotificationService extends GetxController {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _apiService = ApiService();

  // Global Navigator Key
  late GlobalKey<NavigatorState> navigatorKey;

  // Bildirimler listesi (artık boş kalacak - otomatik bildirim yok)
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;

  // Okunmamış bildirim sayısı
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Servisi başlat - BİLDİRİMLER DEVRE DIŞI
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    print('🔕 NotificationService: Otomatik bildirimler devre dışı.');
    // FCM başlatma, izin isteme, topic aboneliği vs. KALDIRILDI
  }

  /// Bildirimi okundu olarak işaretle
  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      notifications.refresh();
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  void markAllAsRead() {
    for (var notification in notifications) {
      notification.isRead = true;
    }
    notifications.refresh();
  }

  /// Bildirimi sil
  void removeNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
  }

  /// Tüm bildirimleri temizle
  void clearAll() {
    notifications.clear();
  }
}
