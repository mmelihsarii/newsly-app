import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import '../models/news_model.dart';
import '../models/source_model.dart';
import '../controllers/saved_controller.dart';
import '../controllers/source_selection_controller.dart';
import '../controllers/reading_settings_controller.dart';
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
  final List<NewsModel> _allNews = []; // Tüm haberler
  final List<NewsModel> _displayedNews = []; // Gösterilen haberler
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  bool _isFollowing = false; // Takip durumu
  
  // Pagination
  static const int _pageSize = 10;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkFollowStatus();
    _fetchNews();
  }
  
  /// Takip durumunu kontrol et
  void _checkFollowStatus() {
    if (Get.isRegistered<SourceSelectionController>()) {
      final controller = Get.find<SourceSelectionController>();
      setState(() {
        _isFollowing = controller.isSourceSelected(widget.source.name) ||
                       controller.isSourceSelected(widget.source.id);
      });
    }
  }
  
  /// Takipten çık
  Future<void> _unfollowSource() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Takipten Çık'),
        content: Text('${widget.source.name} kaynağını takipten çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Takipten Çık'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && Get.isRegistered<SourceSelectionController>()) {
      final controller = Get.find<SourceSelectionController>();
      
      // Kaynağı kaldır
      controller.tempSelectedSources.remove(widget.source.name);
      controller.tempSelectedSources.remove(widget.source.id);
      
      // Kaydet
      await controller.saveAllChanges();
      
      setState(() => _isFollowing = false);
      
      Get.snackbar(
        'Takipten Çıkıldı',
        '${widget.source.name} artık takip edilmiyor',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Sona yaklaşınca daha fazla yükle
    if (currentScroll >= maxScroll - 100) {
      _loadMore();
    }
  }
  
  void _loadMore() {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    final currentCount = _displayedNews.length;
    final newCount = currentCount + _pageSize;
    final actualCount = newCount > _allNews.length ? _allNews.length : newCount;
    
    setState(() {
      _displayedNews.addAll(_allNews.sublist(currentCount, actualCount));
      _hasMore = actualCount < _allNews.length;
      _isLoadingMore = false;
    });
    
    print('📰 Kaynak profil: +$_pageSize haber, toplam ${_displayedNews.length}/${_allNews.length}');
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
      
      // Kronolojik sıralama - en yeni en üstte
      news.sort((a, b) {
        final dateA = a.publishedAt;
        final dateB = b.publishedAt;
        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA); // Descending
        }
        if (dateA != null) return -1;
        if (dateB != null) return 1;
        return 0;
      });
      
      setState(() {
        _allNews.clear();
        _allNews.addAll(news);
        
        // İlk sayfa
        _displayedNews.clear();
        final initialCount = news.length < _pageSize ? news.length : _pageSize;
        _displayedNews.addAll(news.take(initialCount));
        _hasMore = news.length > _pageSize;
        
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
    if (url.isEmpty) {
      print('⚠️ RSS URL boş: $sourceName');
      return [];
    }
    
    print('📡 RSS çekiliyor: $sourceName - $url');
    
    List<NewsModel> newsList = [];
    try {
      // HttpClient kullan - bazı sunucular bozuk Content-Type header'ı gönderiyor
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      client.autoUncompress = true; // Gzip desteği
      
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true; // Redirect'leri takip et
      request.maxRedirects = 5;
      request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36');
      request.headers.set('Accept', 'application/rss+xml, application/xml, text/xml, */*');
      
      final response = await request.close().timeout(const Duration(seconds: 15));
      
      print('📥 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Response body'yi oku
        final bytes = await response.fold<List<int>>(
          <int>[],
          (List<int> previous, List<int> element) => previous..addAll(element),
        );
        
        print('📥 ${bytes.length} bytes alındı');
        
        // UTF-8 encoding düzeltmesi
        String body = _fixEncoding('', bytes);
        
        // Debug: İlk 500 karakteri logla
        print('📄 RSS içeriği (ilk 500): ${body.substring(0, body.length > 500 ? 500 : body.length)}');
        
        final document = XmlDocument.parse(body);
        
        // Hem <item> (RSS) hem <entry> (Atom) formatını destekle
        // Namespace'li ve namespace'siz elementleri ara
        var items = document.findAllElements('item');
        if (items.isEmpty) {
          items = document.findAllElements('entry');
        }
        // Namespace ile de dene (Atom feed'leri için)
        if (items.isEmpty) {
          final root = document.rootElement;
          final entries = root.childElements.where((e) => 
            e.name.local == 'entry' || e.name.local == 'item'
          );
          if (entries.isNotEmpty) {
            items = entries;
          }
        }
        
        print('📰 ${sourceName}: ${items.length} haber bulundu');

        for (var item in items) {
          String? title = item.findElements('title').singleOrNull?.innerText;
          
          // Description - RSS: description, Atom: summary veya content
          String? description = item.findElements('description').singleOrNull?.innerText;
          if (description == null || description.isEmpty) {
            description = item.findElements('summary').singleOrNull?.innerText;
          }
          if (description == null || description.isEmpty) {
            description = item.findElements('content').singleOrNull?.innerText;
          }
          
          // Link - RSS: link içeriği, Atom: link href attribute
          String? link = item.findElements('link').singleOrNull?.innerText;
          if (link == null || link.isEmpty) {
            final linkElement = item.findElements('link').firstOrNull;
            link = linkElement?.getAttribute('href');
          }
          
          // PubDate - RSS: pubDate, Atom: published veya updated
          String? pubDateStr = item.findElements('pubDate').singleOrNull?.innerText;
          if (pubDateStr == null || pubDateStr.isEmpty) {
            pubDateStr = item.findElements('published').singleOrNull?.innerText;
          }
          if (pubDateStr == null || pubDateStr.isEmpty) {
            pubDateStr = item.findElements('updated').singleOrNull?.innerText;
          }

          // Encoding düzeltmesi uygula
          title = _fixTurkishText(title);
          description = _fixTurkishText(description);

          String? imageUrl = _extractImage(item, description);

          DateTime? publishedAt;
          String formattedDate = '';

          if (pubDateStr != null && pubDateStr.isNotEmpty) {
            publishedAt = _parseRssDate(pubDateStr);
            if (publishedAt != null) {
              // Türkçe locale ile formatla
              try {
                formattedDate = DateFormat('dd MMM HH:mm', 'tr_TR').format(publishedAt);
              } catch (_) {
                formattedDate = '${publishedAt.day}/${publishedAt.month} ${publishedAt.hour}:${publishedAt.minute.toString().padLeft(2, '0')}';
              }
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
      } else {
        print('❌ HTTP Hata: ${response.statusCode} - $sourceName');
      }
      
      client.close();
    } catch (e) {
      print('❌ RSS çekme hatası ($sourceName): $e');
    }
    
    print('✅ $sourceName: ${newsList.length} haber parse edildi');
    return newsList;
  }
  
  /// Response encoding'ini düzelt
  String _fixEncoding(String body, List<int> bodyBytes) {
    // Önce bytes'tan UTF-8 decode dene
    if (bodyBytes.isNotEmpty) {
      try {
        return utf8.decode(bodyBytes, allowMalformed: true);
      } catch (_) {}
    }
    return body;
  }
  
  /// Türkçe metin düzeltme
  String? _fixTurkishText(String? text) {
    if (text == null || text.isEmpty) return text;
    
    String fixed = text;
    
    // HTML tag'larını temizle
    fixed = fixed.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // UTF-8 double encoding düzeltmeleri
    final fixes = {
      'Ä±': 'ı', 'Ä°': 'İ', 'ÄŸ': 'ğ', 'Ä': 'Ğ',
      'Ã¼': 'ü', 'Ãœ': 'Ü', 'ÅŸ': 'ş', 'Å': 'Ş',
      'Ã¶': 'ö', 'Ã–': 'Ö', 'Ã§': 'ç', 'Ã‡': 'Ç',
      'Ã¢': 'â', 'Ã®': 'î', 'Ã»': 'û',
      // Byte sequence düzeltmeleri
      '\u00C4\u00B1': 'ı', '\u00C4\u009F': 'ğ', '\u00C5\u009F': 'ş',
      '\u00C4\u00B0': 'İ', '\u00C4\u009E': 'Ğ', '\u00C5\u009E': 'Ş',
      '\u00C3\u00B6': 'ö', '\u00C3\u00BC': 'ü', '\u00C3\u00A7': 'ç',
      '\u00C3\u0096': 'Ö', '\u00C3\u009C': 'Ü', '\u00C3\u0087': 'Ç',
      // Windows-1254
      'Ý': 'İ', 'ý': 'ı', 'Þ': 'Ş', 'þ': 'ş', 'Ð': 'Ğ', 'ð': 'ğ',
      // HTML entities
      '&amp;': '&', '&apos;': "'", '&quot;': '"', '&lt;': '<', '&gt;': '>',
      '&#305;': 'ı', '&#304;': 'İ', '&#287;': 'ğ', '&#286;': 'Ğ',
      '&#252;': 'ü', '&#220;': 'Ü', '&#351;': 'ş', '&#350;': 'Ş',
      '&#246;': 'ö', '&#214;': 'Ö', '&#231;': 'ç', '&#199;': 'Ç',
      '&#39;': "'", '&nbsp;': ' ',
    };
    
    fixes.forEach((wrong, correct) {
      fixed = fixed.replaceAll(wrong, correct);
    });
    
    // Kalan bozuk pattern'leri regex ile düzelt
    fixed = fixed.replaceAllMapped(
      RegExp(r'[\u00C0-\u00C5]([\u0080-\u00BF])'),
      (match) {
        final c1 = match.group(0)!.codeUnitAt(0);
        final c2 = match.group(1)!.codeUnitAt(0);
        final codePoint = ((c1 & 0x1F) << 6) | (c2 & 0x3F);
        return String.fromCharCode(codePoint);
      },
    );
    
    // Kontrol karakterlerini temizle
    fixed = fixed.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '');
    
    // CDATA temizle
    fixed = fixed.replaceAll(RegExp(r'<!\[CDATA\['), '');
    fixed = fixed.replaceAll(RegExp(r'\]\]>'), '');
    
    // Fazla boşlukları temizle
    fixed = fixed.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return fixed;
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
      // Türkçe karakterler için genişletilmiş regex
      final rfc822Regex = RegExp(
        r'([a-zA-ZğüşöçıİĞÜŞÖÇ]+),?\s+(\d{1,2})\s+([a-zA-ZğüşöçıİĞÜŞÖÇ]+)\s+(\d{4})\s+(\d{2}):(\d{2}):?(\d{2})?\s*([\+\-]?\d{4}|GMT|UTC)?',
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
      // İngilizce
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      // Türkçe
      'oca': 1, 'ocak': 1, 'şub': 2, 'şubat': 2, 'mart': 3,
      'nis': 4, 'nisan': 4, 'mayıs': 5, 'haz': 6, 'haziran': 6,
      'tem': 7, 'temmuz': 7, 'ağu': 8, 'ağustos': 8,
      'eyl': 9, 'eylül': 9, 'eki': 10, 'ekim': 10,
      'kas': 11, 'kasım': 11, 'ara': 12, 'aralık': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        controller: _scrollController,
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
            actions: [
              // Takipten Çık butonu
              if (_isFollowing)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: _unfollowSource,
                    icon: const Icon(Icons.person_remove, color: Colors.white, size: 20),
                    label: const Text(
                      'Takipten Çık',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
            ],
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
                    _isLoading ? 'Yükleniyor...' : '${_displayedNews.length}/${_allNews.length} Haber',
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
          else if (_displayedNews.isEmpty)
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
          else ...[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildNewsCard(_displayedNews[index], isDark),
                childCount: _displayedNews.length,
              ),
            ),
            // Loading more indicator
            if (_isLoadingMore || _hasMore)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: _isLoadingMore
                      ? const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)
                      : _hasMore
                          ? Text(
                              'Daha fazla haber için kaydırın',
                              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewsCard(NewsModel news, bool isDark) {
    final savedController = Get.find<SavedController>();
    final readingController = Get.find<ReadingSettingsController>();

    return GestureDetector(
      onTap: () => Get.to(() => NewsDetailPage(news: news)),
      child: Obx(() {
        final hideImages = readingController.hideImages.value;
        
        return Container(
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
              if (!hideImages && news.image != null && news.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: news.image!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    memCacheHeight: 320,
                    fadeInDuration: const Duration(milliseconds: 200),
                    fadeOutDuration: const Duration(milliseconds: 200),
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: isDark ? const Color(0xFF132440) : Colors.grey.shade200,
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
                      maxLines: hideImages ? 3 : 2,
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
                        if (news.date != null || news.publishedAt != null)
                          Text(
                            DateHelper.getTimeAgo(news.publishedAt ?? news.date),
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
        );
      }),
    );
  }
}
