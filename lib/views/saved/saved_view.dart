import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/shared_app_bar.dart';
import '../../widgets/news_card.dart';
import '../../controllers/saved_controller.dart';
import '../news_detail_page.dart';

class SavedView extends StatelessWidget {
  const SavedView({super.key});

  @override
  Widget build(BuildContext context) {
    final SavedController controller = Get.find<SavedController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const SharedAppBar(),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kaydedilenler',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kaydettiğiniz haberler burada görünecek.\nHaberlerdeki kaydet butonuna tıklayarak\nfavori haberlerinizi saklayabilirsiniz.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
