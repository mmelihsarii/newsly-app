import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'image':
          'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800',
      'title': 'En güncel\nhaberlere\nulaşın.',
      'highlight': 'güncel',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=800',
      'title': 'Dünyanın\nher yerinden\nhaberler.',
      'highlight': 'her yerinden',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800',
      'title': 'Sanattan\nspor\'a her\nkategori.',
      'highlight': 'her',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1529107386315-e1a2ed48a620?w=800',
      'title': 'Newsly ile\nhaberler artık\navucunuzda.',
      'highlight': 'avucunuzda',
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Son sayfada - Login ekranına git
      Get.to(() => LoginView());
    }
  }

  void _skip() {
    Get.to(() => LoginView());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Logo ve Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // SVG Logo
                  SizedBox(
                    height: 28,
                    width: 100,
                    child: SvgPicture.asset(
                      'assets/logo.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFF4220B),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  // Skip Button
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'Geç',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildPage(_onboardingData[index]);
                },
              ),
            ),
            // Dots Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFFF4220B)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4220B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _onboardingData.length - 1
                        ? 'Giriş Yap'
                        : 'İlerle',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, String> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arka plan görseli
              Image.network(
                data['image']!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color.fromARGB(255, 15, 32, 54),
                  child: const Center(
                    child: Icon(Icons.image, size: 60, color: Colors.white54),
                  ),
                ),
              ),
              // Lacivert gradient overlay (ortadan aşağıya, %40 opaklık)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                    colors: [
                      Colors.transparent,
                      const Color.fromARGB(255, 11, 25, 43).withOpacity(0.2),
                      const Color.fromARGB(255, 12, 24, 39).withOpacity(0.85),
                    ],
                  ),
                ),
              ),
              // Metin içeriği (altta)
              Positioned(
                left: 24,
                right: 24,
                bottom: 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRichText(data['title']!, data['highlight']!),
                    const SizedBox(height: 16),
                    // Alt çizgi
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4220B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichText(String text, String highlight) {
    final parts = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((line) {
        if (line.contains(highlight)) {
          final beforeHighlight = line.split(highlight)[0];
          final afterHighlight = line.split(highlight).length > 1
              ? line.split(highlight)[1]
              : '';
          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: beforeHighlight,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: highlight,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF4220B),
                    height: 1.2,
                  ),
                ),
                TextSpan(
                  text: afterHighlight,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        }
        return Text(
          line,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        );
      }).toList(),
    );
  }
}
