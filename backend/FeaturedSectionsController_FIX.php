<?php
/**
 * ============================================
 * BACKEND DÜZELTMESİ - TÜM SECTION'LARI ÇEK
 * ============================================
 * 
 * SORUN: API sadece bazı section'ları döndürüyor (ID 4 var, ID 5 yok)
 * 
 * ÇÖZÜM: Aşağıdaki fonksiyonu FeaturedSectionsController.php'ye ekle
 * veya mevcut getFeaturedSectionsForApp fonksiyonunu değiştir
 */

public function getFeaturedSectionsForApp(Request $request)
{
    try {
        $language_id = $request->input('language_id', 2);

        // TÜM aktif section'ları çek - status=1 olanlar
        $sections = FeaturedSections::where('status', 1)
            ->where('language_id', $language_id)
            ->orderBy('row_order', 'ASC')
            ->get();

        // DEBUG: Kaç section bulundu
        \Log::info("FeaturedSections API: " . $sections->count() . " section bulundu");

        if ($sections->isEmpty()) {
            // Eğer language_id filtresi sorun yapıyorsa, onsuz dene
            $sections = FeaturedSections::where('status', 1)
                ->orderBy('row_order', 'ASC')
                ->get();
            
            \Log::info("Language filtresi kaldırıldı: " . $sections->count() . " section");
        }

        $result = [];

        foreach ($sections as $section) {
            $result[] = [
                'id' => $section->id,
                'title' => $section->title,
                'type' => $this->getTypeFromStyle($section->style_app),
                'style_app' => $section->style_app,
                'is_active' => true,
                'order' => $section->row_order ?? 0,
                'row_order' => $section->row_order ?? 0,
            ];
            
            \Log::info("Section eklendi: ID={$section->id}, Title={$section->title}");
        }

        return response()->json([
            'success' => true,
            'data' => $result,
            'count' => count($result),
        ]);

    } catch (\Exception $e) {
        \Log::error('FeaturedSections API Error: ' . $e->getMessage());
        
        return response()->json([
            'success' => false,
            'message' => $e->getMessage(),
            'data' => [],
        ], 500);
    }
}

private function getTypeFromStyle($style)
{
    if ($style == 'style_1' || $style == 'style_6') {
        return 'slider';
    }
    return 'news_list';
}

/**
 * ============================================
 * KONTROL ET
 * ============================================
 * 
 * 1. Panel'de her iki section da "Aktif" durumda mı?
 * 2. Her iki section da aynı dil (Turkish) seçili mi?
 * 3. row_order değerleri farklı mı? (0 ve 1 gibi)
 * 
 * Tarayıcıda test et:
 * https://admin.newsly.com.tr/api/get_featured_sections
 * 
 * Eğer hala tek section dönüyorsa, Laravel log'larını kontrol et:
 * storage/logs/laravel.log
 */
