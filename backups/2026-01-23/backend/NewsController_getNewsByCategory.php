<?php
/**
 * BU FONKSİYONU NewsController.php DOSYASINA EKLE
 * Dosya: /home/newslyco/public_html/admin/app/Http/Controllers/NewsController.php
 * 
 * Class'ın içine, diğer fonksiyonların yanına ekle
 */

/**
 * Kategoriye göre haberleri getir - Bildirim paneli için
 * Route: get_news_by_category (GET veya POST)
 */
public function getNewsByCategory(Request $request)
{
    $category_id = $request->category_id;
    
    if (empty($category_id)) {
        return response()->json(['error' => false, 'data' => []]);
    }
    
    try {
        // tbl_news tablosundan haberleri çek
        $news = \DB::table('tbl_news')
            ->where('category_id', $category_id)
            ->where('status', 1)
            ->orderBy('id', 'desc')
            ->limit(100)
            ->get(['id', 'title']);
        
        $data = [];
        foreach ($news as $item) {
            $data[] = [
                'id' => $item->id,
                'value' => $item->title  // Panel'in fetchList fonksiyonu 'value' bekliyor
            ];
        }
        
        return response()->json(['error' => false, 'data' => $data]);
        
    } catch (\Exception $e) {
        \Log::error('getNewsByCategory error: ' . $e->getMessage());
        return response()->json(['error' => true, 'message' => $e->getMessage(), 'data' => []]);
    }
}


/**
 * =====================================================
 * ROUTE TANIMINI DA EKLE
 * =====================================================
 * 
 * Dosya: /home/newslyco/public_html/admin/routes/web.php
 * 
 * Bu satırı ekle (diğer route'ların yanına):
 * 
 * Route::match(['get', 'post'], 'get_news_by_category', [App\Http\Controllers\NewsController::class, 'getNewsByCategory'])->name('get_news_by_category');
 * 
 * VEYA sadece GET:
 * 
 * Route::get('get_news_by_category', [App\Http\Controllers\NewsController::class, 'getNewsByCategory'])->name('get_news_by_category');
 */
