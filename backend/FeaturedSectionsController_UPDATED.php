<?php
/**
 * ============================================
 * FEATURED SECTIONS CONTROLLER - GÜNCELLENMIŞ
 * ============================================
 * 
 * Bu dosya slider ve news section'ların AYRI AYRI kontrol edilmesini sağlar.
 * Panel'den her section kendi haberleriyle birlikte gelir.
 * 
 * KURULUM:
 * 1. app/Http/Controllers/FeaturedSectionsController.php dosyasını aç
 * 2. getFeaturedSectionsForApp fonksiyonunu bu dosyadaki ile değiştir
 * 3. Kaydet
 * 
 * API KULLANIMI:
 * GET /api/get_featured_sections
 * 
 * RESPONSE FORMATI:
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "id": 1,
 *       "title": "Manşet",
 *       "type": "slider",
 *       "is_active": true,
 *       "order": 0,
 *       "news": [...]
 *     },
 *     {
 *       "id": 2,
 *       "title": "Son Dakika",
 *       "type": "breaking_news",
 *       "is_active": true,
 *       "order": 1,
 *       "news": [...]
 *     }
 *   ]
 * }
 */

/**
 * Flutter uygulaması için API endpoint
 * GET /api/get_featured_sections
 * 
 * Slider ve news section'lar AYRI AYRI döner
 * Her section kendi haberlerini içerir
 */
public function getFeaturedSectionsForApp(Request $request)
{
    try {
        // Varsayılan language_id = 2 (Türkçe)
        $language_id = $request->input('language_id', 2);

        // Aktif section'ları çek
        $sections = FeaturedSections::where('status', 1)
            ->where('language_id', $language_id)
            ->orderBy('row_order', 'ASC')
            ->get();

        // Eğer section yoksa boş dön
        if ($sections->isEmpty()) {
            return response()->json([
                'success' => true,
                'data' => [],
                'message' => 'Aktif section bulunamadı'
            ]);
        }

        $result = [];

        foreach ($sections as $section) {
            // Tip belirleme (style_app'e göre)
            $type = $this->getTypeFromStyle($section->style_app);

            // Haberleri çek
            $newsData = $this->getNewsForSection($section);

            // Section'ı ekle (haberler boş olsa bile - Flutter tarafında fallback var)
            $result[] = [
                'id' => $section->id,
                'title' => $section->title,
                'type' => $type,
                'is_active' => true,
                'order' => $section->row_order ?? 0,
                'style_app' => $section->style_app,
                'news' => $newsData,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $result,
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

/**
 * Style'dan type belirle
 */
private function getTypeFromStyle($style)
{
    switch ($style) {
        case 'style_1':
        case 'style_6':
            return 'slider';
        case 'style_4':
            return 'breaking_news';
        default:
            return 'horizontal_list';
    }
}

/**
 * Section için haberleri çek
 */
private function getNewsForSection($section)
{
    $newsData = [];
    
    try {
        if ($section->news_type == 'breaking_news') {
            // Son dakika haberleri
            $items = BreakingNews::where('language_id', $section->language_id)
                ->where('status', 1)
                ->orderBy('created_at', 'DESC')
                ->take($section->news_count ?? 10)
                ->get();
        } else {
            // Normal haberler
            $query = News::where('status', 1)
                ->where('language_id', $section->language_id);

            // Custom ise belirli ID'leri çek
            if ($section->filter_type == 'custom' && !empty($section->news_ids)) {
                $ids = array_filter(explode(',', $section->news_ids));
                if (!empty($ids)) {
                    $query->whereIn('id', $ids);
                }
            }

            // Kategori filtresi
            if (!empty($section->category_ids)) {
                $catIds = array_filter(explode(',', $section->category_ids));
                if (!empty($catIds)) {
                    $query->whereIn('category_id', $catIds);
                }
            }

            // Sıralama
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

            $items = $query->with('category')
                ->take($section->news_count ?? 10)
                ->get();
        }

        // Haberleri Flutter formatına çevir
        foreach ($items as $item) {
            $newsData[] = $this->formatNewsItem($item);
        }
        
    } catch (\Exception $e) {
        \Log::error('Section news fetch error: ' . $e->getMessage());
    }

    return $newsData;
}

/**
 * Haber item'ını Flutter formatına çevir
 */
private function formatNewsItem($item)
{
    // Resim URL'ini düzelt
    $imageUrl = null;
    if (!empty($item->image)) {
        $imageUrl = (substr($item->image, 0, 4) === 'http') 
            ? $item->image 
            : url('storage/' . $item->image);
    }

    return [
        'id' => (string) $item->id,
        'title' => $item->title ?? '',
        'image' => $imageUrl,
        'date' => $item->created_at ? $item->created_at->format('d M H:i') : '',
        'categoryName' => $item->category->category_name ?? 'Gündem',
        'categoryId' => $item->category_id ?? null,
        'description' => $item->short_description ?? '',
        'sourceUrl' => $item->source_url ?? '',
        'sourceName' => $item->source_name ?? '',
    ];
}

/**
 * ============================================
 * ROUTE TANIMLAMASI
 * ============================================
 * 
 * routes/api.php dosyasına ekle:
 * 
 * use App\Http\Controllers\FeaturedSectionsController;
 * 
 * Route::get('get_featured_sections', [FeaturedSectionsController::class, 'getFeaturedSectionsForApp']);
 */
