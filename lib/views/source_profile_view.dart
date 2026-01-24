import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import '../models/news_model.dart';
import '../models/source_model.dart';
import '../controllers/saved_controller.dart';
import '../utils/colors.dart';
import '../utils/date_helper.dart';
import 'news_detail_page.dart';

class SourceProfileView extends StatefulWidget {
  final SourceModel source;

  const SourceProfileView({super.key, required this.source});

  @override
  State<SourceProfileView> createState() => _SourceProfileViewState();
}

class _SourceProfileViewState extends State<SourceProfileView> {
  final List<NewsModel> _newsList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final news = await _fetchRssFeed(
        widget.source.rssUrl,
        widget.source.name,
        widget.source.category,
      );
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

  Future<List<NewsModel>> _fetchRssFeed(String url, String sourceName, String categoryName) async {
    if (url.isEmpty) return [];
    
    List<NewsModel> newsList = [];
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item').take(30);

        for (var item in items) {
          final title = item.findElements('title').singleOrNull?.innerText;
          final description = item.findElements('description').singleOrNull?.innerText;
          final link = item.findElements('link').singleOrNull?.innerText;
          final pubDateStr = item.findElements('pubDate').singleOrNull?.innerText;

          String? imageUrl = _extractImage(item, description);

          DateTime? publishedAt;
          String formattedDate = '';

          if (pubDateStr != null && pubDateStr.isNotEmpty) {
            publishedAt = _parseRssDate(pubDateStr);
            if (publishedAt != null) {
              formattedDate = DateFormat('dd MMM HH:mm').format(publishedAt);
            } else {
              formattedDate = pubDateStr;
            }
          }

          newsList.add(NewsModel(
            title: title,
            description: description,
            date: formattedDate,
            sourceUrl: link,
            sourceName: sourceName,
            image: imageUrl,
            categoryName: categoryName,
            publishedAt: publishedAt,
          ));
        }
      }
    } catch (e) {
      print('RSS çekme hatası: $e');
    }
    return newsList;
  }

  String? _extractImage(XmlElement item, String? description) {
    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      final url = enclosure.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    final mediaContent = item.findElements('media:content').firstOrNull;
    if (mediaContent != null) {
      final url = mediaContent.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
    if (mediaThumbnail != null) {
      final url = mediaThumbnail.getAttribute('url');
      if (url != null && url.isNotEmpty) return url;
    }

    if (description != null) {
      final imgRegex = RegExp(r'<img[^>]+src="([^"]+)"');
      final match = imgRegex.firstMatch(description);
      if (match != null) return match.group(1);
    }

    return null;
  }

  DateTime? _parseRssDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try { return DateTime.parse(dateStr); } catch (_) {}
    try {
      final rfc822Regex = RegExp(
        r'(\w+),?\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+(\d{2}):(\d{2}):?(\d{2})?\s*([\+\-]?\d{4}|GMT|UTC)?',
        caseSensitive: false,
      );
      final match = rfc822Regex.firstMatch(dateStr);
      if (match != null) {
        final day = int.parse(match.group(2)!);
        final monthStr = match.group(3)!;
        final year = int.parse(match.group(4)!);
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final second = match.group(7) != null ? int.parse(match.group(7)!) : 0;
        final month = _monthToNumber(monthStr);
        return DateTime.utc(year, month, day, hour, minute, second);
      }
    } catch (_) {}
    return null;
  }

  int _monthToNumber(String month) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Source Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.source.name.isNotEmpty 
                                ? widget.source.name[0].toUpperCase() 
                                : '?',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Source Name
                      Text(
                        widget.source.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.source.category,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // News Count
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.article_outlined, color: isDark ? Colors.white70 : Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    _isLoading ? 'Yükleniyor...' : '${_newsList.length} Haber',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    IconButton(
                      onPressed: _fetchNews,
                      icon: Icon(Icons.refresh, color: AppColors.primary),
                    ),
                ],
              ),
            ),
          ),
          // News List
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_errorMessage.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchNews,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          else if (_newsList.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Haber bulunamadı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildNewsCard(_newsList[index], isDark),
                childCount: _newsList.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsModel news, bool isDark) {
    final savedController = Get.find<SavedController>();

    return GestureDetector(
      onTap: () => Get.to(() => NewsDetailPage(news: news)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2F47) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.image != null && news.image!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: news.image!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: isDark ? const Color(0xFF132440) : Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 160,
                    color: isDark ? const Color(0xFF132440) : Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                  ),
                ),
              ),
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
                  if (news.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      DateHelper.stripHtml(news.description!),
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (news.date != null)
                        Text(
                          DateHelper.getTimeAgo(news.date),
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500, fontSize: 12),
                        ),
                      const Spacer(),
                      Obx(() {
                        final isSaved = savedController.isSaved(news);
                        return GestureDetector(
                          onTap: () => savedController.toggleSave(news),
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? Colors.red : (isDark ? Colors.white38 : Colors.grey.shade400),
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
  }
}
