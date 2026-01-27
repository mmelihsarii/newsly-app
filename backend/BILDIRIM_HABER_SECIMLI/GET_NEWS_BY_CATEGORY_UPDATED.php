<?php
/**
 * ============================================
 * KATEGORİYE GÖRE HABER LİSTESİ - GÜNCELLEME
 * ============================================
 * 
 * Bu fonksiyonu helpers.php dosyasında bul ve güncelle.
 * Veya web.php'deki route'u güncelle.
 * 
 * SORUN: Bildirim panelinde az haber görünüyor
 * ÇÖZÜM: Limit'i artır (50 -> 500)
 */

// ===== SEÇENEK 1: helpers.php'deki fonksiyonu güncelle =====

if (!function_exists('get_news_by_category')) {
    function get_news_by_category($category_id)
    {
        // 500 habere çıkar (eskiden 50 idi)
        $news = \DB::table('tbl_news')
            ->where('category_id', $category_id)
            ->where('status', 1)
            ->orderBy('id', 'DESC')
            ->take(500)  // <-- BURAYI 500 YAP
            ->get(['id', 'title']);
        
        return $news;
    }
}


// ===== SEÇENEK 2: web.php'deki route'u güncelle =====
/*
Route::post('get_news_by_category', function(Illuminate\Http\Request $request) {
    $category_id = $request->category_id;
    
    if (empty($category_id)) {
        return response()->json([]);
    }
    
    // 500 habere çıkar
    $news = \DB::table('tbl_news')
        ->where('category_id', $category_id)
        ->where('status', 1)
        ->orderBy('id', 'DESC')
        ->take(500)  // <-- BURAYI 500 YAP
        ->get(['id', 'title']);
    
    $result = [];
    foreach ($news as $item) {
        $result[] = [
            'id' => $item->id,
            'name' => mb_substr($item->title, 0, 80) . (mb_strlen($item->title) > 80 ? '...' : ''),
        ];
    }
    
    return response()->json($result);
})->name('get_news_by_category');
*/


// ===== SEÇENEK 3: Tüm haberleri getir (kategori filtresi olmadan) =====
/*
Route::post('get_all_news_for_notification', function(Illuminate\Http\Request $request) {
    $search = $request->search ?? '';
    
    $query = \DB::table('tbl_news')
        ->where('status', 1)
        ->orderBy('id', 'DESC');
    
    if (!empty($search)) {
        $query->where('title', 'LIKE', '%' . $search . '%');
    }
    
    $news = $query->take(500)->get(['id', 'title', 'category_id']);
    
    $result = [];
    foreach ($news as $item) {
        $result[] = [
            'id' => $item->id,
            'name' => mb_substr($item->title, 0, 80) . (mb_strlen($item->title) > 80 ? '...' : ''),
        ];
    }
    
    return response()->json($result);
})->name('get_all_news_for_notification');
*/
