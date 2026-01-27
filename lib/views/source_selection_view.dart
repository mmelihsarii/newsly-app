import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/source_selection_controller.dart';
import '../models/source_model.dart';
import '../services/user_service.dart';
import '../utils/news_sources_data.dart';
import '../utils/colors.dart';
import 'dashboard_view.dart';

class SourceSelectionView extends StatefulWidget {
  const SourceSelectionView({super.key});

  @override
  State<SourceSelectionView> createState() => _SourceSelectionViewState();
}

class _SourceSelectionViewState extends State<SourceSelectionView> {
  late final SourceSelectionController controller;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SourceSelectionController>();
    _isLoggedIn = FirebaseAuth.instance.currentUser != null;
    
    // Geçici seçimleri kayıtlı duruma sıfırla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initTempSelection();
    });
  }

  /// Geri tuşuna basıldığında
  Future<bool> _onWillPop() async {
    // Giriş yapmış kullanıcı ve kayıtlı kaynak yoksa çıkışı engelle
    if (_isLoggedIn && controller.savedSourcesCount == 0) {
      _showMustSelectSourcesDialog();
      return false;
    }
    
    // Kaydedilmemiş değişiklik varsa uyar
    if (controller.hasChanges) {
      final shouldExit = await _showUnsavedChangesDialog();
      if (shouldExit == true) {
        controller.cancelChanges();
        return true;
      }
      return false;
    }
    
    return true;
  }

  /// Kaynak seçmeden çıkılamaz uyarısı
  void _showMustSelectSourcesDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Kaynak Seçimi Gerekli'),
        content: const Text(
          'Devam etmek için en az 1 kaynak seçmelisiniz.\n\n'
          'Takip etmek istediğiniz haber kaynaklarını seçin ve "Devam Et" butonuna basın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// Kaydedilmemiş değişiklik uyarısı
  Future<bool?> _showUnsavedChangesDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Kaydedilmemiş Değişiklikler'),
        content: const Text(
          'Yaptığınız değişiklikler kaydedilmedi.\n\n'
          'Çıkarsanız değişiklikler kaybolacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('gündem') || n.contains('son dakika')) return const Color(0xFFEF4444);
    if (n.contains('spor')) return const Color(0xFF22C55E);
    if (n.contains('ekonomi') || n.contains('finans')) return const Color(0xFFF59E0B);
    if (n.contains('teknoloji') || n.contains('bilim')) return const Color(0xFF6366F1);
    if (n.contains('yabancı') || n.contains('dünya')) return const Color(0xFF8B5CF6);
    if (n.contains('ajans')) return const Color(0xFF0EA5E9);
    return const Color(0xFF64748B);
  }

  IconData _getCategoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('gündem')) return Icons.newspaper;
    if (n.contains('son dakika')) return Icons.flash_on;
    if (n.contains('spor')) return Icons.sports_soccer;
    if (n.contains('ekonomi')) return Icons.trending_up;
    if (n.contains('teknoloji')) return Icons.computer;
    if (n.contains('bilim')) return Icons.science;
    if (n.contains('ajans')) return Icons.rss_feed;
    return Icons.public;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Kaynak Seçimi',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          // Giriş yapmış ve kaynak seçmemiş kullanıcı için geri butonu yok
          leading: _isLoggedIn 
              ? Obx(() => controller.savedSourcesCount == 0
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () async {
                        final canPop = await _onWillPop();
                        if (canPop) Get.back();
                      },
                    ))
              : IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87),
                  onPressed: () async {
                    final canPop = await _onWillPop();
                    if (canPop) Get.back();
                  },
                ),
          automaticallyImplyLeading: false,
          actions: [
            Obx(() => controller.isSourcesLoading.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: Icon(Icons.refresh, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => controller.refreshSources(),
                  )),
            Obx(() => TextButton(
                  onPressed: () => controller.totalSelectedCount == controller.totalSourcesCount
                      ? controller.deselectAll()
                      : controller.selectAll(),
                  child: Text(
                    controller.totalSelectedCount == controller.totalSourcesCount ? 'Hiçbiri' : 'Tümü',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                )),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2F47) : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade200)),
              ),
              child: Obx(() => Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${controller.totalSelectedCount} / ${controller.totalSourcesCount} kaynak seçili',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 14),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: controller.dynamicCategories.isNotEmpty
                              ? Colors.green.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              controller.dynamicCategories.isNotEmpty ? Icons.cloud : Icons.storage,
                              size: 14,
                              color: controller.dynamicCategories.isNotEmpty ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              controller.dynamicCategories.isNotEmpty ? 'Dinamik' : 'Statik',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: controller.dynamicCategories.isNotEmpty ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isSourcesLoading.value && controller.dynamicCategories.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final categories = controller.dynamicCategories.isNotEmpty
                    ? controller.dynamicCategories
                    : null;

                if (categories != null) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return _buildDynamicCategory(categories[index], isDark);
                    },
                  );
                }

                // Static fallback
                final staticCategories = kNewsSources.where((c) => c.id.toLowerCase() != 'genel').toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  itemCount: staticCategories.length,
                  itemBuilder: (context, index) {
                    return _buildStaticCategory(staticCategories[index], isDark);
                  },
                );
              }),
            ),
            // Bottom Button
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2F47) : Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4)),
                  ],
                ),
                child: Obx(() => ElevatedButton(
                      onPressed: controller.totalSelectedCount > 0 && !controller.isSaving.value
                          ? () async {
                              // Önce kaydet
                              await controller.saveAllChanges();
                              
                              // Onboarding'i tamamlandı olarak işaretle
                              final userService = Get.find<UserService>();
                              await userService.markOnboardingCompleted();
                              
                              // Dashboard'a git (controller'lar yeniden yüklenecek)
                              Get.offAll(() => DashboardView());
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 0,
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              controller.totalSelectedCount > 0
                                  ? 'Devam Et (${controller.totalSelectedCount} kaynak)'
                                  : 'En az 1 kaynak seçin',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCategory(SourceCategory category, bool isDark) {
    final color = _getCategoryColor(category.name);
    final icon = _getCategoryIcon(category.name);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2F47) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(() => Text(
                            '${controller.getSelectedCountInCategory(category.id)} / ${category.sources.length} seçili',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                          )),
                    ],
                  ),
                ),
                Obx(() {
                  final isFullySelected = controller.isCategoryFullySelected(category.id);
                  final isPartiallySelected = controller.isCategoryPartiallySelected(category.id);
                  return TextButton(
                    onPressed: () => controller.toggleCategorySelection(category.id),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: color.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFullySelected ? Icons.check_box : isPartiallySelected ? Icons.indeterminate_check_box : Icons.check_box_outline_blank,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(isFullySelected ? 'Kaldır' : 'Tümü', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          // Sources
          Container(
            width: double.infinity,
            color: isDark ? const Color(0xFF1A2F47) : Colors.white,
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: category.sources.map((source) => _buildSourceChip(source.name, source.name, color, isDark)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticCategory(NewsSourceCategory category, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2F47) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(category.icon, color: category.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(() => Text(
                            '${controller.getSelectedCountInCategory(category.id)} / ${category.sources.length} seçili',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600),
                          )),
                    ],
                  ),
                ),
                Obx(() {
                  final isFullySelected = controller.isCategoryFullySelected(category.id);
                  final isPartiallySelected = controller.isCategoryPartiallySelected(category.id);
                  return TextButton(
                    onPressed: () => controller.toggleCategorySelection(category.id),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: category.color.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFullySelected ? Icons.check_box : isPartiallySelected ? Icons.indeterminate_check_box : Icons.check_box_outline_blank,
                          size: 18,
                          color: category.color,
                        ),
                        const SizedBox(width: 4),
                        Text(isFullySelected ? 'Kaldır' : 'Tümü', style: TextStyle(color: category.color, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          // Sources
          Container(
            width: double.infinity,
            color: isDark ? const Color(0xFF1A2F47) : Colors.white,
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: (List<NewsSourceItem>.from(category.sources)..sort((a, b) => a.name.compareTo(b.name)))
                  .map((source) => _buildSourceChip(source.name, source.name, category.color, isDark))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(String id, String name, Color color, bool isDark) {
    return Obx(() {
      final isSelected = controller.isSourceSelected(id);
      return GestureDetector(
        onTap: () => controller.toggleSource(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : (isDark ? const Color(0xFF132440) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0xFF2A4F67) : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle, size: 18, color: color),
                const SizedBox(width: 8),
              ],
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : (isDark ? Colors.white70 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
