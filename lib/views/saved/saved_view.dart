import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/news_card.dart';
import '../../controllers/saved_controller.dart';
import '../../controllers/search_controller.dart' as search;
import '../../controllers/home_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_bottom_sheet.dart';
import '../news_detail_page.dart';
import '../live_stream_view.dart';
import '../dashboard_view.dart';

class SavedView extends StatelessWidget {
  const SavedView({super.key});

  @override
  Widget build(BuildContext context) {
    final SavedController controller = Get.find<SavedController>();
    final searchController = Get.put(search.NewsSearchController());
    final isSearchOpen = false.obs;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, isSearchOpen, searchController),
      body: Obx(() {
        // Kaydedilen haber yoksa
        if (controller.savedNewsList.isEmpty) {
          return _buildEmptyState();
        }

        // Kaydedilen haberler listesi
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: controller.savedNewsList.length,
          itemBuilder: (context, index) {
            final news = controller.savedNewsList[index];
            return Dismissible(
              key: Key(news.title ?? index.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              onDismissed: (_) => controller.removeNews(news),
              child: NewsCard(
                news: news,
                onTap: () => Get.to(() => NewsDetailPage(news: news)),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2F47)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Kaydedilenler',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kaydettiğiniz haberler burada görünecek.\nHaberlerdeki kaydet butonuna tıklayarak\nfavori haberlerinizi saklayabilirsiniz.',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    RxBool isSearchOpen,
    search.NewsSearchController searchController,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      titleSpacing: 0,
      leading: Obx(
        () => isSearchOpen.value
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: () {
                  mainScaffoldKey.currentState?.openDrawer();
                },
                icon: const Icon(
                  Icons.menu,
                  color: Color(0xFFF4220B),
                  size: 32,
                ),
              ),
      ),
      title: Obx(() {
        if (isSearchOpen.value) {
          return _buildSearchBar(searchController, isDark);
        } else {
          return Transform.translate(
            offset: const Offset(-30, 0),
            child: SizedBox(
              height: 100,
              width: 180,
              child: SvgPicture.asset(
                'assets/logo.svg',
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFF4220B),
                  BlendMode.srcIn,
                ),
              ),
            ),
          );
        }
      }),
      centerTitle: false,
      actions: [
        Obx(() {
          if (isSearchOpen.value) {
            return IconButton(
              onPressed: () {
                isSearchOpen.value = false;
                searchController.clearSearch();
              },
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.white : Colors.black87,
                size: 28,
              ),
            );
          } else {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    // Anasayfaya git ve aramayı aç
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
                  icon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 28,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.to(() => const LiveStreamView()),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.red,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        showNotificationsBottomSheet(context);
                      },
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFFF4220B),
                        size: 28,
                      ),
                    ),
                    Obx(() {
                      final notificationService = NotificationService();
                      if (notificationService.unreadCount == 0) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF42A5F5),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            notificationService.unreadCount > 9
                                ? '9+'
                                : notificationService.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            );
          }
        }),
      ],
    );
  }

  Widget _buildSearchBar(
    search.NewsSearchController searchController,
    bool isDark,
  ) {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132440) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: searchController.searchTextController,
        autofocus: true,
        onChanged: (value) => searchController.search(value),
        decoration: InputDecoration(
          hintText: 'Haber ara...',
          hintStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
