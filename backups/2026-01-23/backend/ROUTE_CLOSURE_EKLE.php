<?php
/**
 * BU KODU routes/web.php DOSYASININ SONUNA EKLE
 * Dosya: /home/newslyco/public_html/admin/routes/web.php
 * 
 * Mevcut get_news_by_category route'unu YORUM SATIRINA AL veya SİL
 * ve bu yeni route'u ekle.
 * 
 * ÖNCELİKLE: Mevcut route'u bul ve yorum satırına al:
 * // Route::get('common/get_news_by_category', ...  eski route
 */

// =====================================================
// YENİ ROUTE - BU KODU EKLE
// =====================================================

Route::get('common/get_news_by_category', function(Illuminate\Http\Request $request) {
    try {
        $category_id = $request->category_id;
        
        if (empty($category_id)) {
            return '<option value="">Haber Seç</option>';
        }
        
        // Doğrudan DB sorgusu - en basit hali
        $news = DB::table('tbl_news')
            ->where('category_id', $category_id)
            ->where('status', 1)
            ->orderBy('id', 'desc')
            ->limit(50)
            ->get(['id', 'title']);
        
        $option = '<option value="">Haber Seç</option>';
        
        foreach ($news as $item) {
            $title = mb_substr($item->title, 0, 80);
            $option .= '<option value="' . $item->id . '">' . htmlspecialchars($title) . '</option>';
        }
        
        return $option;
        
    } catch (\Exception $e) {
        \Log::error('get_news_by_category error: ' . $e->getMessage());
        return '<option value="">Hata: ' . $e->getMessage() . '</option>';
    }
})->name('get_news_by_category');


/**
 * =====================================================
 * SONRA CACHE TEMİZLE:
 * =====================================================
 * 
 * cd /home/newslyco/public_html/admin
 * php artisan route:clear
 * php artisan cache:clear
 * php artisan config:clear
 * 
 * =====================================================
 * HATA AYIKLAMA - LOG KONTROL:
 * =====================================================
 * 
 * tail -50 /home/newslyco/public_html/admin/storage/logs/laravel.log
 */
