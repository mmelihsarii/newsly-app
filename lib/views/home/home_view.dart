import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/saved_controller.dart';
import '../../utils/colors.dart';
import '../news_detail_page.dart';
import '../dashboard_view.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  HomeController get controller => Get.find<HomeController>();
  SavedController get savedController => Get.find<SavedController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.newsList.isEmpty) {
          return const Center(child: Text("Henüz haber yok."));
        }

        return RefreshIndicator(
          onRefresh: () async => controller.fetchNews(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
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
                // Carousel
                _buildCarousel(),
                const SizedBox(height: 12),
                // Carousel Dots
                _buildCarouselDots(),
                const SizedBox(height: 20),
                // Kategori Tab Bar
                _buildCategoryTabs(),
                const SizedBox(height: 16),
                // Kompakt Haber Kartları
                _buildNewsList(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // AppBar
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () {
          mainScaffoldKey.currentState?.openDrawer();
        },
        icon: const Icon(Icons.menu, color: Color(0xFFF4220B), size: 32),
      ),
      title: Transform.translate(
        offset: const Offset(-30, 0), // Sola kaydır
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
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: Colors.black87, size: 28),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.videocam, color: Colors.red, size: 26),
        ),
        const SizedBox(width: 4),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFFF4220B),
                size: 28,
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF42A5F5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Carousel - Popüler Haberler
  Widget _buildCarousel() {
    final popularNews = controller.newsList.take(5).toList();

    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: controller.carouselController,
        padEnds: false,
        pageSnapping: true,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          controller.currentCarouselIndex.value = index;
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
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
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
                          Text(
                            news.date ?? "",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
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
        },
      ),
    );
  }

  // Carousel Dots
  Widget _buildCarouselDots() {
    final dotCount = controller.newsList.length > 5
        ? 5
        : controller.newsList.length;
    return Obx(
      () => Row(
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
      ),
    );
  }

  // Kategori Tab Bar
  Widget _buildCategoryTabs() {
    // Her kategori için özel renkler
    final Map<String, Color> categoryColors = {
      'Latest': const Color(0xFFF4220B),
      'Business': const Color(0xFF213C51),
      'Sports': const Color(0xFF42A5F5),
      'Politics': const Color(0xFFD25353),
      'Health': const Color(0xFF78C841),
      'Tech': const Color(0xFFF4220B),
    };

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          return Obx(() {
            final isSelected = controller.selectedCategoryIndex.value == index;
            final categoryName = controller.categories[index];
            final categoryColor =
                categoryColors[categoryName] ?? const Color(0xFFF4220B);

            return GestureDetector(
              onTap: () => controller.changeCategory(index),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? categoryColor : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? categoryColor : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  // Kompakt Haber Listesi
  Widget _buildNewsList() {
    final newsList = controller.newsList.skip(5).toList();
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Küçük Resim
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: news.image != null && news.image!.isNotEmpty
                      ? Image.network(
                          news.image!,
                          width: 100,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                // İçerik
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A5F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              news.categoryName ?? "Haber",
                              style: const TextStyle(
                                color: Color(0xFF1E3A5F),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "5 dk okuma",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
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
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news.title ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        news.date ?? "",
                        style: TextStyle(
                          color: Colors.grey.shade500,
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
      },
    );
  }
}
