import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/follow_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/home_controller.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../models/source_model.dart';
import '../../utils/colors.dart';
import '../../utils/source_logos.dart';
import '../../widgets/notification_bottom_sheet.dart';
import '../source_profile_view.dart';
import '../live_stream_view.dart';
import '../dashboard_view.dart';
import 'add_source_view.dart';

class FollowView extends StatelessWidget {
  const FollowView({super.key});

  Color _getCategoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('gündem') || c.contains('son dakika')) return const Color(0xFFEF4444);
    if (c.contains('spor')) return const Color(0xFF22C55E);
    if (c.contains('ekonomi') || c.contains('finans')) return const Color(0xFFF59E0B);
    if (c.contains('teknoloji') || c.contains('bilim')) return const Color(0xFF6366F1);
    if (c.contains('yabancı') || c.contains('dünya')) return const Color(0xFF8B5CF6);
    if (c.contains('ajans')) return const Color(0xFF0EA5E9);
    if (c.contains('yerel')) return const Color(0xFF14B8A6);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FollowController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context, isDark),
      body: Obx(() {
        if (controller.isLoading.value && controller.selectedSources.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Kaynaklar yükleniyor...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (controller.selectedSources.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshSources(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: controller.selectedSources.length,
            itemBuilder: (context, index) {
              final source = controller.selectedSources[index];
              return _buildSourceCard(source, isDark);
            },
          ),
        );
      }),
    );
  }

  /// Yeni tasarım: Liste görünümü - Logo + Başlık + Kategori
  Widget _buildSourceCard(SourceModel source, bool isDark) {
    final categoryColor = _getCategoryColor(source.category);
    final logoUrl = SourceLogos.getLogoUrl(source.name);

    return GestureDetector(
      onTap: () => Get.to(() => SourceProfileView(source: source)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2F47) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sol: Kare Logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: categoryColor.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: logoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.contain,
                        memCacheWidth: 100,
                        memCacheHeight: 100,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (_, __) => _buildLogoPlaceholder(source, categoryColor),
                        errorWidget: (_, __, ___) => _buildLogoPlaceholder(source, categoryColor),
                      )
                    : _buildLogoPlaceholder(source, categoryColor),
              ),
            ),
            const SizedBox(width: 14),
            // Sağ: Başlık + Kategori
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      source.category.isNotEmpty ? source.category : 'Genel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sağ ok
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(SourceModel source, Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Text(
          source.name.isNotEmpty ? source.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final authService = Get.find<AuthService>();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rss_feed, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Kaynak Seçin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz haber kaynağı seçmediniz.\nKaynak seçerek takip ettiğiniz\nhaberleri burada görün.',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (authService.isLoggedIn && !authService.isGuest) {
                  Get.to(() => const AddSourceView());
                } else {
                  Get.snackbar(
                    'Üyelik Gerekli',
                    'Kaynak seçimi için lütfen üye girişi yapın.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Kaynak Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDark) {
    final authService = Get.find<AuthService>();
    
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        icon: const Icon(Icons.menu, color: Color(0xFFF4220B), size: 32),
      ),
      title: SizedBox(
        height: 100,
        width: 150,
        child: SvgPicture.asset(
          'assets/logo.svg',
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(Color(0xFFF4220B), BlendMode.srcIn),
        ),
      ),
      centerTitle: false,
      actions: [
        // + Butonu - Kaynak Ekle
        IconButton(
          onPressed: () {
            if (authService.isLoggedIn && !authService.isGuest) {
              Get.to(() => const AddSourceView());
            } else {
              Get.snackbar(
                'Üyelik Gerekli',
                'Kaynak eklemek için lütfen üye girişi yapın.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4220B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Color(0xFFF4220B), size: 22),
          ),
        ),
        IconButton(
          onPressed: () {
            final dashboardController = Get.find<DashboardController>();
            dashboardController.changeTabIndex(0);
            Future.delayed(const Duration(milliseconds: 300), () {
              try {
                final homeController = Get.find<HomeController>();
                homeController.isSearchOpen.value = true;
              } catch (e) {
                print('HomeController bulunamadı: $e');
              }
            });
          },
          icon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black87, size: 28),
        ),
        GestureDetector(
          onTap: () => Get.to(() => const LiveStreamView()),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.videocam, color: Colors.red, size: 26),
          ),
        ),
        const SizedBox(width: 4),
        Stack(
          children: [
            IconButton(
              onPressed: () => showNotificationsBottomSheet(context),
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFFF4220B), size: 28),
            ),
            Obx(() {
              final notificationService = Get.find<NotificationService>();
              if (notificationService.unreadCount == 0) return const SizedBox.shrink();
              return Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFF42A5F5), shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    notificationService.unreadCount > 9 ? '9+' : notificationService.unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
