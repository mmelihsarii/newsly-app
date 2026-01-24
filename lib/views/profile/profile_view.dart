import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/dashboard_controller.dart';
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
  late ProfileController controller;

  @override
  void initState() {
    super.initState();
    // Her seferinde yeni controller oluştur
    controller = Get.put(ProfileController(), tag: 'profile_view');
  }

  @override
  void dispose() {
    // Controller'ı temizle
    Get.delete<ProfileController>(tag: 'profile_view');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final dashboardController = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () {
            // Önce geri dön, sonra anasayfaya geç
            Get.back();
            dashboardController.changeTabIndex(0);
          },
        ),
        title: Text(
          'Profil',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
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

        return _buildUserProfile(controller, user);
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

  Widget _buildUserProfile(ProfileController controller, dynamic user) {
    final themeController = Get.find<ThemeController>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(controller),
          const SizedBox(height: 20),
          _buildProfileInfo(controller),
          const SizedBox(height: 20),
          // Dark Mode Switch
          _buildDarkModeSwitch(themeController),
          const SizedBox(height: 20),
          _buildEditButton(controller),
          const SizedBox(height: 20),
          _buildDeleteAccountButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ProfileController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Get.isDarkMode
              ? [const Color(0xFF1A2F47), const Color(0xFF132440)]
              : [const Color(0xFFF4220B).withOpacity(0.1), Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Profil Resmi (Devre Dışı)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF4220B), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: Get.isDarkMode
                    ? const Color(0xFF1A2F47)
                    : Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Get.isDarkMode ? Colors.white54 : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // İsim
          Obx(() {
            final profile = Get.find<UserService>().userProfile.value;
            final firstName = profile?['firstName'] ?? '';
            final lastName = profile?['lastName'] ?? '';
            final fullName = '$firstName $lastName'.trim();
            return Text(
              fullName.isEmpty ? 'Kullanıcı' : fullName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(ProfileController controller) {
    return Obx(() {
      // Trigger rebuild when profile changes
      final profile = Get.find<UserService>().userProfile.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil Bilgileri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Ad',
              value: profile?['firstName']?.toString().isEmpty ?? true
                  ? 'Belirtilmemiş'
                  : profile?['firstName'] ?? 'Belirtilmemiş',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Soyad',
              value: profile?['lastName']?.toString().isEmpty ?? true
                  ? 'Belirtilmemiş'
                  : profile?['lastName'] ?? 'Belirtilmemiş',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Hakkında',
              value: profile?['about']?.toString().isEmpty ?? true
                  ? 'Belirtilmemiş'
                  : profile?['about'] ?? 'Belirtilmemiş',
              maxLines: 3,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1A2F47) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Get.isDarkMode
              ? const Color(0xFF2A4F67)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4220B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFF4220B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Get.isDarkMode
                        ? Colors.white70
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => _showEditDialog(controller),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF4220B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit, size: 22),
              SizedBox(width: 8),
              Text(
                'Bilgileri Düzenle',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(ProfileController controller) {
    final isDark = Get.isDarkMode;
    
    Get.dialog(
      Dialog(
        backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profili Düzenle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDialogTextField(
                  label: 'Ad',
                  controller: controller.firstNameController,
                  icon: Icons.person_outline,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  label: 'Soyad',
                  controller: controller.lastNameController,
                  icon: Icons.person_outline,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  label: 'Hakkında',
                  controller: controller.aboutController,
                  icon: Icons.info_outline,
                  maxLines: 4,
                  hintText: 'Kendinizden kısaca bahsedin...',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : () => controller.saveProfile(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4220B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark 
                            ? Colors.grey.shade700 
                            : Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Kaydet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? hintText,
    bool isDark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF132440) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: isDark 
                ? Border.all(color: const Color(0xFF2A4F67)) 
                : null,
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: Icon(icon, color: const Color(0xFFF4220B)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountButton() {
    final authService = Get.find<AuthService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200, width: 1),
        ),
        child: ListTile(
          onTap: () => authService.deleteAccount(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_forever,
              color: Colors.red,
              size: 26,
            ),
          ),
          title: const Text(
            'Hesabımı Sil',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Hesabınızı kalıcı olarak silin',
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.red.shade400,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeSwitch(ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1A2F47) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Get.isDarkMode
                ? const Color(0xFF2A4F67)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4220B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                themeController.isDarkMode.value
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: const Color(0xFFF4220B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Karanlık Mod',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Get.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    themeController.isDarkMode.value
                        ? 'Karanlık tema aktif'
                        : 'Aydınlık tema aktif',
                    style: TextStyle(
                      fontSize: 13,
                      color: Get.isDarkMode
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => Switch(
                value: themeController.isDarkMode.value,
                onChanged: (value) => themeController.toggleTheme(),
                activeColor: const Color(0xFFF4220B),
                activeTrackColor: const Color(0xFFF4220B).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
