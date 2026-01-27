<?php
/**
 * ============================================
 * DÜZELTİLMİŞ FONKSİYON
 * ============================================
 * 
 * Bu fonksiyonu FeaturedSectionsController.php dosyasındaki
 * mevcut getFeaturedSectionsForApp fonksiyonuyla DEĞİŞTİR
 * 
 * SORUN: language_id filtresi bazı section'ları atlıyor
 * ÇÖZÜM: Önce language_id olmadan dene, sonra filtreli dene
 */

public function getFeaturedSectionsForApp(Request $request)
{
    try {
        $language_id = $request->input('language_id', 2);

        // ÖNCELİKLE TÜM AKTİF SECTION'LARI ÇEK (language filtresi YOK)
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

        if ($sections->isEmpty()) {
            return response()->json([
                'success' => true,
                'data' => [],
                'message' => 'No active sections found'
            ]);
        }

        $result = [];

        foreach ($sections as $section) {
            $styleApp = $section->style_app ?? 'default';
            
            // Type belirleme
            $type = 'horizontal_list';
            if ($styleApp === 'style_1' || $styleApp === 'style_6') {
                $type = 'slider';
            } elseif ($styleApp === 'style_4') {
                $type = 'breaking_news';
            }

            $newsData = [];

            try {
                $newsType = $section->news_type ?? '';

                if ($newsType === 'breaking_news') {
                    $items = \App\Models\BreakingNews::where('status', 1)
                        ->orderBy('created_at', 'DESC')
                        ->take(10)
                        ->get();
                } else {
                    $query = News::where('status', 1);

                    // Custom news IDs
                    if ($section->filter_type === 'custom' && !empty($section->news_ids)) {
                        $ids = array_filter(explode(',', $section->news_ids));
                        if (!empty($ids)) {
                            $query->whereIn('id', $ids);
                        }
                    }

                    // Category filter
                    if (!empty($section->category_ids)) {
                        $catIds = array_filter(explode(',', $section->category_ids));
                        if (!empty($catIds)) {
                            $query->whereIn('category_id', $catIds);
                        }
                    }

                    // Sorting
                    switch ($section->filter_type) {
                        case 'most_viewed':
                            $query->orderBy('total_views', 'DESC');
                            break;
                        case 'most_favorite':
                        case 'most_like':
                            $query->orderBy('total_like', 'DESC');
                            break;
                        default:
                            $query->orderBy('created_at', 'DESC');
                    }

                    $items = $query->with('category')->take(10)->get();
                }

                // Format news items
                foreach ($items as $item) {
                    $imageUrl = null;
                    if (!empty($item->image)) {
                        $imageUrl = (strpos($item->image, 'http') === 0) 
                            ? $item->image 
                            : url('storage/' . $item->image);
                    }

                    $categoryName = $item->category->category_name ?? 'Gündem';

                    // Source name belirleme
                    $sourceName = '';
                    if (!empty($item->source_name) && strtolower(trim($item->source_name)) !== 'genel') {
                        $sourceName = $item->source_name;
                    } else {
                        $sourceName = $categoryName;
                    }

                    $newsData[] = [
                        'id' => (string) $item->id,
                        'title' => $item->title ?? '',
                        'image' => $imageUrl,
                        'date' => $item->created_at ? $item->created_at->format('d M H:i') : '',
                        'categoryName' => $categoryName,
                        'description' => $item->short_description ?? $item->description ?? '',
                        'sourceUrl' => $item->source_url ?? '',
                        'sourceName' => $sourceName,
                    ];
                }

            } catch (\Exception $e) {
                // Hata olursa bu section'ı atla
                continue;
            }

            // Section'ı ekle (haberler boş olsa bile - Flutter'da fallback var)
            $result[] = [
                'id' => $section->id,
                'title' => $section->title ?? '',
                'type' => $type,
                'style_app' => $styleApp,
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
