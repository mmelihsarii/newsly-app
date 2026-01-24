import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/search_controller.dart' as search;
import '../models/source_model.dart';
import '../utils/colors.dart';
import '../utils/news_sources_data.dart';

class SearchFilterSheet extends StatelessWidget {
  final search.NewsSearchController controller;

  const SearchFilterSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2F47) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gelişmiş Filtreler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Obx(() {
                  if (controller.activeFilterCount > 0) {
                    return TextButton(
                      onPressed: () => controller.clearFilters(),
                      child: const Text(
                        'Temizle',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════════════════════════════════
                  // TARİH FİLTRESİ
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionTitle('Tarih Aralığı', Icons.calendar_today, isDark),
                  const SizedBox(height: 12),
                  _buildDateFilters(context, isDark),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // KATEGORİ FİLTRESİ
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionTitle('Kategoriler', Icons.category, isDark),
                  const SizedBox(height: 12),
                  _buildCategoryFilters(isDark),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // KAYNAK FİLTRESİ
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionTitle('Kaynaklar', Icons.source, isDark),
                  const SizedBox(height: 12),
                  _buildSourceFilters(isDark),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // SIRALAMA
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionTitle('Sıralama', Icons.sort, isDark),
                  const SizedBox(height: 12),
                  _buildSortOptions(isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Apply Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132440) : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade200,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Obx(() => Text(
                    controller.activeFilterCount > 0
                        ? 'Uygula (${controller.activeFilterCount} filtre)'
                        : 'Uygula',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilters(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Hızlı seçenekler
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDateChip('Bugün', 'today', isDark),
            _buildDateChip('Son 7 Gün', 'week', isDark),
            _buildDateChip('Son 30 Gün', 'month', isDark),
            _buildDateChip('Özel', 'custom', isDark),
          ],
        )),
        // Özel tarih seçimi
        Obx(() {
          if (controller.selectedDateRange.value == 'custom') {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateButton(
                      context,
                      'Başlangıç',
                      controller.startDate.value,
                      (date) {
                        if (date != null) {
                          controller.setCustomDateRange(
                            date,
                            controller.endDate.value ?? DateTime.now(),
                          );
                        }
                      },
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateButton(
                      context,
                      'Bitiş',
                      controller.endDate.value,
                      (date) {
                        if (date != null) {
                          controller.setCustomDateRange(
                            controller.startDate.value ?? DateTime.now().subtract(const Duration(days: 30)),
                            date,
                          );
                        }
                      },
                      isDark,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildDateChip(String label, String value, bool isDark) {
    final isSelected = controller.selectedDateRange.value == value;
    
    return GestureDetector(
      onTap: () => controller.setDateRange(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF2A4F67) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF3A5F77) : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime? date,
    Function(DateTime?) onSelect,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: isDark ? const Color(0xFF1A2F47) : Colors.white,
                  onSurface: isDark ? Colors.white : Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );
        onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF3A5F77) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd MMM yyyy', 'tr').format(date)
                    : label,
                style: TextStyle(
                  color: date != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white54 : Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(bool isDark) {
    return Obx(() {
      final categories = controller.availableCategories;
      
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map((category) {
          // Dinamik veya statik kategori olabilir
          final String catId;
          final String catName;
          final Color catColor;
          final IconData catIcon;
          
          if (category is SourceCategory) {
            // Dinamik kategori (Firestore'dan)
            catId = category.id;
            catName = category.name;
            catColor = _getCategoryColor(category.name);
            catIcon = _getCategoryIcon(category.name);
          } else {
            // Statik kategori (NewsSourceCategory)
            catId = category.id;
            catName = category.name;
            catColor = category.color;
            catIcon = category.icon;
          }
          
          final isSelected = controller.selectedCategories.contains(catId);
          
          return GestureDetector(
            onTap: () => controller.toggleCategory(catId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? catColor.withOpacity(0.2)
                    : (isDark ? const Color(0xFF2A4F67) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? catColor
                      : (isDark ? const Color(0xFF3A5F77) : Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    catIcon,
                    size: 16,
                    color: isSelected
                        ? catColor
                        : (isDark ? Colors.white54 : Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    catName,
                    style: TextStyle(
                      color: isSelected
                          ? catColor
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.check, size: 14, color: catColor),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildSourceFilters(bool isDark) {
    return Obx(() {
      // Dinamik kaynaklar varsa kategorize göster
      if (controller.dynamicSourceCategories.isNotEmpty) {
        return _buildDynamicSourceFilters(isDark);
      }
      
      // Fallback: eski format
      final sources = controller.availableSources;
      
      if (sources.isEmpty) {
        return Text(
          'Kaynak bulunamadı',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        );
      }

      return Container(
        constraints: const BoxConstraints(maxHeight: 150),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources.take(20).map((source) {
              final isSelected = controller.selectedSources.contains(source);
              
              return GestureDetector(
                onTap: () => controller.toggleSource(source),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : (isDark ? const Color(0xFF2A4F67) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF3A5F77) : Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        source,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check, size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildDynamicSourceFilters(bool isDark) {
    final categories = controller.dynamicSourceCategories;
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.map((category) {
            final color = _getCategoryColor(category.name);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori başlığı
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(_getCategoryIcon(category.name), size: 14, color: color),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${category.sources.length})',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Kaynaklar
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: category.sources.map((source) {
                      final isSelected = controller.selectedSources.contains(source.name);
                      
                      return GestureDetector(
                        onTap: () => controller.toggleSource(source.name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.2)
                                : (isDark ? const Color(0xFF2A4F67) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : (isDark ? const Color(0xFF3A5F77) : Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                source.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.check, size: 12, color: color),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
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
    if (n.contains('yerel')) return const Color(0xFF14B8A6);
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
    if (n.contains('yerel')) return Icons.location_city;
    return Icons.public;
  }

  Widget _buildSortOptions(bool isDark) {
    return Obx(() => Row(
      children: [
        Expanded(
          child: _buildSortChip(
            'Tarihe Göre',
            'date',
            Icons.access_time,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSortChip(
            'İlgiye Göre',
            'relevance',
            Icons.star,
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        // Sıralama yönü
        GestureDetector(
          onTap: () => controller.toggleSortOrder(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A4F67) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF3A5F77) : Colors.grey.shade300,
              ),
            ),
            child: Icon(
              controller.sortOrder.value == 'desc'
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildSortChip(String label, String value, IconData icon, bool isDark) {
    final isSelected = controller.sortBy.value == value;
    
    return GestureDetector(
      onTap: () => controller.setSortBy(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : (isDark ? const Color(0xFF2A4F67) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF3A5F77) : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white54 : Colors.grey),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filtre sheet'i göster
void showSearchFilterSheet(BuildContext context, search.NewsSearchController controller) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SearchFilterSheet(controller: controller),
    ),
  );
}
