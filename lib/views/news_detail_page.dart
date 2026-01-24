import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/news_model.dart';
import '../controllers/saved_controller.dart';
import '../controllers/reading_settings_controller.dart';
import '../utils/date_helper.dart';
import '../services/analytics_service.dart';

class NewsDetailPage extends StatefulWidget {
  final NewsModel news;

  const NewsDetailPage({super.key, required this.news});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  @override
  void initState() {
    super.initState();
    // Analytics: Haber okundu
    AnalyticsService().logNewsRead(
      newsId: widget.news.id ?? '',
      newsTitle: widget.news.title ?? '',
      category: widget.news.categoryName ?? '',
      source: widget.news.sourceName ?? '',
    );
    AnalyticsService().logScreenView(screenName: 'news_detail');
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
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
            onPressed: () => _shareNews(),
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
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
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
                    
                    // Alt boşluk - navigation bar için
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
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
      child: OutlinedButton.icon(
        onPressed: () => _openOriginalSource(),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: const Text(
          'Devamını Gör',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF4220B),
          side: const BorderSide(color: Color(0xFFF4220B), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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

    // Tam ekran WebView sayfası aç
    Get.to(
      () => _WebViewFullScreen(
        url: news.sourceUrl!,
        sourceName: news.sourceName ?? 'Kaynak',
      ),
      transition: Transition.rightToLeft,
    );
  }

  /// Haberi paylaş - Linki panoya kopyala ve bildirim göster
  Future<void> _shareNews() async {
    final title = news.title ?? 'Haber';
    final url = news.sourceUrl ?? '';
    
    String shareText = title;
    if (url.isNotEmpty) {
      shareText = '$title\n$url';
    }
    
    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      Get.snackbar(
        'Kopyalandı',
        'Haber linki panoya kopyalandı',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Kopyalama yapılamadı',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

/// WebView Modal Bottom Sheet Widget
class _WebViewBottomSheet extends StatefulWidget {
  final String url;
  final String sourceName;

  const _WebViewBottomSheet({
    required this.url,
    required this.sourceName,
  });

  @override
  State<_WebViewBottomSheet> createState() => _WebViewBottomSheetState();
}

class _WebViewBottomSheetState extends State<_WebViewBottomSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Sayfa yüklenemedi';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Bottom bar yüksekliği (yaklaşık 56-80px) + safe area
    final bottomBarHeight = 80 + bottomPadding;
    final webViewHeight = screenHeight - bottomBarHeight;

    return Container(
      height: webViewHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(isDark),
          
          // Loading indicator
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress / 100,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF4220B)),
            ),
          
          // WebView veya Error
          Expanded(
            child: _errorMessage != null
                ? _buildErrorWidget(isDark)
                : ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
                    child: WebViewWidget(controller: _controller),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title bar
          Row(
            children: [
              // Kapat butonu
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.white : Colors.black,
                ),
                tooltip: 'Kapat',
              ),
              
              // Kaynak adı ve URL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sourceName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getDomain(widget.url),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Yenile butonu
              IconButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _controller.reload();
                },
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white : Colors.black,
                ),
                tooltip: 'Yenile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Bir hata oluştu',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _controller.reload();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF4220B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }
}


/// Tam Ekran WebView Sayfası
class _WebViewFullScreen extends StatefulWidget {
  final String url;
  final String sourceName;

  const _WebViewFullScreen({
    required this.url,
    required this.sourceName,
  });

  @override
  State<_WebViewFullScreen> createState() => _WebViewFullScreenState();
}

class _WebViewFullScreenState extends State<_WebViewFullScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Sayfa yüklenemedi';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sourceName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _getDomain(widget.url),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Yenile butonu
          IconButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _controller.reload();
            },
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : Colors.black,
            ),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: SafeArea(
        top: false, // AppBar zaten üstte
        bottom: true, // Alt kısımda safe area - çerez banner'ı için
        child: Column(
          children: [
            // Loading indicator
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadingProgress / 100,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF4220B)),
                minHeight: 3,
              ),
            
            // WebView - SafeArea içinde
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorWidget(isDark)
                  : WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Bir hata oluştu',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _controller.reload();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF4220B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }
}
