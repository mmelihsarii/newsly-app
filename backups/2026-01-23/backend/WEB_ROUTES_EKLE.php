<?php
/**
 * BU KODU web.php DOSYASINA EKLE
 * Dosya: /home/newslyco/public_html/admin/routes/web.php
 * 
 * Diğer route'ların olduğu yere (genellikle dosyanın sonuna) ekle
 */

// =====================================================
// KATEGORİYE GÖRE HABERLERİ GETİR - BİLDİRİM PANELİ İÇİN
// =====================================================
Route::get('get_news_by_category', function(Illuminate\Http\Request $request) {
    $category_id = $request->category_id;
    
    if (empty($category_id)) {
        return response()->json(['error' => false, 'data' => []]);
    }
    
    // tbl_news tablosundan haberleri çek
    $news = DB::table('tbl_news')
        ->where('category_id', $category_id)
        ->where('status', 1)
        ->orderBy('id', 'desc')
        ->limit(100)
        ->get(['id', 'title']);
    
    $data = [];
    foreach ($news as $item) {
        $data[] = [
            'id' => $item->id,
            'value' => $item->title
        ];
    }
    
    return response()->json(['error' => false, 'data' => $data]);
})->name('get_news_by_category');


// =====================================================
// EĞER YUKARIDA HATA VERİRSE BU ALTERNATİFİ DENE
// =====================================================
/*
Route::get('get_news_by_category', 'App\Http\Controllers\NewsController@getNewsByCategory')->name('get_news_by_category');
*/
