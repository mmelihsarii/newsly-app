<?php
/**
 * ============================================
 * HABER DETAY API - BACKEND'E EKLE
 * ============================================
 * 
 * ⚠️ ÖNEMLİ: Bu fonksiyonu NewsController.php dosyasına KOPYALA!
 * 
 * Route: /api/news_detail?id=123
 * 
 * BU API OLMADAN BİLDİRİMDEN HABERE GİTME ÇALIŞMAZ!
 * 
 * HATA: 500 Server Error alıyorsan bu endpoint backend'de YOK demektir!
 */

// ===== 1. ROUTE EKLE (routes/api.php) =====
// Bu satırı routes/api.php dosyasına ekle:
//
// Route::get('news_detail', [NewsController::class, 'getNewsDetail']);
//

// ===== 2. CONTROLLER FONKSİYONU =====
// Bu fonksiyonu app/Http/Controllers/Api/NewsController.php dosyasına ekle:

/**
 * Haber detayını ID ile getir
 * 
 * @param Request $request
 * @return \Illuminate\Http\JsonResponse
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
        
        // Haberi ID ile bul - status kontrolü YAPMA çünkü bildirim gönderilmiş haber aktif olmalı
        $news = \App\Models\News::with('category')->find($newsId);
        
        if (!$news) {
            return response()->json([
                'success' => false,
                'message' => 'Haber bulunamadı',
                'data' => null,
            ], 404);
        }
        
        // Görsel URL'sini düzelt
        $imageUrl = null;
        if (!empty($news->image)) {
            if (strpos($news->image, 'http') === 0) {
                $imageUrl = $news->image;
            } else {
                $imageUrl = url('storage/' . $news->image);
            }
        }
        
        // Kategori adı
        $categoryName = 'Gündem';
        if ($news->category) {
            $categoryName = $news->category->category_name ?? 'Gündem';
        }
        
        // Kaynak adı
        $sourceName = $news->source_name ?? '';
        if (empty($sourceName) || strtolower(trim($sourceName)) === 'genel') {
            if (!empty($news->source_url)) {
                try {
                    $parsedUrl = parse_url($news->source_url);
                    $host = $parsedUrl['host'] ?? '';
                    $sourceName = str_replace('www.', '', $host);
                } catch (\Exception $e) {
                    $sourceName = $categoryName;
                }
            } else {
                $sourceName = $categoryName;
            }
        }
        
        // Tam içerik
        $content = $news->content ?? $news->description ?? '';
        
        $data = [
            'id' => (string) $news->id,
            'title' => $news->title ?? '',
            'image' => $imageUrl,
            'date' => $news->created_at ? $news->created_at->format('d M H:i') : '',
            'categoryName' => $categoryName,
            'description' => $news->short_description ?? $news->description ?? '',
            'contentValue' => $content,
            'sourceUrl' => $news->source_url ?? $news->other_url ?? '',
            'sourceName' => $sourceName,
            'published_at' => $news->created_at ? $news->created_at->toIso8601String() : null,
        ];
        
        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
        
    } catch (\Exception $e) {
        \Log::error('news_detail hatası: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => 'Sunucu hatası: ' . $e->getMessage(),
            'data' => null,
        ], 500);
    }
}


/**
 * ============================================
 * BİLDİRİM PANELİ İÇİN HABER LİSTESİ
 * ============================================
 * 
 * Bildirim gönderirken haber seçmek için kullanılır.
 * Daha fazla haber gösterir (son 500 haber).
 */

// Route: /api/news_for_notification
/*
Route::get('news_for_notification', [NewsController::class, 'getNewsForNotification']);
*/

public function getNewsForNotification(Request $request)
{
    try {
        $limit = $request->input('limit', 500);
        $search = $request->input('search', '');
        
        $query = News::with('category')
            ->where('status', 1)
            ->orderBy('created_at', 'DESC');
        
        // Arama varsa filtrele
        if (!empty($search)) {
            $query->where('title', 'LIKE', '%' . $search . '%');
        }
        
        $news = $query->take($limit)->get();
        
        $result = [];
        foreach ($news as $item) {
            $imageUrl = null;
            if (!empty($item->image)) {
                $imageUrl = (strpos($item->image, 'http') === 0) 
                    ? $item->image 
                    : url('storage/' . $item->image);
            }
            
            $result[] = [
                'id' => (string) $item->id,
                'title' => $item->title ?? '',
                'image' => $imageUrl,
                'date' => $item->created_at ? $item->created_at->format('d M H:i') : '',
                'categoryName' => $item->category->category_name ?? 'Gündem',
            ];
        }
        
        return response()->json([
            'success' => true,
            'data' => $result,
            'total' => count($result),
        ]);
        
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => $e->getMessage(),
            'data' => [],
        ], 500);
    }
}
