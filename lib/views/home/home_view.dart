import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/saved_controller.dart';
import '../../controllers/search_controller.dart' as search;
import '../../models/news_model.dart';
import '../../models/featured_section_model.dart';
import '../../services/notification_service.dart';
import '../../utils/colors.dart';
import '../../utils/date_helper.dart';
import '../../widgets/notification_bottom_sheet.dart';
import '../live_stream_view.dart';
import '../news_detail_page.dart';
import '../dashboard_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  HomeController get controller => Get.find<HomeController>();
  SavedController get savedController => Get.find<SavedController>();

  @override
  Widget build(BuildContext context) {
    final searchController = Get.put(search.NewsSearchController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: Obx(() {
        // Arama açıksa arama sonuçlarını göster
        if (controller.isSearchOpen.value) {
          return _buildSearchResults(searchController);
        }

        // Normal haber akışı
        return RefreshIndicator(
          onRefresh: () async => controller.refreshNews(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // ===== FEATURED SECTIONS (Admin Panel'den) =====
                Obx(() {
                  if (controller.isFeaturedLoading.value) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }
                  
                  if (controller.featuredSections.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  return Column(
                    children: controller.featuredSections.map((section) {
                      return _buildFeaturedSection(section);
                    }).toList(),
                  );
                }),
                
                // ===== PERSONALIZED NEWS FEED =====
                // Popüler Haberler Başlığı
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Popüler Haberler",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Carousel - kendi Obx'i var içinde
                _buildCarousel(),
                const SizedBox(height: 12),
                // Carousel Dots
                _buildCarouselDots(),
                const SizedBox(height: 20),
                // Kompakt Haber Kartları - sadece bu kısım yenileniyor
                Obx(() {
                  if (controller.isLoading.value) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  if (controller.newsList.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text("Bu kategoride haber bulunamadı."),
                      ),
                    );
                  }

                  return Column(children: [_buildNewsList()]);
                }),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Arama Sonuçları Widget'ı
  Widget _buildSearchResults(search.NewsSearchController searchController) {
    return Obx(() {
      if (searchController.searchQuery.value.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Haber aramak için yazın',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      if (searchController.isSearching.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      // Sonuç bulunamadıysa ama öneriler varsa
      if (searchController.searchResults.isEmpty) {
        if (searchController.suggestedResults.isNotEmpty) {
          // Önerilen sonuçları göster
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${searchController.searchQuery.value}" için sonuç bulunamadı',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bunları da arayabilirsiniz:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildSearchResultsList(
                  searchController.suggestedResults,
                ),
              ),
            ],
          );
        }

        // Hiç öneri de yoksa
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Sonuç bulunamadı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${searchController.searchQuery.value}" için sonuç yok',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${searchController.searchResults.length} sonuç bulundu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _buildSearchResultsList(searchController.searchResults),
          ),
        ],
      );
    });
  }

  // Arama sonuçları listesi (ortak widget)
  Widget _buildSearchResultsList(List<NewsModel> newsList) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            final news = newsList[index];
            return GestureDetector(
              onTap: () => Get.to(() => NewsDetailPage(news: news)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2F47) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Küçük Resim
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: news.image != null && news.image!.isNotEmpty
                          ? Image.network(
                              news.image!,
                              width: 90,
                              height: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 90,
                                height: 75,
                                color: isDark
                                    ? const Color(0xFF132440)
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.image,
                                  color: isDark ? Colors.white38 : Colors.grey,
                                  size: 24,
                                ),
                              ),
                            )
                          : Container(
                              width: 90,
                              height: 75,
                              color: isDark
                                  ? const Color(0xFF132440)
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.image,
                                color: isDark ? Colors.white38 : Colors.grey,
                                size: 24,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    // İçerik
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (news.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A4F67)
                                    : const Color(0xFF1E3A5F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                news.categoryName!,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF1E3A5F),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            news.title ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (news.sourceName != null &&
                                  news.sourceName!.isNotEmpty) ...[
                                Icon(
                                  Icons.article_outlined,
                                  size: 11,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    news.sourceName!,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  DateHelper.getTimeAgo(news.date),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
      },
    );
  }

  // AppBar
  AppBar _buildAppBar(BuildContext context) {
    final searchController = Get.put(search.NewsSearchController());

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      titleSpacing: 0,
      leading: Obx(
        () => controller.isSearchOpen.value
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
        if (controller.isSearchOpen.value) {
          // Arama açıkken search bar göster
          return _buildSearchBar(searchController);
        } else {
          // Normal logo göster
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
          if (controller.isSearchOpen.value) {
            // Arama açıkken kapat butonu
            return IconButton(
              onPressed: () {
                controller.isSearchOpen.value = false;
                searchController.clearSearch();
              },
              icon: const Icon(Icons.close, color: Colors.black87, size: 28),
            );
          } else {
            // Normal butonlar
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    controller.isSearchOpen.value = true;
                  },
                  icon: const Icon(
                    Icons.search,
                    color: Colors.black87,
                    size: 28,
                  ),
                ),
                // Canlı Yayın Butonu
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
                    // Okunmamış bildirim göstergesi
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

  // Arama Bar Widget'ı
  Widget _buildSearchBar(search.NewsSearchController searchController) {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: searchController.searchTextController,
        autofocus: true,
        onChanged: (value) => searchController.search(value),
        decoration: InputDecoration(
          hintText: 'Haber ara...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  // Carousel - Popüler Haberler
  Widget _buildCarousel() {
    return Obx(() {
      // Loading durumunda spinner göster
      if (controller.isCarouselLoading.value) {
        return const SizedBox(
          height: 280,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      final popularNews = controller.carouselNewsList;

      // Hiç haber yoksa boş mesaj
      if (popularNews.isEmpty) {
        return const SizedBox(
          height: 280,
          child: Center(child: Text("Popüler haberler yüklenemedi.")),
        );
      }

      return SizedBox(
        height: 280,
        child: PageView.builder(
          controller: controller.carouselController,
          padEnds: false,
          pageSnapping: true,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            controller.currentCarouselIndex.value = index;
            // Manuel kaydırma yapıldığında timer'ı sıfırla
            controller.resetAutoScroll();
          },
          itemCount: popularNews.length,
          itemBuilder: (context, index) {
            final news = popularNews[index];
            return GestureDetector(
              onTap: () => Get.to(() => NewsDetailPage(news: news)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Arka Plan Resmi
                      news.image != null && news.image!.isNotEmpty
                          ? Image.network(
                              news.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF1E3A5F),
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.white54,
                                    size: 60,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF1E3A5F),
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.white54,
                                  size: 60,
                                ),
                              ),
                            ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      // Kaydet Butonu
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Obx(() {
                          final isSaved = savedController.isSaved(news);
                          return GestureDetector(
                            onTap: () => savedController.toggleSave(news),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSaved ? Colors.white : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isSaved ? Colors.red : Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                        }),
                      ),
                      // Başlık ve Tarih
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news.title ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Kaynak adı
                                if (news.sourceName != null &&
                                    news.sourceName!.isNotEmpty)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.article_outlined,
                                          size: 12,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            news.sourceName!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                // Tarih
                                Text(
                                  DateHelper.getTimeAgo(news.date),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // Carousel Dots
  Widget _buildCarouselDots() {
    return Obx(() {
      final dotCount = controller.carouselNewsList.length;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(dotCount, (index) {
          final isActive = controller.currentCarouselIndex.value == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF4220B) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    });
  }

  // Kompakt Haber Listesi
  Widget _buildNewsList() {
    final newsList = controller.newsList;
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            final news = newsList[index];
            return GestureDetector(
              onTap: () => Get.to(() => NewsDetailPage(news: news)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2F47) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Küçük Resim
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: news.image != null && news.image!.isNotEmpty
                          ? Image.network(
                              news.image!,
                              width: 90,
                              height: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 90,
                                height: 75,
                                color: isDark
                                    ? const Color(0xFF132440)
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.image,
                                  color: isDark ? Colors.white38 : Colors.grey,
                                  size: 24,
                                ),
                              ),
                            )
                          : Container(
                              width: 90,
                              height: 75,
                              color: isDark
                                  ? const Color(0xFF132440)
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.image,
                                color: isDark ? Colors.white38 : Colors.grey,
                                size: 24,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    // İçerik
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2A4F67)
                                        : const Color(
                                            0xFF1E3A5F,
                                          ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    news.categoryName ?? "Haber",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF1E3A5F),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                    size: 20,
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            news.title ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              // Kaynak adı
                              if (news.sourceName != null &&
                                  news.sourceName!.isNotEmpty) ...[
                                Icon(
                                  Icons.article_outlined,
                                  size: 11,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    news.sourceName!,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              // Tarih
                              Flexible(
                                child: Text(
                                  DateHelper.getTimeAgo(news.date),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
      },
    );
  }

  // ===== FEATURED SECTION BUILDER =====
  Widget _buildFeaturedSection(FeaturedSectionModel section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Başlığı
        if (section.title != null && section.title!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (section.type == 'breaking_news')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SON DAKİKA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    section.title!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        
        // Section İçeriği (Tip'e göre)
        if (section.type == 'slider')
          _buildFeaturedSlider(section)
        else if (section.type == 'breaking_news')
          _buildBreakingNewsSection(section)
        else
          _buildHorizontalListSection(section),
        
        const SizedBox(height: 16),
      ],
    );
  }

  // Featured Slider (Carousel)
  Widget _buildFeaturedSlider(FeaturedSectionModel section) {
    if (section.news.isEmpty || section.id == null) {
      return const SizedBox.shrink();
    }

    final pageController = controller.featuredSliderControllers[section.id!];
    if (pageController == null) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: (index) {
              controller.updateFeaturedSliderIndex(section.id!, index);
              controller.update();
            },
            itemCount: section.news.length,
            itemBuilder: (context, index) {
              final news = section.news[index];
              return GestureDetector(
                onTap: () => Get.to(() => NewsDetailPage(news: news)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Resim
                        news.image != null && news.image!.isNotEmpty
                            ? Image.network(
                                news.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1E3A5F),
                                  child: const Icon(Icons.image, color: Colors.white54, size: 50),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF1E3A5F),
                                child: const Icon(Icons.image, color: Colors.white54, size: 50),
                              ),
                        // Gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                            ),
                          ),
                        ),
                        // Başlık
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Text(
                            news.title ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Slider Dots
        GetBuilder<HomeController>(
          builder: (_) {
            final currentIndex = controller.featuredSliderIndices[section.id!] ?? 0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(section.news.length, (index) {
                final isActive = currentIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  // Breaking News Section
  Widget _buildBreakingNewsSection(FeaturedSectionModel section) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: section.news.length,
        itemBuilder: (context, index) {
          final news = section.news[index];
          return GestureDetector(
            onTap: () => Get.to(() => NewsDetailPage(news: news)),
            child: Container(
              width: 280,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Resim
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: news.image != null && news.image!.isNotEmpty
                        ? Image.network(
                            news.image!,
                            width: 100,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 140,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 100,
                            height: 140,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  // İçerik
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SON DAKİKA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              news.title ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                          Text(
                            DateHelper.getTimeAgo(news.date),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Horizontal List Section
  Widget _buildHorizontalListSection(FeaturedSectionModel section) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: section.news.length,
        itemBuilder: (context, index) {
          final news = section.news[index];
          return GestureDetector(
            onTap: () => Get.to(() => NewsDetailPage(news: news)),
            child: Container(
              width: 160,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resim
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: news.image != null && news.image!.isNotEmpty
                        ? Image.network(
                            news.image!,
                            width: 160,
                            height: 95,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 160,
                              height: 95,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 160,
                            height: 95,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  // İçerik
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              news.title ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Text(
                            DateHelper.getTimeAgo(news.date),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
