import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/home_controller.dart';
import '../views/login_view.dart';
import '../views/source_selection_view.dart';
import '../views/dashboard_view.dart';
import '../views/profile/profile_view.dart';
import '../views/live_stream_view.dart';
import '../views/legal/legal_page_view.dart';
import '../widgets/notification_bottom_sheet.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SharedAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
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
      title: GestureDetector(
        onTap: () {
          // Logo'ya basınca anasayfaya git
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
        IconButton(
          onPressed: () {
            // Anasayfaya git ve aramayı aç
            final dashboardController = Get.find<DashboardController>();
            dashboardController.changeTabIndex(0); // Anasayfaya git

            // Sayfa geçişi tamamlanınca aramayı aç
            Future.delayed(const Duration(milliseconds: 300), () {
              try {
                final homeController = Get.find<HomeController>();
                homeController.isSearchOpen.value = true;
              } catch (e) {
                print('HomeController bulunamadı: $e');
              }
            });
          },
          icon: Icon(
            Icons.search,
            color: isDark ? Colors.white : Colors.black87,
            size: 28,
          ),
        ),
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
class MainMenuDrawer extends StatefulWidget {
  const MainMenuDrawer({super.key});

  @override
  State<MainMenuDrawer> createState() => _MainMenuDrawerState();
}

class _MainMenuDrawerState extends State<MainMenuDrawer> {
  bool _isLegalExpanded = false;

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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                          // Üye kontrolü - üye değilse login'e yönlendir
                          if (authService.isLoggedIn) {
                            Get.to(() => const SourceSelectionView());
                          } else {
                            Get.snackbar(
                              'Giriş Gerekli',
                              'Kaynak seçimi için lütfen giriş yapın',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.orange,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                            Get.to(() => LoginView());
                          }
                        },
                      ),
                      const Divider(height: 1),
                      // Yasal Metinler - Dropdown
                      _buildExpandableMenuItem(
                        icon: Icons.gavel_outlined,
                        title: 'Yasal Metinler',
                        isExpanded: _isLegalExpanded,
                        onTap: () {
                          setState(() {
                            _isLegalExpanded = !_isLegalExpanded;
                          });
                        },
                        children: [
                          _buildSubMenuItem(
                            title: 'KVKK',
                            onTap: () {
                              Get.back();
                              Get.to(
                                () => const LegalPageView(
                                  title: 'KVKK',
                                  slug: 'kvkk',
                                ),
                              );
                            },
                          ),
                          _buildSubMenuItem(
                            title: 'Kişisel Verilerin Saklama ve İmha Etme',
                            onTap: () {
                              Get.back();
                              Get.to(
                                () => const LegalPageView(
                                  title:
                                      'Kişisel Verilerin Saklama ve İmha Etme Prosedürü',
                                  slug:
                                      'kisisel-verilerin-saklama-ve-imha-etme-proseduru',
                                ),
                              );
                            },
                          ),
                          _buildSubMenuItem(
                            title: 'Çerez Politikası',
                            onTap: () {
                              Get.back();
                              Get.to(
                                () => const LegalPageView(
                                  title: 'Çerez Politikası',
                                  slug: 'cerez-politikasi',
                                ),
                              );
                            },
                          ),
                          _buildSubMenuItem(
                            title: 'Hakkımızda',
                            onTap: () {
                              Get.back();
                              Get.to(
                                () => const LegalPageView(
                                  title: 'Hakkımızda',
                                  slug: 'about-us',
                                ),
                              );
                            },
                          ),
                          _buildSubMenuItem(
                            title: 'İletişim',
                            onTap: () {
                              Get.back();
                              Get.to(
                                () => const LegalPageView(
                                  title: 'İletişim',
                                  slug: 'contact-us',
                                ),
                              );
                            },
                          ),
                          _buildSubMenuItem(
                            title: 'Şartlar & Koşullar',
                            onTap: () {
                              Get.back();
                              Get.to(
                                () => const LegalPageView(
                                  title: 'Kullanım Şartları ve Koşulları',
                                  slug: 'terms-condition',
                                ),
                              );
                            },
                          ),
                          _buildSubMenuItem(
                            title: 'Gizlilik Politikası',
                            onTap: () {
                              Get.back();
                              Get.to(
                                () => const LegalPageView(
                                  title: 'Gizlilik Politikası',
                                  slug: 'privacy-policy',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),
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

  Widget _buildExpandableMenuItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: const Color(0xFF1E3A5F)),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
          ),
          onTap: onTap,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: Colors.grey.shade50,
            child: Column(children: children),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildSubMenuItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade300,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}
