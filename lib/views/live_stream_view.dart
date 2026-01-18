import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/live_stream_service.dart';
import '../controllers/dashboard_controller.dart';
import '../utils/colors.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LiveStreamView extends StatelessWidget {
  const LiveStreamView({super.key});

  @override
  Widget build(BuildContext context) {
    // Service'i register et
    final controller = Get.put(LiveStreamService());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, controller),
      body: Obx(() {
        if (controller.isLoading.value && controller.streams.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.error.value.isNotEmpty && controller.streams.isEmpty) {
          return _buildErrorState(controller);
        }

        if (controller.streams.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.refresh(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.streams.length,
            itemBuilder: (context, index) {
              final stream = controller.streams[index];
              return _LiveStreamCard(stream: stream);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              Icons.live_tv_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Şu an canlı yayın yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni canlı yayınlar eklendiğinde\nburada görünecek',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LiveStreamService controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            controller.error.value,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => controller.refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, LiveStreamService controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () {
          // Anasayfaya geri dön
          Get.back();
          final dashboardController = Get.find<DashboardController>();
          dashboardController.changeTabIndex(0);
        },
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFF4220B), size: 26),
      ),
      title: GestureDetector(
        onTap: () {
          // Logo'ya basınca anasayfaya git
          Get.back();
          final dashboardController = Get.find<DashboardController>();
          dashboardController.changeTabIndex(0);
        },
        child: Transform.translate(
          offset: const Offset(-30, 0),
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
      ),
      centerTitle: false,
      actions: [
        // Canlı Yayın Badge - Aktif sayfa
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam, color: Colors.white, size: 22),
              SizedBox(width: 4),
              Text(
                'CANLI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Yenile Butonu
        IconButton(
          onPressed: () => controller.refresh(),
          icon: Icon(
            Icons.refresh,
            color: isDark ? Colors.white : Colors.black87,
            size: 26,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _LiveStreamCard extends StatelessWidget {
  final LiveStream stream;

  const _LiveStreamCard({required this.stream});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openStream(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / Preview
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: stream.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: stream.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade800,
                              child: const Center(
                                child: Icon(
                                  Icons.live_tv,
                                  size: 48,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: Icon(
                                Icons.live_tv,
                                size: 48,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                  ),
                ),
                // Canlı Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'CANLI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Play Button Overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Stream Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Logo
                  if (stream.logoUrl != null && stream.logoUrl!.isNotEmpty)
                    Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: stream.logoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.tv, color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4220B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tv,
                        color: Color(0xFFF4220B),
                        size: 24,
                      ),
                    ),
                  // Title & Source
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stream.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (stream.sourceName != null &&
                            stream.sourceName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            stream.sourceName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStream() async {
    // 1. Kontrol: Eğer link YouTube linki ise Bizim Player'ı aç
    if (stream.url.contains('youtube.com') || stream.url.contains('youtu.be')) {
      Get.to(() => MyYoutubePlayer(url: stream.url));
    }
    // 2. Kontrol: YouTube değilse (m3u8 vb.) eski usül dışarıda aç
    else {
      final uri = Uri.parse(stream.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Hata',
          'Yayın açılamadı',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}

// 👇 class MyYoutubePlayer KISMINI KOMPLE BUNUNLA DEĞİŞTİR 👇

class MyYoutubePlayer extends StatefulWidget {
  final String url;
  const MyYoutubePlayer({super.key, required this.url});

  @override
  _MyYoutubePlayerState createState() => _MyYoutubePlayerState();
}

class _MyYoutubePlayerState extends State<MyYoutubePlayer> {
  late YoutubePlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayer.convertUrlToId(widget.url);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? "",
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        isLive: true,
        forceHD: true,
      ),
    );

    // Error handling via listener
    _controller.addListener(() {
      if (_controller.value.hasError && !_isError) {
        print("YouTube Hatası: ${_controller.value.errorCode}");
        _handleError();
      }
    });
  }

  // Hata alınca çalışacak fonksiyon
  void _handleError() async {
    if (_isError) return; // Zaten işlem yapılıyorsa dur
    setState(() => _isError = true);

    Get.snackbar(
      "Yayın Kısıtlaması",
      "Kanal sahibi bu yayını kısıtlamış. YouTube'da açılıyor...",
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // 1.5 saniye bekle kullanıcı mesajı okusun
    await Future.delayed(const Duration(milliseconds: 1500));

    // YouTube uygulamasını aç
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Bizim siyah ekranı kapat
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: _isError
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_clock, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "Yönlendiriliyor...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
                liveUIColor: Colors.red,
                onEnded: (meta) {
                  // Bazen hata yerine video bitmiş gibi davranır
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
