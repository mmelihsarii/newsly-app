import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/shared_app_bar.dart';
import '../../widgets/news_card.dart';
import '../../controllers/follow_controller.dart';
import '../../controllers/interest_controller.dart';
import '../news_detail_page.dart';
import '../interest_view.dart';

class FollowView extends StatelessWidget {
  const FollowView({super.key});

  @override
  Widget build(BuildContext context) {
    // InterestController'ı önce register et
    Get.put(InterestController());
    final FollowController controller = Get.put(FollowController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const SharedAppBar(),
      body: Obx(() {
        // Takip edilen bir şey yoksa
        if (!controller.hasFollowedItems) {
          return _buildEmptyState();
        }

        // Yükleniyor
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF1E3A5F)),
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
        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchFollowedNews(),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        // Haber listesi boşsa
        if (controller.newsList.isEmpty) {
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
                  'Takip ettiğiniz kaynaklardan haber yok',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.fetchFollowedNews(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                ),
              ],
            ),
          );
        }

        // Haber listesi
        return RefreshIndicator(
          onRefresh: () => controller.fetchFollowedNews(),
          color: const Color(0xFF1E3A5F),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.newsList.length,
            itemBuilder: (context, index) {
              final news = controller.newsList[index];
              return NewsCard(
                news: news,
                onTap: () => Get.to(() => NewsDetailPage(news: news)),
              );
            },
          ),
        );
      }),
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
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_outlined,
                size: 64,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Takip Edilenler',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Henüz bir şehir veya kategori takip etmiyorsunuz.\nİlgi alanlarınızı seçerek haberleri burada görün.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const InterestView()),
              icon: const Icon(Icons.add),
              label: const Text('İlgi Alanlarını Seç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
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
}
