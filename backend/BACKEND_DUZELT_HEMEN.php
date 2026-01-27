<?php
/**
 * ============================================
 * BACKEND DÜZELTMESİ - HEMEN YAP
 * ============================================
 * 
 * SORUN: API sadece ID 4'ü döndürüyor, ID 5 (Öne Çıkanlar) gelmiyor
 * 
 * ADIM 1: Laravel projesinde şu dosyayı aç:
 *         app/Http/Controllers/FeaturedSectionsController.php
 * 
 * ADIM 2: getFeaturedSectionsForApp fonksiyonunu BUL ve SİL
 * 
 * ADIM 3: Aşağıdaki fonksiyonu YAPISTIR
 */

public function getFeaturedSectionsForApp(Request $request)
{
    try {
        $language_id = $request->input('language_id', 2);

        // TÜM aktif section'ları çek - FİLTRE YOK
        $sections = FeaturedSections::where('status', 1)
            ->orderBy('row_order', 'ASC')
            ->get();

        // Eğer boşsa language filtresiyle dene
        if ($sections->isEmpty()) {
            $sections = FeaturedSections::where('status', 1)
                ->where('language_id', $language_id)
                ->orderBy('row_order', 'ASC')
                ->get();
        }

        $result = [];

        foreach ($sections as $section) {
            // Tip belirleme
            $type = 'horizontal_list';
            if ($section->style_app == 'style_1' || $section->style_app == 'style_6') {
                $type = 'slider';
            }

            // Haberleri çek
            $newsData = [];
            
            if ($section->news_type == 'breaking_news') {
                $items = \App\Models\BreakingNews::where('language_id', $section->language_id)
                    ->where('status', 1)
                    ->orderBy('created_at', 'DESC')
                    ->take(10)
                    ->get();
            } else {
                $query = \App\Models\News::where('status', 1);

                if (!empty($section->category_ids)) {
                    $catIds = array_filter(explode(',', $section->category_ids));
                    if (!empty($catIds)) {
                        $query->whereIn('category_id', $catIds);
                    }
                }

                switch ($section->filter_type) {
                    case 'most_viewed':
                        $query->orderBy('total_views', 'DESC');
                        break;
                    default:
                        $query->orderBy('created_at', 'DESC');
                }

                $items = $query->with('category')->take(10)->get();
            }

            foreach ($items as $item) {
                $imageUrl = null;
                if (!empty($item->image)) {
                    $imageUrl = (substr($item->image, 0, 4) === 'http') 
                        ? $item->image 
                        : url('storage/' . $item->image);
                }

                $newsData[] = [
                    'id' => (string) $item->id,
                    'title' => $item->title ?? '',
                    'image' => $imageUrl,
                    'date' => $item->created_at ? $item->created_at->format('d M H:i') : '',
                    'categoryName' => $item->category->category_name ?? 'Gündem',
                    'description' => $item->short_description ?? '',
                    'sourceUrl' => $item->source_url ?? '',
                    'sourceName' => $item->source_name ?? '',
                ];
            }

            // Section'ı ekle
            $result[] = [
                'id' => $section->id,
                'title' => $section->title,
                'type' => $type,
                'style_app' => $section->style_app,
                'is_active' => true,
                'order' => $section->row_order ?? 0,
                'row_order' => $section->row_order ?? 0,
                'news' => $newsData,
            ];
        }

        // row_order'a göre sırala
        usort($result, function($a, $b) {
            return ($a['row_order'] ?? 999) - ($b['row_order'] ?? 999);
        });

        return response()->json([
            'success' => true,
            'data' => $result,
        ]);

    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => $e->getMessage(),
            'data' => [],
        ], 500);
    }
}

/**
 * ============================================
 * KONTROL LİSTESİ
 * ============================================
 * 
 * Panel'de kontrol et:
 * 
 * 1. ID 5 (Öne Çıkanlar) -> Durum: AKTİF mi?
 * 2. ID 5 -> Satır Sırası: 0 olmalı (slider üstte)
 * 3. ID 4 (Haberler) -> Satır Sırası: 1 olmalı (news altta)
 * 4. ID 5 -> App Style: style_1 seçili mi? (slider için)
 * 
 * Fonksiyonu değiştirdikten sonra test et:
 * https://admin.newsly.com.tr/api/get_featured_sections
 * 
 * 2 section dönmeli:
 * - ID 5: Öne Çıkanlar (type: slider)
 * - ID 4: Haberler (type: horizontal_list)
 */
