import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/source_selection_controller.dart';
import '../utils/news_sources_data.dart';
import 'dashboard_view.dart';

class SourceSelectionView extends StatelessWidget {
  const SourceSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SourceSelectionController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Kaynak Seçimi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
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
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
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
                return _buildCategorySection(controller, category);
              },
            ),
          ),
          // Continue Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
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
                    disabledBackgroundColor: Colors.grey.shade300,
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
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Obx(
                        () => Text(
                          '${controller.getSelectedCountInCategory(category.id)} / ${category.sources.length} seçili',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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
                          : Colors.grey.shade400,
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
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: category.sources.map((source) {
                return _buildSourceChip(controller, source, category.color);
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
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? categoryColor : Colors.grey.shade300,
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
                  color: isSelected ? categoryColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
