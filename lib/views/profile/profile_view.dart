import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/colors.dart';
import '../login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int selectedZodiacIndex = 0;
  int selectedTeamIndex = -1; // -1 = hiçbiri seçili değil
  bool isSaving = false;

  // Text Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  final List<Map<String, String>> zodiacSigns = [
    {'name': 'Koç', 'symbol': '♈'},
    {'name': 'Boğa', 'symbol': '♉'},
    {'name': 'İkizler', 'symbol': '♊'},
    {'name': 'Yengeç', 'symbol': '♋'},
    {'name': 'Aslan', 'symbol': '♌'},
    {'name': 'Başak', 'symbol': '♍'},
    {'name': 'Terazi', 'symbol': '♎'},
    {'name': 'Akrep', 'symbol': '♏'},
    {'name': 'Yay', 'symbol': '♐'},
    {'name': 'Oğlak', 'symbol': '♑'},
    {'name': 'Kova', 'symbol': '♒'},
    {'name': 'Balık', 'symbol': '♓'},
  ];

  final List<Map<String, dynamic>> teams = [
    {'name': 'Fenerbahçe', 'short': 'FB', 'color': const Color(0xFF00205B)},
    {'name': 'Galatasaray', 'short': 'GS', 'color': const Color(0xFFFF6600)},
    {'name': 'Beşiktaş', 'short': 'BJK', 'color': Colors.black},
    {'name': 'Trabzon', 'short': 'TS', 'color': const Color(0xFF8B0000)},
    {'name': 'Diğer Takımlar', 'short': '⚽', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    final authService = Get.find<AuthService>();
    final user = authService.user.value;
    if (user != null) {
      final displayName = user.displayName ?? '';
      final nameParts = displayName.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameController.text = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Hata',
        'Lütfen adınızı girin',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final userService = Get.find<UserService>();
      final success = await userService.saveFullProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        about: _aboutController.text.trim(),
        zodiacSign: zodiacSigns[selectedZodiacIndex]['name'],
        team: selectedTeamIndex >= 0 ? teams[selectedTeamIndex]['name'] : null,
      );

      if (success) {
        Get.snackbar(
          'Başarılı',
          'Profiliniz kaydedildi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Hata',
          'Profil kaydedilemedi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Bir hata oluştu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Profili Düzenle',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final user = authService.user.value;

        if (user == null) {
          return _buildGuestView();
        }

        return _buildUserProfile(user);
      }),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Misafir olarak geziniyorsunuz',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.to(() => LoginView()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Giriş Yap', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(dynamic user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormFieldWithController(
                  label: 'Adınız',
                  controller: _firstNameController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildFormFieldWithController(
                  label: 'Soyadınız',
                  controller: _lastNameController,
                ),
                const SizedBox(height: 20),
                _buildFormFieldWithController(
                  label: 'Hakkınızda',
                  controller: _aboutController,
                  hintText: 'Kendinizden kısaca bahsedin...',
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                _buildZodiacSelector(),
                const SizedBox(height: 20),
                _buildTeamSelector(),
                const SizedBox(height: 30),
                // Kaydet Butonu
                _buildSaveButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF4220B),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Kaydet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFormFieldWithController({
    required String label,
    required TextEditingController controller,
    String? hintText,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: icon != null
                  ? Icon(icon, color: const Color(0xFFF4220B))
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZodiacSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Burcunuz',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: zodiacSigns.length,
            itemBuilder: (context, index) {
              final zodiac = zodiacSigns[index];
              final isSelected = index == selectedZodiacIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedZodiacIndex = index;
                  });
                },
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF4220B)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        zodiac['symbol']!,
                        style: TextStyle(
                          fontSize: 26,
                          color: isSelected
                              ? const Color(0xFFF4220B)
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        zodiac['name']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFF4220B)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Takımınız',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: teams.asMap().entries.map((entry) {
            final index = entry.key;
            final team = entry.value;
            final isSelected = index == selectedTeamIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedTeamIndex = index;
                });
              },
              child: Container(
                width: (MediaQuery.of(context).size.width - 60) / 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFF4220B)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: team['color'],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          team['short'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        team['name'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFF4220B)
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFFF4220B),
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE5E5), Colors.white],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: _buildCameraButton(
              onTap: () {
                print('Profil resmi değiştir');
              },
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildCameraButton(
              onTap: () {
                print('Kapak resmi değiştir');
              },
              hasPlus: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton({
    required VoidCallback onTap,
    bool hasPlus = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.camera_alt, color: Color(0xFFF4220B), size: 22),
            if (hasPlus)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4220B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
