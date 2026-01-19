import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

/// Bildirim Bottom Sheet'i gösteren fonksiyon
void showNotificationsBottomSheet(BuildContext context) {
  final notificationService = NotificationService();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2F47) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bildirimler',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      Obx(() {
                        if (notificationService.notifications.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return TextButton(
                          onPressed: () {
                            notificationService.markAllAsRead();
                          },
                          child: const Text(
                            'Tümünü Okundu İşaretle',
                            style: TextStyle(
                              color: Color(0xFFF4220B),
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
            // Notification List
            Expanded(
              child: Obx(() {
                if (notificationService.notifications.isEmpty) {
                  return _buildEmptyState(isDark);
                }
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notificationService.notifications.length,
                  itemBuilder: (context, index) {
                    final notification =
                        notificationService.notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      isDark: isDark,
                      onTap: () {
                        notificationService.markAsRead(notification.id);
                        // Eğer data'da newsId varsa detaya git
                        if (notification.data?.containsKey('newsId') ?? false) {
                          Navigator.pop(context);
                          // Navigation işlemi NotificationService içinde yapılabilir
                        }
                      },
                      onDismiss: () {
                        notificationService.removeNotification(notification.id);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildEmptyState(bool isDark) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF132440) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Henüz bildirim yok',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Yeni bildirimler burada görünecek',
          style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey.shade600),
        ),
      ],
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final bool isDark;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? (isDark ? const Color(0xFF1A2F47) : Colors.white)
                : (isDark ? const Color(0xFF132440) : const Color(0xFFFFF8F7)),
            border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade100)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? (isDark ? const Color(0xFF132440) : Colors.grey.shade100)
                      : const Color(0xFFF4220B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications,
                  color: notification.isRead
                      ? (isDark ? Colors.white38 : Colors.grey.shade500)
                      : const Color(0xFFF4220B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.receivedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4220B),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Şimdi';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return DateFormat('dd MMM', 'tr_TR').format(time);
    }
  }
}
