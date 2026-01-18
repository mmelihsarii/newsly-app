import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/user_service.dart';
import 'dashboard_view.dart';

class CategorySelectionView extends StatefulWidget {
  const CategorySelectionView({super.key});

  @override
  State<CategorySelectionView> createState() => _CategorySelectionViewState();
}

class _CategorySelectionViewState extends State<CategorySelectionView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedCategories = {};
  String _searchQuery = '';

  final List<Map<String, String>> _categories = [
    {
      'name': 'Bilim',
      'image':
          'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400',
    },
    {
      'name': 'Teknoloji',
      'image':
          'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400',
    },
    {
      'name': 'Spor',
      'image':
          'https://images.unsplash.com/photo-1461896836934- voices-of-football?w=400',
    },
    {
      'name': 'Gündem',
      'image':
          'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=400',
    },
    {
      'name': 'Ekonomi',
      'image':
          'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=400',
    },
    {
      'name': 'Sağlık',
      'image':
          'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=400',
    },
    {
      'name': 'Kültür & Sanat',
      'image':
          'https://images.unsplash.com/photo-1541367777708-7905fe3296c0?w=400',
    },
    {
      'name': 'Eğitim',
      'image':
          'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=400',
    },
  ];

  List<Map<String, String>> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where(
          (cat) =>
              cat['name']!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _goBack() {
    Get.back();
  }

  void _skip() {
    Get.offAll(() => DashboardView());
  }

  Future<void> _next() async {
    if (_selectedCategories.isNotEmpty) {
      // Firestore'a kategorileri kaydet
      final userService = Get.find<UserService>();
      for (final category in _selectedCategories) {
        await userService.followCategory(category);
      }

      Get.offAll(() => DashboardView());
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
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
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İlgi alanlarınızı\nseçin.',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Kategori ara',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Category Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = _filteredCategories[index];
                    final isSelected = _selectedCategories.contains(
                      category['name'],
                    );

                    return _buildCategoryCard(
                      name: category['name']!,
                      imageUrl: category['image']!,
                      isSelected: isSelected,
                      onTap: () => _toggleCategory(category['name']!),
                    );
                  },
                ),
              ),
            ),
            // Next Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedCategories.isNotEmpty ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4220B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'İleri',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String name,
    required String imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFFF4220B), width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 17 : 20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E3A5F),
                  child: const Center(
                    child: Icon(
                      Icons.category,
                      size: 40,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              // Category Name
              Positioned(
                left: 16,
                bottom: 16,
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Selection Indicator
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF4220B) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF4220B)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
