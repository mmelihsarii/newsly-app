import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../views/login_view.dart';
import '../views/source_selection_view.dart';
import '../views/dashboard_view.dart';
import '../views/profile/profile_view.dart';
import '../views/notification_settings_view.dart';
import '../views/interest_view.dart';
import '../views/live_stream_view.dart';
import '../widgets/notification_bottom_sheet.dart';

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
        // Canlı Yayın Butonu
        GestureDetector(
          onTap: () => Get.to(() => const LiveStreamView()),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.videocam, color: Colors.red, size: 26),
          ),
        ),
        const SizedBox(width: 4),
        Stack(
          children: [
            IconButton(
              onPressed: () {
                showNotificationsBottomSheet(context);
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFFF4220B),
                size: 28,
              ),
            ),
            // Okunmamış bildirim göstergesi
            Obx(() {
              final notificationService = NotificationService();
              if (notificationService.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF42A5F5),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    notificationService.unreadCount > 9
                        ? '9+'
                        : notificationService.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
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
                icon: Icons.person_outline,
                title: 'Profil',
                onTap: () {
                  Get.back();
                  Get.to(() => const ProfileView());
                },
              ),
              _buildMenuItem(
                icon: Icons.source_outlined,
                title: 'Kaynak Seçimi',
                onTap: () {
                  Get.back();
                  Get.to(() => const SourceSelectionView());
                },
              ),
              _buildMenuItem(
                icon: Icons.interests_outlined,
                title: 'İlgi Alanları',
                onTap: () {
                  Get.back();
                  Get.to(() => const InterestView());
                },
              ),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Bildirim Ayarları',
                onTap: () {
                  Get.back();
                  Get.to(() => const NotificationSettingsPage());
                },
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'Hakkımızda',
                onTap: () {
                  Get.back();
                  _showAboutDialog();
                },
              ),
              _buildMenuItem(
                icon: Icons.mail_outline,
                title: 'İletişim',
                onTap: () {
                  Get.back();
                  _showContactDialog();
                },
              ),
              _buildMenuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                onTap: () {
                  Get.back();
                  _showPrivacyPolicy();
                },
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

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Hakkımızda'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Newsly',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Versiyon: 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Newsly, size en güncel haberleri sunan modern bir haber uygulamasıdır. Türkiye\'nin önde gelen haber kaynaklarından haberleri tek bir yerde toplar.',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Tamam')),
        ],
      ),
    );
  }

  void _showContactDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('İletişim'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.email, color: Color(0xFFF4220B)),
              title: Text('E-posta'),
              subtitle: Text('destek@newsly.com'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Color(0xFFF4220B)),
              title: Text('Telefon'),
              subtitle: Text('+90 212 XXX XX XX'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.location_on, color: Color(0xFFF4220B)),
              title: Text('Adres'),
              subtitle: Text('İstanbul, Türkiye'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Kapat')),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Get.dialog(
      AlertDialog(
        title: const Text('Gizlilik Politikası'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Veri Toplama',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Uygulamamız, hizmetlerimizi sunabilmek için temel kullanıcı bilgilerini toplar. Bu bilgiler arasında e-posta adresi, tercih edilen haberler ve uygulama kullanım verileri bulunur.',
              ),
              SizedBox(height: 16),
              Text(
                '2. Veri Güvenliği',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Verileriniz güvenli sunucularda şifrelenmiş olarak saklanır. Üçüncü taraflarla paylaşılmaz.',
              ),
              SizedBox(height: 16),
              Text(
                '3. Çerezler',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Uygulamamız, kullanıcı deneyimini iyileştirmek için çerezler kullanabilir.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Anladım')),
        ],
      ),
    );
  }
}
