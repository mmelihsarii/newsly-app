<?php
/**
 * DEBUG AMAÇLI - Önce bunu dene, çalışırsa asıl fonksiyonu ekle
 * 
 * Bu fonksiyonu FeaturedSectionsController.php'ye ekle ve test et
 * Eğer bu çalışırsa, sorun model ilişkilerinde demektir
 */

/*  // TEST 1: Basit test - API çalışıyor mu?
  public function testApi()
  {
      return response()->json([
          'success' => true,
          'message' => 'API çalışıyor',
          'php_version' => PHP_VERSION,
      ]);
  }

  // TEST 2: FeaturedSections tablosu var mı?
  public function testFeaturedSections()
  {
      try {
          $count = FeaturedSections::count();
          $first = FeaturedSections::first();

          return response()->json([
              'success' => true,
              'total_sections' => $count,
              'first_section' => $first ? [
                  'id' => $first->id,
                  'title' => $first->title,
                  'status' => $first->status,
                  'style_app' => $first->style_app,
                  'news_type' => $first->news_type,
              ] : null,
          ]);
      } catch (\Exception $e) {
          return response()->json([
              'success' => false,
              'error' => $e->getMessage(),
              'line' => $e->getLine(),
          ], 500);
      }
  }

  // TEST 3: News tablosu var mı?
  public function testNews()
  {
      try {
          $count = News::count();
          $first = News::with('category')->first();

          return response()->json([
              'success' => true,
              'total_news' => $count,
              'first_news' => $first ? [
                  'id' => $first->id,
                  'title' => $first->title,
                  'category_name' => $first->category?->category_name ?? 'YOK',
                  'source_name' => $first->source_name ?? 'YOK',
              ] : null,
          ]);
      } catch (\Exception $e) {
          return response()->json([
              'success' => false,
              'error' => $e->getMessage(),
              'line' => $e->getLine(),
          ], 500);
      }
  }

/**
* Route'ları api.php'ye ekle:
* 
* Route::get('test_api', [FeaturedSectionsController::class, 'testApi']);
* Route::get('test_featured', [FeaturedSectionsController::class, 'testFeaturedSections']);
* Route::get('test_news', [FeaturedSectionsController::class, 'testNews']);
* 
* Sonra tarayıcıda test et:
* https://admin.newsly.com.tr/api/test_api
* https://admin.newsly.com.tr/api/test_featured
* https://admin.newsly.com.tr/api/test_news
*/
