import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/shared_app_bar.dart';
import 'home/home_view.dart';
import 'local/local_view.dart';
import 'follow/follow_view.dart';
import 'saved/saved_view.dart';
import 'profile/profile_view.dart';

// Global key for accessing scaffold from anywhere
final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

class DashboardView extends StatelessWidget {
  DashboardView({super.key});

  final DashboardController controller = Get.put(DashboardController());

  // Tab item'ları (ikon, label) - 5 normal item
  final List<Map<String, dynamic>> _navItems = const [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home,
      'label': 'Anasayfa',
    },
    {
      'icon': Icons.location_on_outlined,
      'activeIcon': Icons.location_on,
      'label': 'Yerel',
    },
    {'icon': Icons.add, 'activeIcon': Icons.add, 'label': 'Takip'},
    {
      'icon': Icons.bookmark_border,
      'activeIcon': Icons.bookmark,
      'label': 'Kaydedilenler',
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'label': 'Profil',
    },
  ];

  // View'ları bir kere oluştur (rebuild önleme)
  final List<Widget> _pages = [
    HomeView(),
    const LocalView(),
    const FollowView(),
    const SavedView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: mainScaffoldKey,
      backgroundColor: Colors.white,
      drawer: const MainMenuDrawer(),
      body: GetBuilder<DashboardController>(
        builder: (ctrl) =>
            IndexedStack(index: ctrl.tabIndex.value, children: _pages),
      ),
      bottomNavigationBar: GetBuilder<DashboardController>(
        builder: (ctrl) => _buildBottomNav(ctrl),
      ),
    );
  }

  // Normal Bottom Navigation Bar
  Widget _buildBottomNav(DashboardController ctrl) {
    return Builder(
      builder: (context) {
        // Get the bottom safe area padding for system navigation/home indicator
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return Container(
          // Add bottom safe area padding to the height
          height: 70 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final isSelected = ctrl.tabIndex.value == index;
              final item = _navItems[index];
              final isTakip = index == 2;

              // Takip butonu özel tasarım - TAM YUVARLAK
              if (isTakip) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ctrl.changeTabIndex(index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4220B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF4220B).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Normal butonlar
              return Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.changeTabIndex(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: isSelected ? 24 : 0,
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4220B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Icon(
                        isSelected ? item['activeIcon'] : item['icon'],
                        color: isSelected
                            ? const Color(0xFFF4220B)
                            : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFF4220B)
                              : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
