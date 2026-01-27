<?php
/**
 * web.php dosyasına bu route'u ekle
 * 
 * Route::group(['prefix' => 'common'], ...) bloğunun içine ekle
 */

// Bildirim için haber detaylarını getir (title, description, image)
Route::post('get_news_details_for_notification', function(Illuminate\Http\Request $request) {
    try {
        $news_id = $request->news_id;
        
        if (empty($news_id)) {
            return response()->json([
                'error' => true,
                'message' => 'Haber ID gerekli'
            ]);
        }
        
        $news = \DB::table('tbl_news')
            ->where('id', $news_id)
            ->where('status', 1)
            ->first(['id', 'title', 'description', 'image']);
        
        if (!$news) {
            return response()->json([
                'error' => true,
                'message' => 'Haber bulunamadı'
            ]);
        }
        
        // Description'dan HTML taglerini temizle ve kısalt
        $description = strip_tags($news->description ?? '');
        $description = html_entity_decode($description, ENT_QUOTES, 'UTF-8');
        $description = preg_replace('/\s+/', ' ', $description);
        $description = trim($description);
        
        // Bildirim için max 150 karakter
        if (mb_strlen($description) > 150) {
            $description = mb_substr($description, 0, 147) . '...';
        }
        
        // Image URL oluştur
        $image = '';
        if (!empty($news->image)) {
            $imagePath = $news->image;
            if (strpos($imagePath, 'news/') === false) {
                $imagePath = 'news/' . $imagePath;
            }
            if (\Storage::disk('public')->exists($imagePath)) {
                $image = url(\Storage::url($imagePath));
            }
        }
        
        return response()->json([
            'error' => false,
            'data' => [
                'id' => $news->id,
                'title' => $news->title,
                'description' => $description,
                'image' => $image,
            ]
        ]);
        
    } catch (\Exception $e) {
        \Log::error('get_news_details_for_notification error: ' . $e->getMessage());
        return response()->json([
            'error' => true,
            'message' => 'Bir hata oluştu'
        ]);
    }
})->name('get_news_details_for_notification');
