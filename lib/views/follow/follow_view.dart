import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../controllers/follow_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/home_controller.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../models/source_model.dart';
import '../../utils/colors.dart';
import '../../widgets/notification_bottom_sheet.dart';
import '../source_profile_view.dart';
import '../source_selection_view.dart';
import '../login_view.dart';
import '../live_stream_view.dart';
import '../dashboard_view.dart';

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

        // Hiç kaynak seçilmemişse
        if (controller.selectedSources.isEmpty) {
          return _buildEmptyState(isDark);
        }

        // Kategorilere göre grupla
        final groupedSources = <String, List<SourceModel>>{};
        for (final source in controller.selectedSources) {
          final category = source.category.isNotEmpty ? source.category : 'Diğer';
          groupedSources.putIfAbsent(category, () => []);
          groupedSources[category]!.add(source);
        }

        // Kategorileri alfabetik sırala
        final sortedCategories = groupedSources.keys.toList()..sort();

        return RefreshIndicator(
          onRefresh: () => controller.refreshSources(),
          color: AppColors.primary,
          child: Container(
            color: isDark ? const Color(0xFF1A2F47) : Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 0, bottom: 100),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final category = sortedCategories[index];
                final sources = groupedSources[category]!..sort((a, b) => a.name.compareTo(b.name));
                final color = _getCategoryColor(category);

                return _buildCategorySection(category, sources, color, isDark);
              },
            ),
          ),
        );
      }),
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
                // Üye kontrolü
                if (authService.isLoggedIn && !authService.isGuest) {
                  Get.to(() => SourceSelectionView());
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
              label: const Text('Kaynak Seç'),
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

  Widget _buildCategorySection(String category, List<SourceModel> sources, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2F47) : Colors.white,
            border: Border(
              left: BorderSide(color: color, width: 4),
              bottom: BorderSide(color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getCategoryIcon(category), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${sources.length} kaynak',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Sources Grid
        Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF1A2F47) : Colors.white,
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sources.map((source) => _buildSourceChip(source, color, isDark)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceChip(SourceModel source, Color color, bool isDark) {
    return GestureDetector(
      onTap: () => Get.to(() => SourceProfileView(source: source)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132440) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  source.name.isNotEmpty ? source.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              source.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: isDark ? Colors.white38 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('gündem')) return Icons.newspaper;
    if (c.contains('son dakika')) return Icons.flash_on;
    if (c.contains('spor')) return Icons.sports_soccer;
    if (c.contains('ekonomi')) return Icons.trending_up;
    if (c.contains('teknoloji')) return Icons.computer;
    if (c.contains('bilim')) return Icons.science;
    if (c.contains('ajans')) return Icons.rss_feed;
    if (c.contains('yerel')) return Icons.location_city;
    if (c.contains('yabancı') || c.contains('dünya')) return Icons.public;
    return Icons.article;
  }

  AppBar _buildAppBar(BuildContext context, bool isDark) {
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
      title: Transform.translate(
        offset: const Offset(-30, 0),
        child: SizedBox(
          height: 100,
          width: 180,
          child: SvgPicture.asset(
            'assets/logo.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(Color(0xFFF4220B), BlendMode.srcIn),
          ),
        ),
      ),
      centerTitle: false,
      actions: [
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
              final notificationService = NotificationService();
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
