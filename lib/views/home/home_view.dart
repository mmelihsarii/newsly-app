import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/saved_controller.dart';
import '../../controllers/search_controller.dart' as search;
import '../../controllers/reading_settings_controller.dart';
import '../../models/news_model.dart';
import '../../models/featured_section_model.dart';
import '../../services/notification_service.dart';
import '../../utils/colors.dart';
import '../../utils/date_helper.dart';
import '../../utils/source_logos.dart';
import '../../widgets/notification_bottom_sheet.dart';
import '../../widgets/search_filter_sheet.dart';
import '../../widgets/news_card.dart' show getCategoryColor;
import '../live_stream_view.dart';
import '../news_detail_page.dart';
import '../dashboard_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  HomeController get controller => Get.find<HomeController>();
  SavedController get savedController => Get.find<SavedController>();

  @override
  Widget build(BuildContext context) {
    final searchController = Get.find<search.NewsSearchController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: Obx(() {
        // Arama açıksa arama sonuçlarını göster
        if (controller.isSearchOpen.value) {
          return _buildSearchResults(searchController);
        }

        // Normal haber akışı - PERFORMANS OPTİMİZE
        return RefreshIndicator(
          onRefresh: () async => controller.refreshNews(),
          color: AppColors.primary,
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            cacheExtent: 500, // Önceden render et
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ===== SLIDER (PANEL'DEN - type: slider) =====
              Obx(() {
                if (controller.isFeaturedLoading.value) {
                  return const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }

                if (controller.sliderSections.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverToBoxAdapter(
                  child: Column(
                    children: controller.sliderSections.map((section) {
                      return _buildFeaturedSlider(section);
                    }).toList(),
                  ),
                );
              }),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ===== HABER LİSTESİ - SliverList ile optimize =====
              Obx(() {
                // İlk yükleme sırasında loading göster
                if (controller.isLoading.value || controller.isFeaturedLoading.value) {
                  return const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }

                // Haberler yüklendi ama boş
                if (controller.newsSections.isEmpty && controller.rssNews.isEmpty) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.newspaper, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              "Haber bulunamadı",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => controller.refreshNews(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text("Yenile"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Haber listesi - SliverList ile performanslı
                return _buildOptimizedNewsList();
              }),
            ],
          ),
        );
      }),
    );
  }

  /// PERFORMANS OPTİMİZE - SliverList ile haber listesi
  Widget _buildOptimizedNewsList() {
    final isDark = Get.isDarkMode;
    final readingController = Get.find<ReadingSettingsController>();
    
    // Section başlığı ve haberler
    final section = controller.newsSections.isNotEmpty ? controller.newsSections.first : null;
    if (section == null || section.news.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    return SliverMainAxisGroup(
      slivers: [
        // Section Başlığı
        if (section.title != null && section.title!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                section.title!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        
        // Haber Listesi - SliverList ile lazy loading
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: section.news.length + 1, // +1 for loading indicator
            itemBuilder: (context, index) {
              // Son item loading indicator
              if (index == section.news.length) {
                return Obx(() {
                  if (controller.isLoadingMore.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  
                  if (!controller.hasMoreNews.value) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Tüm haberler yüklendi',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return const SizedBox(height: 60);
                });
              }
              
              final news = section.news[index];
              return _OptimizedNewsListItem(
                key: ValueKey('news_${news.id ?? index}'),
                news: news,
                isDark: isDark,
                hideImages: readingController.hideImages.value,
              );
            },
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  // Arama Sonuçları Widget'ı
  Widget _buildSearchResults(search.NewsSearchController searchController) {
    return Obx(() {
      final isDark = Get.isDarkMode;
      
      // Arama boş ve filtre yok
      if (searchController.searchQuery.value.isEmpty && !searchController.isFilterActive.value) {
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
              const SizedBox(height: 24),
              // Filtre butonu
              OutlinedButton.icon(
                onPressed: () => showSearchFilterSheet(Get.context!, searchController),
                icon: const Icon(Icons.tune),
                label: const Text('Gelişmiş Filtreler'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
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
              // Aktif filtreler
              _buildActiveFiltersBar(searchController, isDark),
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
        return Column(
          children: [
            _buildActiveFiltersBar(searchController, isDark),
            Expanded(
              child: Center(
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
                      searchController.searchQuery.value.isNotEmpty
                          ? '"${searchController.searchQuery.value}" için sonuç yok'
                          : 'Seçili filtrelere uygun haber bulunamadı',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                    if (searchController.isFilterActive.value) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => searchController.clearFilters(),
                        child: const Text('Filtreleri Temizle'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aktif filtreler
          _buildActiveFiltersBar(searchController, isDark),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  // Aktif filtreler bar'ı
  Widget _buildActiveFiltersBar(search.NewsSearchController searchController, bool isDark) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132440) : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade200,
            ),
          ),
        ),
        child: Row(
          children: [
            // Filtre butonu
            GestureDetector(
              onTap: () => showSearchFilterSheet(Get.context!, searchController),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: searchController.isFilterActive.value
                      ? AppColors.primary.withOpacity(0.1)
                      : (isDark ? const Color(0xFF2A4F67) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: searchController.isFilterActive.value
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF3A5F77) : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 18,
                      color: searchController.isFilterActive.value
                          ? AppColors.primary
                          : (isDark ? Colors.white70 : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filtreler',
                      style: TextStyle(
                        color: searchController.isFilterActive.value
                            ? AppColors.primary
                            : (isDark ? Colors.white70 : Colors.grey.shade600),
                        fontWeight: searchController.isFilterActive.value
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (searchController.activeFilterCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${searchController.activeFilterCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Aktif filtre chip'leri
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Tarih filtresi
                    if (searchController.selectedDateRange.value.isNotEmpty)
                      _buildFilterChip(
                        _getDateRangeLabel(searchController.selectedDateRange.value),
                        () => searchController.setDateRange(''),
                        isDark,
                      ),
                    // Kategori filtreleri
                    ...searchController.selectedCategories.map((catId) {
                      final category = searchController.availableCategories
                          .firstWhereOrNull((c) => c.id == catId);
                      return _buildFilterChip(
                        category?.name ?? catId,
                        () => searchController.toggleCategory(catId),
                        isDark,
                      );
                    }),
                    // Kaynak filtreleri
                    ...searchController.selectedSources.map((source) {
                      return _buildFilterChip(
                        source,
                        () => searchController.toggleSource(source),
                        isDark,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getDateRangeLabel(String range) {
    switch (range) {
      case 'today':
        return 'Bugün';
      case 'week':
        return 'Son 7 Gün';
      case 'month':
        return 'Son 30 Gün';
      case 'custom':
        return 'Özel Tarih';
      default:
        return range;
    }
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Arama sonuçları listesi (ortak widget)
  Widget _buildSearchResultsList(List<NewsModel> newsList) {
    final readingController = Get.find<ReadingSettingsController>();
    
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Obx(() {
          final hideImages = readingController.hideImages.value;
          
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
                      // Küçük Resim - hideImages açıksa gösterme
                      if (!hideImages)
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
                      if (!hideImages) const SizedBox(width: 10),
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
                              maxLines: hideImages ? 3 : 2,
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getCategoryColor(news.categoryName).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      news.sourceName!,
                                      style: TextStyle(
                                        color: getCategoryColor(news.categoryName),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    DateHelper.getTimeAgo(news.publishedAt ?? news.date),
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
        });
      },
    );
  }

  // AppBar
  AppBar _buildAppBar(BuildContext context) {
    final searchController = Get.find<search.NewsSearchController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
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
          return _buildSearchBar(searchController, isDark);
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
              icon: Icon(
                Icons.close, 
                color: isDark ? Colors.white : Colors.black87, 
                size: 28,
              ),
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
                  icon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white : Colors.black87,
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
  Widget _buildSearchBar(search.NewsSearchController searchController, bool isDark) {
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
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  // ===== FEATURED SLIDER (PANEL'DEN) =====
  Widget _buildFeaturedSlider(FeaturedSectionModel section) {
    if (section.news.isEmpty || section.id == null) {
      return const SizedBox.shrink();
    }

    final pageController = controller.featuredSliderControllers[section.id!];
    if (pageController == null) return const SizedBox.shrink();
    
    final readingController = Get.find<ReadingSettingsController>();

    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Color(0xCC000000)],
    );

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Obx(() {
          final hideImages = readingController.hideImages.value;
          
          // Görseller gizliyse slider yerine basit liste göster
          if (hideImages) {
            return _buildTextOnlySlider(section, isDark);
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Başlığı
              if (section.title != null && section.title!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    section.title!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: (index) {
                    controller.updateSliderIndex(section.id!, index);
                    controller.update();
                  },
                  itemCount: section.news.length,
                  itemBuilder: (context, index) {
                    final news = section.news[index];
                    return _buildSliderItem(news, gradient);
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Slider Dots
              GetBuilder<HomeController>(
                builder: (_) {
              final currentIndex =
                  controller.featuredSliderIndices[section.id!] ?? 0;
              final itemCount = section.news.length > 10
                  ? 10
                  : section.news.length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(itemCount, (index) {
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
          const SizedBox(height: 16),
            ],
          );
        });
      },
    );
  }
  
  /// Görseller gizliyken slider yerine gösterilecek metin tabanlı liste
  Widget _buildTextOnlySlider(FeaturedSectionModel section, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Başlığı
        if (section.title != null && section.title!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              section.title!,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        // Yatay kaydırılabilir haber kartları
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: section.news.length > 10 ? 10 : section.news.length,
            itemBuilder: (context, index) {
              final news = section.news[index];
              return GestureDetector(
                onTap: () => Get.to(() => NewsDetailPage(news: news)),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2F47) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori ve kaydet butonu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (news.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                news.categoryName!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Obx(() {
                            final isSaved = savedController.isSaved(news);
                            return GestureDetector(
                              onTap: () => savedController.toggleSave(news),
                              child: Icon(
                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: isSaved ? AppColors.primary : (isDark ? Colors.white54 : Colors.grey),
                                size: 20,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Başlık
                      Expanded(
                        child: Text(
                          news.title ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tarih
                      Text(
                        DateHelper.getTimeAgo(news.publishedAt ?? news.date),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Slider Item
  Widget _buildSliderItem(NewsModel news, LinearGradient gradient) {
    return GestureDetector(
      onTap: () => Get.to(() => NewsDetailPage(news: news)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Resim veya Fallback
              _buildSliderImage(news),
              // Gradient
              DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
              // Kategori (sol üst)
              if (news.categoryName != null && news.categoryName!.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      news.categoryName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              // Kaydet butonu (sağ üst)
              Positioned(
                top: 12,
                right: 12,
                child: Obx(() {
                  final isSaved = savedController.isSaved(news);
                  return GestureDetector(
                    onTap: () => savedController.toggleSave(news),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSaved ? Colors.white : Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? AppColors.primary : Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                }),
              ),
              // Başlık ve tarih (alt)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateHelper.getTimeAgo(news.publishedAt ?? news.date),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== HABER SECTİON (PANEL'DEN - breaking_news vs.) =====
  Widget _buildNewsSection(FeaturedSectionModel section) {
    if (section.news.isEmpty) {
      return const SizedBox.shrink();
    }

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Başlığı
            if (section.title != null && section.title!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  section.title!,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            // Haber Listesi - sadece mevcut haberleri göster
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: section.news.length,
              itemBuilder: (context, index) {
                final news = section.news[index];
                return _buildNewsListItem(news, isDark);
              },
            ),
            // Loading indicator - ayrı Obx içinde
            Obx(() {
              if (controller.isLoadingMore.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              
              // Tüm haberler yüklendiyse mesaj göster
              if (!controller.hasMoreNews.value) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Tüm haberler yüklendi',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              
              // Daha fazla haber var ama henüz yüklenmiyor - boşluk bırak
              return const SizedBox(height: 60);
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // Haber Liste Item
  Widget _buildNewsListItem(NewsModel news, bool isDark) {
    final readingController = Get.find<ReadingSettingsController>();
    
    return GestureDetector(
      onTap: () => Get.to(() => NewsDetailPage(news: news)),
      child: Obx(() {
        final hideImages = readingController.hideImages.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
              // Resim veya Fallback - hideImages açıksa gösterme
              if (!hideImages)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildListItemImage(news, isDark),
                ),
              if (!hideImages) const SizedBox(width: 12),
              // İçerik
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kaynak adı - kategori renkli
                    if (news.sourceName != null && news.sourceName!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: getCategoryColor(news.categoryName).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          news.sourceName!,
                          style: TextStyle(
                            color: getCategoryColor(news.categoryName),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Başlık
                    Text(
                      news.title ?? "",
                      maxLines: hideImages ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tarih
                    Text(
                      DateHelper.getTimeAgo(news.publishedAt ?? news.date),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Slider için görsel widget'ı
  Widget _buildSliderImage(NewsModel news) {
    final hasImage = news.image != null && news.image!.isNotEmpty;
    
    if (hasImage) {
      return CachedNetworkImage(
        imageUrl: news.image!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 800,
        memCacheHeight: 450,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => Container(
          color: const Color(0xFF1E3A5F),
        ),
        errorWidget: (context, url, error) => _buildSliderFallback(news),
      );
    } else {
      return _buildSliderFallback(news);
    }
  }

  /// Slider için fallback görsel (logo veya placeholder)
  Widget _buildSliderFallback(NewsModel news) {
    final logoUrls = SourceLogos.getLogoUrlVariants(news.sourceName);
    final categoryColor = getCategoryColor(news.categoryName);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withOpacity(0.9),
            categoryColor.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: _buildLogoWithFallbacks(logoUrls, news, 66),
        ),
      ),
    );
  }
  
  /// Birden fazla URL deneyen logo widget'ı
  Widget _buildLogoWithFallbacks(List<String> urls, NewsModel news, double size) {
    if (urls.isEmpty) {
      return _buildSourceInitialWidget(news, size);
    }
    
    return CachedNetworkImage(
      imageUrl: urls[0],
      fit: BoxFit.contain,
      alignment: Alignment.center,
      imageBuilder: (context, imageProvider) => Image(
        image: imageProvider,
        fit: BoxFit.contain,
      ),
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) {
        if (urls.length > 1) {
          return _buildLogoWithFallbacks(urls.sublist(1), news, size);
        }
        return Center(
          child: Icon(
            Icons.newspaper,
            size: size * 0.5,
            color: getCategoryColor(news.categoryName),
          ),
        );
      },
    );
  }

  /// Liste item için görsel widget'ı
  Widget _buildListItemImage(NewsModel news, bool isDark) {
    final hasImage = news.image != null && news.image!.isNotEmpty;
    
    if (hasImage) {
      return SizedBox(
        width: 100,
        height: 85,
        child: CachedNetworkImage(
          imageUrl: news.image!,
          width: 100,
          height: 85,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          memCacheWidth: 200,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          placeholder: (context, url) => Container(
            width: 100,
            height: 85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132440) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => _buildListItemFallback(news, isDark),
        ),
      );
    } else {
      return _buildListItemFallback(news, isDark);
    }
  }

  /// Liste item için fallback görsel
  Widget _buildListItemFallback(NewsModel news, bool isDark) {
    final logoUrls = SourceLogos.getLogoUrlVariants(news.sourceName);
    final categoryColor = getCategoryColor(news.categoryName);
    
    return Container(
      width: 100,
      height: 85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withOpacity(0.3),
            categoryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: _buildLogoWithFallbacks(logoUrls, news, 38),
        ),
      ),
    );
  }

  /// Firebase Storage'dan kaynak logosu URL'si oluştur
  String _getSourceLogoUrl(String? sourceName) {
    if (sourceName == null || sourceName.isEmpty) {
      return 'https://firebasestorage.googleapis.com/v0/b/newsly-70ef9.firebasestorage.app/o/source_logos%2Fdefault.png?alt=media';
    }
    
    // Normalize: Halk TV -> halk_tv
    String normalized = sourceName
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('.', '')
        .replaceAll('&', '')
        .replaceAll("'", '')
        .trim();
    
    return 'https://firebasestorage.googleapis.com/v0/b/newsly-70ef9.firebasestorage.app/o/source_logos%2F$normalized.png?alt=media';
  }

  /// Kaynak logosu widget'ı - Firebase Storage'dan çeker
  Widget _buildSourceInitialWidget(NewsModel news, double size) {
    final logoUrl = _getSourceLogoUrl(news.sourceName);
    final categoryColor = getCategoryColor(news.categoryName);
    
    return CachedNetworkImage(
      imageUrl: logoUrl,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      memCacheWidth: 100,
      imageBuilder: (context, imageProvider) => Image(
        image: imageProvider,
        fit: BoxFit.contain,
      ),
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Center(
        child: Icon(
          Icons.newspaper,
          size: size * 0.5,
          color: categoryColor,
        ),
      ),
    );
  }
}

/// PERFORMANS OPTİMİZE - Ayrı StatelessWidget olarak haber item
/// Bu sayede her item bağımsız olarak rebuild olur, tüm liste değil
class _OptimizedNewsListItem extends StatelessWidget {
  final NewsModel news;
  final bool isDark;
  final bool hideImages;

  const _OptimizedNewsListItem({
    super.key,
    required this.news,
    required this.isDark,
    required this.hideImages,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => NewsDetailPage(news: news)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Resim veya Fallback - hideImages açıksa gösterme
            if (!hideImages)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildOptimizedImage(),
              ),
            if (!hideImages) const SizedBox(width: 12),
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kaynak adı - kategori renkli
                  if (news.sourceName != null && news.sourceName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: getCategoryColor(news.categoryName).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        news.sourceName!,
                        style: TextStyle(
                          color: getCategoryColor(news.categoryName),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Başlık
                  Text(
                    news.title ?? "",
                    maxLines: hideImages ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Tarih
                  Text(
                    DateHelper.getTimeAgo(news.publishedAt ?? news.date),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Optimize edilmiş görsel widget'ı
  Widget _buildOptimizedImage() {
    final hasImage = news.image != null && news.image!.isNotEmpty;
    
    if (hasImage) {
      return SizedBox(
        width: 100,
        height: 85,
        child: CachedNetworkImage(
          imageUrl: news.image!,
          width: 100,
          height: 85,
          fit: BoxFit.cover,
          memCacheWidth: 200, // Bellek optimizasyonu
          memCacheHeight: 170,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 200),
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          placeholder: (context, url) => Container(
            width: 100,
            height: 85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132440) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackImage(),
        ),
      );
    } else {
      return _buildFallbackImage();
    }
  }

  /// Fallback görsel
  Widget _buildFallbackImage() {
    final categoryColor = getCategoryColor(news.categoryName);
    
    return Container(
      width: 100,
      height: 85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withOpacity(0.3),
            categoryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.newspaper,
          size: 32,
          color: categoryColor.withOpacity(0.7),
        ),
      ),
    );
  }
}
