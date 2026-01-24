<?php
/**
 * =====================================================
 * BU KODU routes/web.php DOSYASINA EKLE
 * =====================================================
 * 
 * Dosya: /home/newslyco/public_html/admin/routes/web.php
 * 
 * ADIMLAR:
 * 1. web.php dosyasını aç
 * 2. Mevcut get_news_by_category route'unu bul ve YORUM SATIRINA AL:
 *    // Route::get('common/get_news_by_category', ...
 * 3. Aşağıdaki kodu dosyanın SONUNA ekle (son }); öncesine)
 * 4. Kaydet
 * 5. Cache temizle: php artisan route:clear && php artisan cache:clear
 */

// =====================================================
// KATEGORİYE GÖRE HABERLERİ GETİR - CLOSURE VERSİYONU
// =====================================================
Route::get('common/get_news_by_category', function(Illuminate\Http\Request $request) {
    try {
        $category_id = $request->category_id;
        
        if (empty($category_id)) {
            return '<option value="">Haber Seç</option>';
        }
        
        $news = DB::table('tbl_news')
            ->where('category_id', $category_id)
            ->where('status', 1)
            ->orderBy('id', 'desc')
            ->limit(50)
            ->get(['id', 'title']);
        
        $option = '<option value="">Haber Seç</option>';
        
        foreach ($news as $item) {
            $title = mb_substr($item->title, 0, 100);
            $option .= '<option value="' . $item->id . '">' . htmlspecialchars($title, ENT_QUOTES, 'UTF-8') . '</option>';
        }
        
        return $option;
        
    } catch (\Exception $e) {
        \Log::error('get_news_by_category error: ' . $e->getMessage());
        return '<option value="">Hata oluştu</option>';
    }
})->name('get_news_by_category');
