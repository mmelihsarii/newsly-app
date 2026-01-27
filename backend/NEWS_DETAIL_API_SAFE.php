<?php
/**
 * ============================================
 * HABER DETAY API - GÜVENLİ VERSİYON
 * ============================================
 * 
 * Bu fonksiyonu NewsController.php'deki getNewsDetail ile DEĞİŞTİR!
 * 
 * Sadece News tablosunda GERÇEKTEN olan alanları kullanır.
 * source_name, source_url gibi olmayan alanları KULLANMAZ.
 */

public function getNewsDetail(Request $request)
{
    try {
        $newsId = $request->input('id');
        
        if (empty($newsId)) {
            return response()->json([
                'success' => false,
                'message' => 'Haber ID gerekli',
                'data' => null,
            ], 400);
        }
        
        // Haberi ID ile bul
        $news = \App\Models\News::with('category')->find($newsId);
        
        if (!$news) {
            return response()->json([
                'success' => false,
                'message' => 'Haber bulunamadı',
                'data' => null,
            ], 404);
        }
        
        // Görsel URL'sini düzelt - GÜVENLİ
        $imageUrl = '';
        if (!empty($news->image)) {
            if (strpos($news->image, 'http') === 0) {
                $imageUrl = $news->image;
            } else {
                $imageUrl = url('storage/' . $news->image);
            }
        }
        
        // Kategori adı - GÜVENLİ
        $categoryName = 'Gündem';
        if ($news->category && isset($news->category->category_name)) {
            $categoryName = $news->category->category_name;
        }
        
        // Tarih formatla - GÜVENLİ
        $dateStr = '';
        if ($news->created_at) {
            try {
                $dateStr = $news->created_at->format('d M H:i');
            } catch (\Exception $e) {
                $dateStr = (string) $news->created_at;
            }
        }
        
        // published_at - GÜVENLİ
        $publishedAt = null;
        if ($news->created_at) {
            try {
                $publishedAt = $news->created_at->toIso8601String();
            } catch (\Exception $e) {
                $publishedAt = null;
            }
        }
        
        // Video URL - content_value alanından
        $sourceUrl = '';
        if (!empty($news->content_value)) {
            $sourceUrl = $news->content_value;
        }
        
        // Response data - SADECE VAR OLAN ALANLAR
        $data = [
            'id' => (string) $news->id,
            'title' => $news->title ?? '',
            'image' => $imageUrl,
            'date' => $dateStr,
            'categoryName' => $categoryName,
            'description' => $news->description ?? '',
            'contentValue' => $news->description ?? '',
            'sourceUrl' => $sourceUrl,
            'sourceName' => $categoryName, // source_name yok, kategori adını kullan
            'published_at' => $publishedAt,
        ];
        
        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
        
    } catch (\Exception $e) {
        // HATA DETAYINI LOGLA
        \Log::error('news_detail hatası: ' . $e->getMessage() . ' - Line: ' . $e->getLine() . ' - File: ' . $e->getFile());
        
        return response()->json([
            'success' => false,
            'message' => 'Sunucu hatası: ' . $e->getMessage(),
            'data' => null,
        ], 500);
    }
}


/**
 * ============================================
 * DEBUG İÇİN - HANGİ ALANLAR VAR KONTROL ET
 * ============================================
 * 
 * Bu fonksiyonu da ekle ve /api/debug_news?id=215003 ile test et
 * Hangi alanların var olduğunu göreceksin
 */

public function debugNews(Request $request)
{
    try {
        $newsId = $request->input('id', 215003);
        
        $news = \App\Models\News::find($newsId);
        
        if (!$news) {
            return response()->json([
                'success' => false,
                'message' => 'Haber bulunamadı',
            ]);
        }
        
        // Tüm alanları döndür
        return response()->json([
            'success' => true,
            'table_columns' => array_keys($news->getAttributes()),
            'data' => $news->toArray(),
        ]);
        
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'error' => $e->getMessage(),
            'line' => $e->getLine(),
        ]);
    }
}

// Route ekle: Route::get('debug_news', [NewsController::class, 'debugNews']);
