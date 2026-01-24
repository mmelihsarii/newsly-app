import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../controllers/local_controller.dart';
import '../../controllers/saved_controller.dart';
import '../../controllers/search_controller.dart' as search;
import '../../controllers/home_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/notification_service.dart';
import '../../utils/colors.dart';
import '../../utils/date_helper.dart';
import '../../widgets/notification_bottom_sheet.dart';
import '../news_detail_page.dart';
import '../live_stream_view.dart';
import '../dashboard_view.dart';

class LocalView extends StatelessWidget {
  const LocalView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı register et
    final controller = Get.put(LocalController());
    final searchController = Get.find<search.NewsSearchController>();
    final isSearchOpen = false.obs;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, isSearchOpen, searchController),
      body: Column(
        children: [
          // Şehir Seçim Listesi
          _buildCitySelector(controller),
          // Haber Listesi
          Expanded(
            child: Obx(() {
              if (controller.isNewsLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (controller.localNewsList.isEmpty) {
                return _buildEmptyState(controller);
              }

              return _buildNewsList(controller);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelector(LocalController controller) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2F47) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.2) 
                    : Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(() {
            if (controller.isCitiesLoading.value) {
              return Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
              );
            }

            // selectedCity'yi burada dinle - bu tüm listenin yeniden build edilmesini sağlar
            final currentSelectedCity = controller.selectedCity.value;

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: controller.cityList.length,
              itemBuilder: (context, index) {
                final city = controller.cityList[index];
                final isSelected = currentSelectedCity?['name'] == city['name'];
                final cityName = city['name'] ?? '';

                return GestureDetector(
                  onTap: () => controller.selectCity(city),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary 
                          : (isDark ? const Color(0xFF132440) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cityName,
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }

  Widget _buildEmptyState(LocalController controller) {
    final cityName = controller.selectedCity.value?['name'] ?? 'Şehir';

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.newspaper, 
                size: 64, 
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '$cityName için haber bulunamadı',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600, 
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => controller.loadSources(),
                icon: const Icon(Icons.refresh),
                label: const Text('Yeniden Dene'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewsList(LocalController controller) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return RefreshIndicator(
          onRefresh: () => controller.fetchLocalNews(),
          color: AppColors.primary,
          backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.localNewsList.length,
            itemBuilder: (context, index) {
              final news = controller.localNewsList[index];
              return _buildNewsCard(news);
            },
          ),
        );
      },
    );
  }

  Widget _buildNewsCard(dynamic news) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () => Get.to(() => NewsDetailPage(news: news)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2F47) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (news.image != null && news.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: news.image!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 160,
                        color: isDark
                            ? const Color(0xFF132440)
                            : Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white38 : AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 160,
                        color: isDark
                            ? const Color(0xFF132440)
                            : Colors.grey.shade200,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateHelper.stripHtml(news.description ?? ''),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              news.categoryName ?? 'Yerel',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Kaynak ve Tarih
                          Row(
                            children: [
                              // Kaynak adı
                              if (news.sourceName != null &&
                                  news.sourceName!.isNotEmpty) ...[
                                Icon(
                                  Icons.article_outlined,
                                  size: 12,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  news.sourceName!,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // Tarih
                              Text(
                                DateHelper.getTimeAgo(news.date),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Obx(() {
                            final savedController = Get.find<SavedController>();
                            final isSaved = savedController.isSaved(news);
                            return GestureDetector(
                              onTap: () => savedController.toggleSave(news),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isSaved
                                    ? Colors.red
                                    : (isDark
                                          ? Colors.white38
                                          : Colors.grey.shade400),
                                size: 22,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
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
