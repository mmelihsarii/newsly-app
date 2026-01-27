import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/source_model.dart';
import '../../utils/source_logos.dart';
import '../../controllers/follow_controller.dart';
import '../../controllers/source_selection_controller.dart';

class AddSourceView extends StatefulWidget {
  const AddSourceView({super.key});

  @override
  State<AddSourceView> createState() => _AddSourceViewState();
}

class _AddSourceViewState extends State<AddSourceView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();
  
  bool _isLoading = true;
  List<SourceModel> _allSources = [];
  Set<String> _selectedSourceIds = {};
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() => _isLoading = true);
    
    try {
      // Mevcut seçili kaynakları yükle - SourceSelectionController'dan al (öncelikli)
      if (Get.isRegistered<SourceSelectionController>()) {
        final sourceController = Get.find<SourceSelectionController>();
        // Önce kaynakları yüklemesini bekle
        await sourceController.initTempSelection();
        _selectedSourceIds = sourceController.selectedSources.toSet();
        print('📌 SourceSelectionController\'dan ${_selectedSourceIds.length} kaynak alındı');
        print('📌 Seçili kaynaklar: $_selectedSourceIds');
      } else {
        // Fallback: local storage'dan al
        final List<dynamic>? savedSources = _storage.read<List<dynamic>>('selected_sources');
        if (savedSources != null) {
          _selectedSourceIds = savedSources.cast<String>().toSet();
        }
      }

      // Tüm aktif kaynakları çek
      final snapshot = await _firestore
          .collection('news_sources')
          .where('is_active', isEqualTo: true)
          .get();

      _allSources = snapshot.docs
          .map((doc) => SourceModel.fromFirestore(doc))
          .where((s) => s.rssUrl.isNotEmpty)
          .toList();

      // Alfabetik sırala
      _allSources.sort((a, b) => a.name.compareTo(b.name));
      
      print('📌 Toplam ${_allSources.length} kaynak yüklendi');
      print('📌 Seçili kaynak sayısı: ${_selectedSourceIds.length}');
      
    } catch (e) {
      print('❌ Kaynak yükleme hatası: $e');
      Get.snackbar('Hata', 'Kaynaklar yüklenirken bir hata oluştu',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSource(SourceModel source) {
    setState(() {
      // Kaynak adını kullan (NewsService ile uyumlu)
      final sourceIdentifier = source.name;
      
      if (_selectedSourceIds.contains(sourceIdentifier)) {
        _selectedSourceIds.remove(sourceIdentifier);
      } else {
        _selectedSourceIds.add(sourceIdentifier);
      }
    });
  }
  
  /// Kaynak seçili mi kontrol et (hem ID hem name ile - normalize edilmiş)
  bool _isSourceSelected(SourceModel source) {
    // Direkt eşleşme
    if (_selectedSourceIds.contains(source.id) || 
        _selectedSourceIds.contains(source.name)) {
      return true;
    }
    
    // Normalize edilmiş eşleşme
    final normalizedName = _normalizeForComparison(source.name);
    final normalizedId = _normalizeForComparison(source.id);
    
    for (final selected in _selectedSourceIds) {
      final normalizedSelected = _normalizeForComparison(selected);
      if (normalizedSelected == normalizedName || 
          normalizedSelected == normalizedId ||
          selected.toLowerCase() == source.name.toLowerCase()) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Karşılaştırma için normalize et
  String _normalizeForComparison(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .trim();
  }

  Future<void> _saveAndGoBack() async {
    // Kaydet
    await _storage.write('selected_sources', _selectedSourceIds.toList());
    
    // SourceSelectionController'ı güncelle (ANA KAYNAK)
    if (Get.isRegistered<SourceSelectionController>()) {
      final sourceController = Get.find<SourceSelectionController>();
      // Geçici seçimleri güncelle
      sourceController.tempSelectedSources.clear();
      sourceController.tempSelectedSources.addAll(_selectedSourceIds);
      // Kaydet ve haberleri yenile
      await sourceController.saveAllChanges();
    }
    
    // FollowController'ı güncelle
    if (Get.isRegistered<FollowController>()) {
      Get.find<FollowController>().fetchSources();
    }
    
    Get.back();
    Get.snackbar(
      'Kaydedildi',
      '${_selectedSourceIds.length} kaynak takip ediliyor',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Color _getCategoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('gündem') || c.contains('son dakika')) return const Color(0xFFEF4444);
    if (c.contains('spor')) return const Color(0xFF22C55E);
    if (c.contains('ekonomi') || c.contains('finans')) return const Color(0xFFF59E0B);
    if (c.contains('teknoloji') || c.contains('bilim')) return const Color(0xFF6366F1);
    if (c.contains('yabancı') || c.contains('dünya')) return const Color(0xFF8B5CF6);
    if (c.contains('ajans')) return const Color(0xFF0EA5E9);
    if (c.contains('yerel')) return const Color(0xFF14B8A6);
    return const Color(0xFF64748B);
  }

  List<String> get _categories {
    final cats = _allSources.map((s) => s.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<SourceModel> get _filteredSources {
    var sources = _allSources;
    
    // Kategori filtresi
    if (_selectedCategory != null) {
      sources = sources.where((s) => s.category == _selectedCategory).toList();
    }
    
    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      sources = sources.where((s) => 
        s.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return sources;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A2F47) : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black87),
        ),
        title: Text(
          'Kaynak Ekle',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Takip Et butonu
          TextButton.icon(
            onPressed: _saveAndGoBack,
            icon: const Icon(Icons.check, color: Color(0xFFF4220B)),
            label: const Text(
              'Kaydet',
              style: TextStyle(color: Color(0xFFF4220B), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF4220B)))
          : Column(
              children: [
                // Arama ve Kategori Filtreleri
                _buildFilters(isDark),
                
                // Seçili kaynak sayısı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isDark ? const Color(0xFF132440) : Colors.grey.shade100,
                  child: Text(
                    '${_selectedSourceIds.length} kaynak seçili',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Grid
                Expanded(
                  child: _buildSourcesGrid(isDark),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1A2F47) : Colors.white,
      child: Column(
        children: [
          // Arama
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Kaynak ara...',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
              prefixIcon: Icon(Icons.search, color: isDark ? Colors.white38 : Colors.grey),
              filled: true,
              fillColor: isDark ? const Color(0xFF132440) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),
          // Kategori chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('Tümü', null, isDark),
                ..._categories.map((cat) => _buildCategoryChip(cat, cat, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category, bool isDark) {
    final isSelected = _selectedCategory == category;
    final color = category != null ? _getCategoryColor(category) : const Color(0xFFF4220B);
    
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? const Color(0xFF132440) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF2A4F67) : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSourcesGrid(bool isDark) {
    final sources = _filteredSources;
    
    if (sources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Kaynak bulunamadı',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ],
        ),
      );
    }

    // Kategorilere göre grupla
    final groupedSources = <String, List<SourceModel>>{};
    for (final source in sources) {
      final category = source.category.isNotEmpty ? source.category : 'Diğer';
      groupedSources.putIfAbsent(category, () => []);
      groupedSources[category]!.add(source);
    }

    final sortedCategories = groupedSources.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categorySources = groupedSources[category]!;
        final color = _getCategoryColor(category);

        return _buildCategorySection(category, categorySources, color, isDark);
      },
    );
  }

  Widget _buildCategorySection(String category, List<SourceModel> sources, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori başlığı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getCategoryIcon(category), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${sources.length})',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        // 3'lü Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: sources.length,
            itemBuilder: (context, index) {
              return _buildSourceGridItem(sources[index], color, isDark);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSourceGridItem(SourceModel source, Color color, bool isDark) {
    final isSelected = _isSourceSelected(source);
    final logoUrl = SourceLogos.getLogoUrl(source.name);

    return GestureDetector(
      onTap: () => _toggleSource(source),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2F47) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF4220B) : (isDark ? const Color(0xFF2A4F67) : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFF4220B).withOpacity(0.3), blurRadius: 8)]
              : null,
        ),
        child: Stack(
          children: [
            // İçerik
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => _buildLogoPlaceholder(source, color),
                              errorWidget: (_, __, ___) => _buildLogoPlaceholder(source, color),
                            )
                          : _buildLogoPlaceholder(source, color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // İsim
                  Text(
                    source.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Seçili işareti
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4220B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(SourceModel source, Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Text(
          source.name.isNotEmpty ? source.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('gündem')) return Icons.newspaper;
    if (c.contains('son dakika')) return Icons.flash_on;
    if (c.contains('spor')) return Icons.sports_soccer;
    if (c.contains('ekonomi')) return Icons.trending_up;
    if (c.contains('teknoloji')) return Icons.computer;
    if (c.contains('bilim')) return Icons.science;
    if (c.contains('ajans')) return Icons.rss_feed;
    if (c.contains('yerel')) return Icons.location_city;
    if (c.contains('yabancı') || c.contains('dünya')) return Icons.public;
    return Icons.article;
  }
}
