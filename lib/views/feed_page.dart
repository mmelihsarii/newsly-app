import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../models/news_model.dart';
import '../views/news_detail_page.dart'; // Detay sayfası importu
import '../utils/colors.dart';
import '../utils/date_helper.dart';
import '../utils/news_sources_data.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  // Belçika sunucusu için özel instance
  final DatabaseReference _databaseRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://newsly-70ef9-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref("news");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Haber Akışı",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder(
        stream: _databaseRef.orderByChild("timestamp").onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Henüz haber yok."));
          }

          // Veriyi işle
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          // Listeye çevir ve modelle eşle
          List<NewsModel> newsList = [];
          data.forEach((key, value) {
            final newsMap = Map<dynamic, dynamic>.from(value);
            newsMap['id'] = key; // ID'yi ekle
            newsList.add(NewsModel.fromMap(newsMap));
          });

          // Timestamp'e göre sırala (Yeniden eskiye)
          // Not: Firebase zaten sıralı gönderir ama Map sırasız olabilir,
          // bu yüzden client tarafında ters çevirmek en garantisidir.
          newsList.sort((a, b) {
            // Eğer modelinizde timestamp alanı varsa ona göre yapın,
            // yoksa listeyi ters çevireceğiz çünkü orderByChild küçükten büyüğe verir.
            return 0;
          });

          // orderByChild ascending (eskiden yeniye) verir, biz en yeniyi (sondakini)
          // en üstte istiyoruz.
          final reversedList = newsList.reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reversedList.length,
            itemBuilder: (context, index) {
              final news = reversedList[index];
              return _buildNewsCard(news);
            },
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(NewsModel news) {
    return GestureDetector(
      onTap: () {
        Get.to(() => NewsDetailPage(news: news));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim Alanı
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: news.image ?? "",
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            // İçerik Alanı
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Text(
                    news.title ?? "Başlıksız Haber",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Açıklama
                  Text(
                    news.description ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),

                  // Tarih ve Kaynak Bilgi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Kaynak adı
                          if (news.sourceName != null &&
                              news.sourceName!.isNotEmpty) ...[
                            Builder(
                              builder: (context) {
                                final sourceColor = getSourceCategoryColor(news.sourceName);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.article_outlined,
                                      size: 14,
                                      color: sourceColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      news.sourceName!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: sourceColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '•',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Tarih
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateHelper.getTimeAgo(news.publishedAt ?? news.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.primary,
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
  }
}
