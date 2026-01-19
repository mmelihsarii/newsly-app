import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_model.dart';
import '../controllers/saved_controller.dart';
import '../controllers/reading_settings_controller.dart';
import '../utils/date_helper.dart';

class NewsDetailPage extends StatelessWidget {
  final NewsModel news;

  const NewsDetailPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final savedController = Get.find<SavedController>();
    final readingController = Get.find<ReadingSettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Font boyutu ayarlama butonu
          IconButton(
            icon: Icon(Icons.text_fields, color: isDark ? Colors.white : Colors.black),
            onPressed: () => _showFontSizeSheet(context, readingController),
            tooltip: 'Yazı Boyutu',
          ),
          IconButton(
            icon: Icon(Icons.share, color: isDark ? Colors.white : Colors.black),
            onPressed: () {
              print("Paylaş tıklandı");
            },
          ),
          // Kaydet Butonu
          Obx(() {
            final isSaved = savedController.isSaved(news);
            return IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? Colors.red : (isDark ? Colors.white : Colors.black),
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
            // 1. KAPAK RESMİ - Okuma modunda gizle
            Obx(() {
              if (readingController.isReadingMode.value) {
                return const SizedBox.shrink();
              }
              if (news.image == null || news.image!.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
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
              );
            }),

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

                  // 3. BAŞLIK - Font boyutuna göre
                  Obx(() => Text(
                    news.title ?? "Başlık Yok",
                    style: TextStyle(
                      fontSize: readingController.fontSize.value + 6,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                  )),
                  const SizedBox(height: 10),

                  // 4. KAYNAK VE TARİH
                  Row(
                    children: [
                      if (news.sourceName != null &&
                          news.sourceName!.isNotEmpty) ...[
                        Icon(
                          Icons.article_outlined,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            news.sourceName!,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        DateHelper.getTimeAgo(news.date),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 30,
                    thickness: 1,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),

                  // 5. İÇERİK
                  _buildContent(context, readingController, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReadingSettingsController readingController, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İçerik göster - Font boyutuna göre
        Obx(() {
          final fontSize = readingController.fontSize.value;
          final textColor = isDark ? Colors.white70 : Colors.black87;
          
          if (news.contentValue != null && news.contentValue!.trim().isNotEmpty) {
            return Html(
              data: news.contentValue!,
              style: {
                "body": Style(
                  fontSize: FontSize(fontSize),
                  lineHeight: const LineHeight(1.6),
                  color: textColor,
                ),
                "img": Style(
                  width: Width(100, Unit.percent),
                  height: Height.auto(),
                ),
                "p": Style(margin: Margins.only(bottom: 12)),
              },
            );
          } else if (news.description != null && news.description!.trim().isNotEmpty) {
            if (news.description!.contains('<') && news.description!.contains('>')) {
              return Html(
                data: news.description!,
                style: {
                  "body": Style(
                    fontSize: FontSize(fontSize),
                    lineHeight: const LineHeight(1.6),
                    color: textColor,
                  ),
                  "p": Style(margin: Margins.only(bottom: 12)),
                },
              );
            } else {
              return Text(
                DateHelper.stripHtml(news.description!),
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor,
                  height: 1.6,
                ),
              );
            }
          } else {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: isDark ? Colors.grey[400] : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu haber için detaylı içerik mevcut değil.',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }),

        // Devamını Gör Butonu
        if (news.sourceUrl != null && news.sourceUrl!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildReadMoreButton(),
        ],
      ],
    );
  }

  /// Font boyutu ayarlama bottom sheet
  void _showFontSizeSheet(BuildContext context, ReadingSettingsController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Başlık
            Text(
              'Okuma Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            
            // Font boyutu kontrolü
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Küçült butonu
                IconButton(
                  onPressed: controller.decreaseFontSize,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.text_decrease,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                
                // Font boyutu göstergesi
                Obx(() => Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${controller.fontSize.value.toInt()}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        controller.fontSizeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
                
                // Büyüt butonu
                IconButton(
                  onPressed: controller.increaseFontSize,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.text_increase,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Okuma modu toggle
            Obx(() => SwitchListTile(
              title: Text(
                'Okuma Modu',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              subtitle: Text(
                'Resimleri gizle, sadece metin göster',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              value: controller.isReadingMode.value,
              onChanged: (_) => controller.toggleReadingMode(),
              activeColor: Colors.redAccent,
            )),
            
            const SizedBox(height: 12),
            
            // Sıfırla butonu
            TextButton(
              onPressed: () {
                controller.resetFontSize();
                if (controller.isReadingMode.value) {
                  controller.toggleReadingMode();
                }
              },
              child: const Text(
                'Varsayılana Sıfırla',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildReadMoreButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () => _openOriginalSource(),
        icon: const Icon(Icons.open_in_new, size: 20),
        label: const Text(
          'Devamını Gör',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF4220B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Future<void> _openOriginalSource() async {
    if (news.sourceUrl == null || news.sourceUrl!.isEmpty) {
      Get.snackbar(
        'Hata',
        'Haber kaynağı bulunamadı',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final url = Uri.parse(news.sourceUrl!);

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Link açılamadı',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Link açılırken bir hata oluştu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
