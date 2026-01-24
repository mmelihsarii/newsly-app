import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/city_data.dart';
import 'source_selection_view.dart';
import 'login_view.dart';

class CitySelectionView extends StatefulWidget {
  const CitySelectionView({super.key});

  @override
  State<CitySelectionView> createState() => _CitySelectionViewState();
}

class _CitySelectionViewState extends State<CitySelectionView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  String _searchQuery = '';

  // Türkiye'nin 81 ili - Alfabetik sıralı (CityData'dan)
  final List<Map<String, dynamic>> _cities = CityData.cities;

  @override
  void initState() {
    super.initState();
    // Üye kontrolü - üye değilse login'e yönlendir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Get.find<AuthService>();
      if (!authService.isLoggedIn) {
        Get.snackbar(
          'Giriş Gerekli',
          'Şehir seçimi için lütfen giriş yapın',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        Get.offAll(() => LoginView());
      }
    });
  }

  List<Map<String, dynamic>> get _filteredCities {
    if (_searchQuery.isEmpty) return _cities;
    return _cities
        .where(
          (city) => city['name']!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _goBack() {
    Get.back();
  }

  void _skip() {
    // Misafir kullanıcılar kaynak seçimine gidemez
    final authService = Get.find<AuthService>();
    if (authService.isGuest) {
      Get.snackbar(
        'Üyelik Gerekli',
        'Kaynak seçimi için lütfen üye girişi yapın.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      Get.offAll(() => LoginView());
      return;
    }
    // Şehir seçimi atlandığında kaynak seçimine git
    Get.to(() => SourceSelectionView());
  }

  Future<void> _next() async {
    if (_selectedCity != null) {
      // Misafir kullanıcılar kaynak seçimine gidemez
      final authService = Get.find<AuthService>();
      if (authService.isGuest) {
        Get.snackbar(
          'Üyelik Gerekli',
          'Kaynak seçimi için lütfen üye girişi yapın.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        Get.offAll(() => LoginView());
        return;
      }

      // Firestore'a şehri kaydet
      await Get.find<UserService>().updateUserProfile(
        displayName: Get.find<UserService>().userProfile.value?['displayName'],
      );

      // Şehir bilgisini ayrıca kaydet
      // TODO: UserService'e city field eklenebilir

      // Kaynak seçimine git
      Get.to(() => SourceSelectionView());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
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
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Geç',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 16),
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
                  Text(
                    'Şehrinizi\nseçin.',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF132440) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Şehir ara',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
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
            const SizedBox(height: 16),
            // City List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filteredCities.length,
                itemBuilder: (context, index) {
                  final city = _filteredCities[index];
                  final cityName = city['name'] ?? '';
                  final isSelected = _selectedCity == cityName;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCity = cityName),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF4220B).withOpacity(0.1)
                            : (isDark ? const Color(0xFF132440) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF4220B)
                              : (isDark ? Colors.white12 : Colors.grey.shade200),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Şehir İkonu
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF4220B).withOpacity(0.1)
                                  : (isDark ? const Color(0xFF1A2F47) : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.location_city,
                              color: isSelected
                                  ? const Color(0xFFF4220B)
                                  : (isDark ? Colors.white54 : Colors.grey.shade500),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // City Name
                          Expanded(
                            child: Text(
                              cityName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          // Check Icon
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFF4220B),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Next Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedCity != null ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4220B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
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
}
