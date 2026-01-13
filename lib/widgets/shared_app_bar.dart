import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../views/login_view.dart';
import '../views/interest_view.dart';
import '../views/dashboard_view.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SharedAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () {
          mainScaffoldKey.currentState?.openDrawer();
        },
        icon: const Icon(Icons.menu, color: Color(0xFFF4220B), size: 32),
      ),
      title: Transform.translate(
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
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: Colors.black87, size: 28),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.videocam, color: Colors.red, size: 26),
        ),
        const SizedBox(width: 4),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFFF4220B),
                size: 28,
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF42A5F5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// Ana Menü Drawer Widget'ı
class MainMenuDrawer extends StatelessWidget {
  const MainMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF4220B), Color(0xFFFF6B4A)],
                  ),
                ),
                child: Row(
                  children: [
                    Obx(() {
                      final user = authService.user.value;
                      return CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              )
                            : null,
                      );
                    }),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Obx(() {
                        final user = authService.user.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Misafir',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (user?.email != null)
                              Text(
                                user!.email!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Menu Items
              _buildMenuItem(
                icon: Icons.interests_outlined,
                title: 'İlgi Alanları',
                onTap: () {
                  Get.back();
                  Get.to(() => const InterestView());
                },
              ),
              _buildMenuItem(
                icon: Icons.settings,
                title: 'Ayarlar',
                onTap: () => Get.back(),
              ),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                onTap: () => Get.back(),
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Yardım',
                onTap: () => Get.back(),
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'Hakkında',
                onTap: () => Get.back(),
              ),
              const Spacer(),
              const Divider(),
              // Çıkış Yap
              Obx(() {
                final user = authService.user.value;
                if (user == null) {
                  return _buildMenuItem(
                    icon: Icons.login,
                    title: 'Giriş Yap',
                    color: const Color(0xFFF4220B),
                    onTap: () {
                      Get.back();
                      Get.to(() => LoginView());
                    },
                  );
                }
                return _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Çıkış Yap',
                  color: Colors.red,
                  onTap: () async {
                    Get.back();
                    await authService.signOut();
                    Get.offAll(() => LoginView());
                  },
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF1E3A5F)),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
