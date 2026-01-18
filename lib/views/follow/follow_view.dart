import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../controllers/source_selection_controller.dart';
import '../../controllers/saved_controller.dart';
import '../../controllers/search_controller.dart' as search;
import '../../controllers/home_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/news_service.dart';
import '../../services/notification_service.dart';
import '../../models/news_model.dart';
import '../../utils/colors.dart';
import '../../utils/date_helper.dart';
import '../../widgets/notification_bottom_sheet.dart';
import '../news_detail_page.dart';
import '../source_selection_view.dart';
import '../live_stream_view.dart';
import '../dashboard_view.dart';

class FollowView extends StatefulWidget {
  const FollowView({super.key});

  @override
  State<FollowView> createState() => _FollowViewState();
}

class _FollowViewState extends State<FollowView> {
  final NewsService _newsService = NewsService();
  final List<NewsModel> _newsList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late final search.NewsSearchController searchController;
  final isSearchOpen = false.obs;

  @override
  void initState() {
    super.initState();
    searchController = Get.put(search.NewsSearchController());
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final news = await _newsService.fetchAllNews();
      setState(() {
        _newsList.clear();
        _newsList.addAll(news);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Haberler yüklenirken bir hata oluştu';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // SourceSelectionController'ı register et
    final sourceController = Get.put(SourceSelectionController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: Obx(() {
        // Hiç kaynak seçilmemişse
        if (sourceController.selectedSources.isEmpty) {
          return _buildEmptyState();
        }

        // Yükleniyor
        if (_isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Haberler yükleniyor...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Hata durumu
        if (_errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchNews,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        // Haber listesi boşsa
        if (_newsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Henüz haber bulunamadı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seçtiğiniz kaynaklardan haber yok',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchNews,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        // Haber listesi
        return RefreshIndicator(
          onRefresh: _fetchNews,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _newsList.length,
            itemBuilder: (context, index) {
              final news = _newsList[index];
              return _buildNewsCard(news);
            },
          ),
        );
      }),
    );
  }

  Widget _buildNewsCard(NewsModel news) {
    final savedController = Get.find<SavedController>();

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
                      if (news.description != null)
                        Text(
                          DateHelper.stripHtml(news.description!),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Kaynak adı
                          if (news.sourceName != null)
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
                                news.sourceName!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const Spacer(),
                          // Tarih
                          if (news.date != null)
                            Text(
                              DateHelper.getTimeAgo(news.date),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(width: 12),
                          // Kaydet butonu
                          Obx(() {
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

  Widget _buildEmptyState() {
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
              child: const Icon(
                Icons.add_circle_outline,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kaynak Seçin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Henüz haber kaynağı seçmediniz.\nKaynak seçerek takip ettiğiniz\nhaberleri burada görün.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const SourceSelectionView()),
              icon: const Icon(Icons.add),
              label: const Text('Kaynak Seç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
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
          return _buildSearchBar(isDark);
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

  Widget _buildSearchBar(bool isDark) {
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
