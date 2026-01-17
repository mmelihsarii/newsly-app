import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MyYoutubePlayer extends StatefulWidget {
  final String url;
  const MyYoutubePlayer({Key? key, required this.url}) : super(key: key);

  @override
  _MyYoutubePlayerState createState() => _MyYoutubePlayerState();
}

class _MyYoutubePlayerState extends State<MyYoutubePlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Linkten Video ID'sini çekiyoruz
    String? videoId = YoutubePlayer.convertUrlToId(widget.url);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? "",
      flags: const YoutubePlayerFlags(
        autoPlay: true, // Otomatik başlasın
        mute: false,
        isLive: true, // Canlı yayın modunu açıyoruz
        forceHD: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sinema modu için siyah arka plan
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Şeffaf üst bar
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Geri butonu beyaz
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          liveUIColor: Colors.red, // Canlı yazısı rengi
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
