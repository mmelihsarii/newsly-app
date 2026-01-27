<?php
/**
 * DEBUG FONKSİYONU
 * 
 * Bu fonksiyonu FeaturedSectionsController.php'ye ekle
 * Sonra şu URL'i çağır: https://admin.newsly.com.tr/api/debug_sections
 * 
 * Route ekle (routes/api.php):
 * Route::get('debug_sections', [FeaturedSectionsController::class, 'debugSections']);
 */

public function debugSections()
{
    // TÜM section'ları çek - HİÇBİR FİLTRE YOK
    $allSections = FeaturedSections::all();
    
    $result = [];
    foreach ($allSections as $section) {
        $result[] = [
            'id' => $section->id,
            'title' => $section->title,
            'status' => $section->status,
            'language_id' => $section->language_id,
            'row_order' => $section->row_order,
            'style_app' => $section->style_app,
        ];
    }
    
    return response()->json([
        'total_count' => count($result),
        'sections' => $result,
    ]);
}
