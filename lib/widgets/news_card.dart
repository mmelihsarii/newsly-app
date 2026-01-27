import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_model.dart';
import '../controllers/saved_controller.dart';
import '../controllers/reading_settings_controller.dart';
import '../utils/colors.dart';
import '../utils/date_helper.dart';
import '../utils/source_logos.dart';

/// Kategori adına göre renk döndür
Color getCategoryColor(String? categoryName) {
  if (categoryName == null || categoryName.isEmpty) return const Color(0xFF64748B);
  
  final name = categoryName.toLowerCase();
  
  // Gündem & Son Dakika - Red
  if (name.contains('gündem') || name.contains('son dakika') || name.contains('breaking')) {
    return const Color(0xFFEF4444);
  }
  
  // Spor - Green
  if (name.contains('spor') || name.contains('sport')) {
    return const Color(0xFF22C55E);
  }
  
  // Ekonomi & Finans - Orange/Amber
  if (name.contains('ekonomi') || name.contains('finans') || name.contains('economy') || name.contains('finance')) {
    return const Color(0xFFF59E0B);
  }
  
  // Bilim & Teknoloji - Indigo/Purple
  if (name.contains('teknoloji') || name.contains('bilim') || name.contains('tech') || name.contains('science')) {
    return const Color(0xFF6366F1);
  }
  
  // Yabancı Kaynaklar & Dünya - Purple
  if (name.contains('yabancı') || name.contains('dünya') || name.contains('world') || name.contains('international')) {
    return const Color(0xFF8B5CF6);
  }
  
  // Haber Ajansları - Cyan/Sky Blue
  if (name.contains('ajans') || name.contains('agency')) {
    return const Color(0xFF0EA5E9);
  }
  
  // Yerel Haberler - Teal
  if (name.contains('yerel') || name.contains('local')) {
    return const Color(0xFF14B8A6);
  }
  
  // Magazin & Yaşam - Pink
  if (name.contains('magazin') || name.contains('yaşam') || name.contains('lifestyle') || name.contains('entertainment')) {
    return const Color(0xFFEC4899);
  }
  
  // Sağlık - Green variant
  if (name.contains('sağlık') || name.contains('health')) {
    return const Color(0xFF10B981);
  }
  
  // Kültür & Sanat - Violet
  if (name.contains('kültür') || name.contains('sanat') || name.contains('culture') || name.contains('art')) {
    return const Color(0xFF7C3AED);
  }
  
  // Eğitim - Blue
  if (name.contains('eğitim') || name.contains('education')) {
    return const Color(0xFF3B82F6);
  }
  
  // Otomotiv - Gray (ama koyu gri değil)
  if (name.contains('otomotiv') || name.contains('auto')) {
    return const Color(0xFF6B7280);
  }
  
  // Default - Slate Blue
  return const Color(0xFF64748B);
}

class NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback onTap;

  const NewsCard({super.key, required this.news, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = news.image != null && news.image!.isNotEmpty;
    final readingController = Get.find<ReadingSettingsController>();

    return GestureDetector(
      onTap: onTap,
      child: Obx(() {
        final hideImages = readingController.hideImages.value;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2F47) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Haber Resmi - hideImages açıksa gösterme
              if (!hideImages)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: news.image!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              memCacheWidth: 600,
                              memCacheHeight: 400,
                              fadeInDuration: const Duration(milliseconds: 200),
                              fadeOutDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => _buildPlaceholder(isDark),
                              errorWidget: (context, url, error) => _buildSourceLogo(isDark),
                            )
                          : _buildSourceLogo(isDark),
                    ),
                    // Kaydet Butonu
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Obx(() {
                        final savedController = Get.find<SavedController>();
                        final isSaved = savedController.isSaved(news);
                        return GestureDetector(
                          onTap: () => savedController.toggleSave(news),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSaved ? Colors.white : Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? Colors.red : Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              // Başlık ve Detaylar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Görseller gizliyken kaydet butonu burada göster
                    if (hideImages)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (news.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                news.categoryName!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Obx(() {
                            final savedController = Get.find<SavedController>();
                            final isSaved = savedController.isSaved(news);
                            return GestureDetector(
                              onTap: () => savedController.toggleSave(news),
                              child: Icon(
                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: isSaved ? Colors.red : (isDark ? Colors.white54 : Colors.grey),
                                size: 22,
                              ),
                            );
                          }),
                        ],
                      )
                    else if (news.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          news.categoryName!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      news.title ?? "Başlıksız Haber",
                      maxLines: hideImages ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (news.sourceName != null && news.sourceName!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: getCategoryColor(news.categoryName).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              news.sourceName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: getCategoryColor(news.categoryName),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.access_time, size: 14, color: isDark ? Colors.white54 : Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateHelper.getTimeAgo(news.publishedAt ?? news.date),
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                        ),
                      ],
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

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      height: 200,
      color: isDark ? const Color(0xFF132440) : Colors.grey[200],
    );
  }

  /// Görsel yoksa Firebase Storage'dan kaynak logosu göster
  Widget _buildSourceLogo(bool isDark) {
    final logoUrls = SourceLogos.getLogoUrlVariants(news.sourceName);
    final categoryColor = getCategoryColor(news.categoryName);
    
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withOpacity(0.8),
            categoryColor.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildLogoWithFallbacks(logoUrls, 76),
        ),
      ),
    );
  }
  
  /// Birden fazla URL deneyen logo widget'ı
  Widget _buildLogoWithFallbacks(List<String> urls, double size) {
    if (urls.isEmpty) {
      return Center(
        child: Icon(
          Icons.newspaper,
          size: size * 0.5,
          color: getCategoryColor(news.categoryName),
        ),
      );
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
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) {
        if (urls.length > 1) {
          return _buildLogoWithFallbacks(urls.sublist(1), size);
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
}
