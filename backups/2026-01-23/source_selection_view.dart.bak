import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/source_selection_controller.dart';
import '../services/auth_service.dart';
import '../utils/news_sources_data.dart';
import 'dashboard_view.dart';
import 'login_view.dart';

class SourceSelectionView extends StatelessWidget {
  const SourceSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    // Üye kontrolü - üye değilse login'e yönlendir
    final authService = Get.find<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (!authService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Giriş Gerekli',
          'Kaynak seçimi için lütfen giriş yapın',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        Get.offAll(() => LoginView());
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final controller = Get.put(SourceSelectionController());

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF132440) : Colors.grey.shade50,
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: () {
                if (controller.totalSelectedCount ==
                    controller.totalSourcesCount) {
                  controller.deselectAll();
                } else {
                  controller.selectAll();
                }
              },
              child: Text(
                controller.totalSelectedCount == controller.totalSourcesCount
                    ? 'Hiçbiri'
                    : 'Tümü',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2F47) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
            ),
            child: Obx(
              () => Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${controller.totalSelectedCount} / ${controller.totalSourcesCount} kaynak seçili',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: kNewsSources.length,
              itemBuilder: (context, index) {
                final category = kNewsSources[index];
                return _buildCategorySection(controller, category, isDark);
              },
            ),
          ),
          // Continue Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2F47) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Obx(
              () => SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: controller.totalSelectedCount > 0
                      ? () => Get.offAll(() => DashboardView())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4220B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    controller.totalSelectedCount > 0
                        ? 'Devam Et (${controller.totalSelectedCount} kaynak)'
                        : 'En az 1 kaynak seçin',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    SourceSelectionController controller,
    NewsSourceCategory category,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2F47) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(category.icon, color: category.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Obx(
                        () => Text(
                          '${controller.getSelectedCountInCategory(category.id)} / ${category.sources.length} seçili',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Select All Button
                Obx(() {
                  final isFullySelected = controller.isCategoryFullySelected(
                    category.id,
                  );
                  final isPartiallySelected = controller
                      .isCategoryPartiallySelected(category.id);

                  return TextButton.icon(
                    onPressed: () =>
                        controller.toggleCategorySelection(category.id),
                    icon: Icon(
                      isFullySelected
                          ? Icons.check_box
                          : isPartiallySelected
                          ? Icons.indeterminate_check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: isFullySelected || isPartiallySelected
                          ? category.color
                          : (isDark ? Colors.white38 : Colors.grey.shade400),
                    ),
                    label: Text(
                      isFullySelected ? 'Kaldır' : 'Tümünü Seç',
                      style: TextStyle(
                        color: category.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Sources Grid
          Container(
            color: isDark ? const Color(0xFF1A2F47) : Colors.white,
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: category.sources.map((source) {
                return _buildSourceChip(controller, source, category.color, isDark);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(
    SourceSelectionController controller,
    NewsSourceItem source,
    Color categoryColor,
    bool isDark,
  ) {
    return Obx(() {
      final isSelected = controller.isSourceSelected(source.id);

      return GestureDetector(
        onTap: () => controller.toggleSource(source.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withOpacity(0.1)
                : (isDark ? const Color(0xFF132440) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? categoryColor : (isDark ? Colors.white24 : Colors.grey.shade300),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle, size: 16, color: categoryColor),
                const SizedBox(width: 6),
              ],
              Text(
                source.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? categoryColor : (isDark ? Colors.white70 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
