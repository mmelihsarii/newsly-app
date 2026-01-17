import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_model.dart';
import '../controllers/saved_controller.dart';

class NewsDetailPage extends StatelessWidget {
  final NewsModel news;

  const NewsDetailPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final savedController = Get.find<SavedController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              print("Paylaş tıklandı");
            },
          ),
          // Kaydet Butonu - SavedController ile entegre
          Obx(() {
            final isSaved = savedController.isSaved(news);
            return IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? Colors.red : Colors.black,
              ),
              onPressed: () => savedController.toggleSave(news),
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KAPAK RESMİ
            if (news.image != null && news.image!.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: news.image!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. KATEGORİ ETİKETİ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      news.categoryName ?? "Haber",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. BAŞLIK
                  Text(
                    news.title ?? "Başlık Yok",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. TARİH VE SAAT
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        news.date ?? "",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),

                  // 5. İÇERİK - Önce HTML içerik, yoksa description göster
                  _buildContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Eğer contentValue varsa ve doluysa HTML olarak göster
    if (news.contentValue != null && news.contentValue!.trim().isNotEmpty) {
      return Html(
        data: news.contentValue!,
        style: {
          "body": Style(
            fontSize: FontSize(16.0),
            lineHeight: const LineHeight(1.6),
            color: Colors.black87,
          ),
          "img": Style(width: Width(100, Unit.percent), height: Height.auto()),
          "p": Style(margin: Margins.only(bottom: 12)),
        },
      );
    }

    // contentValue yoksa description'ı göster
    if (news.description != null && news.description!.trim().isNotEmpty) {
      return Text(
        news.description!,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.6,
        ),
      );
    }

    // Her ikisi de yoksa bilgi mesajı
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu haber için detaylı içerik mevcut değil.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
