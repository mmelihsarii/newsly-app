<?php
/**
 * ============================================
 * SADECE BU FONKSİYONU EKLE
 * ============================================
 * 
 * ADIM 1: app/Http/Controllers/FeaturedSectionsController.php dosyasını aç
 * ADIM 2: Dosyanın EN SONUNA, son } karakterinden ÖNCE bu kodu yapıştır
 * ADIM 3: Kaydet
 * 
 * NOT: Aşağıdaki kodu olduğu gibi kopyala, <?php tagını KOPYALAMA!
 */

// ============================================
// FLUTTER API - BU FONKSİYONU EKLE
// ============================================

/**
 * Flutter uygulaması için API endpoint
 * GET /api/get_featured_sections
 *//*
public function getFeaturedSectionsForApp(Request $request)
{
  try {
      // Varsayılan language_id = 2 (Türkçe)
      $language_id = $request->input('language_id', 2);

      // DEBUG: Tüm section'ları say
      $totalCount = FeaturedSections::count();
      $activeCount = FeaturedSections::where('status', 1)->count();
      $langCount = FeaturedSections::where('status', 1)
          ->where('language_id', $language_id)
          ->count();

      // Aktif section'ları çek
      $sections = FeaturedSections::where('status', 1)
          ->where('language_id', $language_id)
          ->orderBy('row_order', 'ASC')
          ->get();

      // DEBUG: Eğer section yoksa bilgi ver
      if ($sections->isEmpty()) {
          return response()->json([
              'success' => false,
              'message' => 'Section bulunamadı',
              'debug' => [
                  'total_sections' => $totalCount,
                  'active_sections' => $activeCount,
                  'language_' . $language_id . '_sections' => $langCount,
                  'requested_language_id' => $language_id,
              ],
              'data' => [],
          ]);
      }

      $result = [];

      foreach ($sections as $section) {
          // Tip belirleme (style_app'e göre)
          switch ($section->style_app) {
              case 'style_1':
              case 'style_6':
                  $type = 'slider';
                  break;
              case 'style_4':
                  $type = 'breaking_news';
                  break;
              default:
                  $type = 'horizontal_list';
          }

          // Haberleri çek
          $newsData = [];

          if ($section->news_type == 'breaking_news') {
              // Son dakika haberleri
              $items = BreakingNews::where('language_id', $section->language_id)
                  ->where('status', 1)
                  ->orderBy('created_at', 'DESC')
                  ->take(10)
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

              $items = $query->with('category')->take(10)->get();
          }

          // Haberleri Flutter formatına çevir
          foreach ($items as $item) {
              // Resim URL'ini düzelt
              $imageUrl = null;
              if (!empty($item->image)) {
                  // PHP 7 uyumlu: str_starts_with yerine substr kullan
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

          // Haber varsa ekle
          if (!empty($newsData)) {
              $result[] = [
                  'id' => $section->id,
                  'title' => $section->title,
                  'type' => $type,
                  'is_active' => true,
                  'order' => $section->row_order,
                  'news' => $newsData,
              ];
          }
      }

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
* ADIM 2: ROUTE EKLE
* ============================================
* 
* routes/api.php dosyasını aç ve şu satırı ekle:
* 
* En üste (use satırlarının yanına):
* use App\Http\Controllers\FeaturedSectionsController;
* 
* Route tanımlarının arasına:
* Route::get('get_featured_sections', [FeaturedSectionsController::class, 'getFeaturedSectionsForApp']);
*/
