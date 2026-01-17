import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/interest_controller.dart';

class InterestView extends StatelessWidget {
  const InterestView({super.key});

  @override
  Widget build(BuildContext context) {
    final InterestController controller = Get.put(InterestController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'İlgi Alanları',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Get.back(),
          ),
          bottom: TabBar(
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade700,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Şehirler', icon: Icon(Icons.location_city)),
              Tab(text: 'Kategoriler', icon: Icon(Icons.category)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Şehirler Tab
            _buildCitiesList(controller),
            // Kategoriler Tab
            _buildCategoriesList(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildCitiesList(InterestController controller) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: controller.allCities.length,
      itemBuilder: (context, index) {
        final city = controller.allCities[index];
        final String cityName = city['name'] as String;

        return Obx(() {
          final bool isFollowing = controller.isCityFollowing(cityName);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isFollowing ? Colors.blue.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFollowing
                    ? Colors.blue.shade300
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: CircleAvatar(
                backgroundColor: isFollowing
                    ? Colors.blue.shade100
                    : Colors.grey.shade200,
                child: Icon(
                  Icons.location_on,
                  color: isFollowing ? Colors.blue.shade700 : Colors.grey,
                  size: 20,
                ),
              ),
              title: Text(
                cityName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isFollowing ? Colors.blue.shade700 : Colors.black87,
                ),
              ),
              trailing: Switch(
                value: isFollowing,
                onChanged: (_) => controller.toggleCity(cityName),
                activeThumbColor: Colors.blue,
                activeTrackColor: Colors.blue.shade100,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildCategoriesList(InterestController controller) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: controller.categories.length,
      itemBuilder: (context, index) {
        final category = controller.categories[index];
        final String categoryName = category['name']!;

        return Obx(() {
          final bool isFollowing = controller.isCategoryFollowing(categoryName);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isFollowing ? Colors.orange.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFollowing
                    ? Colors.orange.shade300
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: CircleAvatar(
                backgroundColor: isFollowing
                    ? Colors.orange.shade100
                    : Colors.grey.shade200,
                child: Icon(
                  _getCategoryIcon(categoryName),
                  color: isFollowing ? Colors.orange.shade700 : Colors.grey,
                  size: 20,
                ),
              ),
              title: Text(
                categoryName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isFollowing ? Colors.orange.shade700 : Colors.black87,
                ),
              ),
              trailing: Switch(
                value: isFollowing,
                onChanged: (_) => controller.toggleCategory(categoryName),
                activeThumbColor: Colors.orange,
                activeTrackColor: Colors.orange.shade100,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
              ),
            ),
          );
        });
      },
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Yerel Haberler':
        return Icons.location_city;
      case 'Son Dakika':
        return Icons.flash_on;
      case 'Gündem':
        return Icons.newspaper;
      case 'Spor':
        return Icons.sports_soccer;
      case 'Ekonomi & Finans':
        return Icons.trending_up;
      case 'Bilim & Teknoloji':
        return Icons.science;
      case 'Haber Ajansları':
        return Icons.rss_feed;
      case 'Yabancı Kaynaklar':
        return Icons.language;
      default:
        return Icons.category;
    }
  }
}
