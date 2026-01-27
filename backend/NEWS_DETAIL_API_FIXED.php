<?php
/**
 * ============================================
 * HABER DETAY API - TAM VERSİYON
 * ============================================
 * 
 * NewsController.php'deki getNewsDetail fonksiyonunu BU İLE DEĞİŞTİR!
 * 
 * Görsel, kaynak adı ve kaynak URL'si dahil TÜM verileri döndürür.
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
        
        // Haberi ID ile bul - category ve language ile birlikte
        $news = \App\Models\News::with(['category', 'language'])->find($newsId);
        
        if (!$news) {
            return response()->json([
                'success' => false,
                'message' => 'Haber bulunamadı',
                'data' => null,
            ], 404);
        }
        
        // ========== GÖRSEL URL ==========
        $imageUrl = null;
        if (!empty($news->image)) {
            // Zaten tam URL mi kontrol et
            if (strpos($news->image, 'http') === 0) {
                $imageUrl = $news->image;
            } else {
                // Storage path'i tam URL'ye çevir
                $imageUrl = url('storage/' . $news->image);
            }
        }
        
        // ========== KATEGORİ ADI ==========
        $categoryName = 'Gündem';
        if ($news->category && !empty($news->category->category_name)) {
            $categoryName = $news->category->category_name;
        }
        
        // ========== KAYNAK URL (Haberin orijinal linki) ==========
        // content_type'a göre kaynak URL'sini belirle
        $sourceUrl = '';
        
        // 1. Önce content_value'ya bak (video URL olabilir)
        if (!empty($news->content_value) && strpos($news->content_value, 'http') === 0) {
            $sourceUrl = $news->content_value;
        }
        
        // 2. source_url alanı varsa onu kullan
        if (empty($sourceUrl) && !empty($news->source_url)) {
            $sourceUrl = $news->source_url;
        }
        
        // 3. other_url alanı varsa onu kullan
        if (empty($sourceUrl) && !empty($news->other_url)) {
            $sourceUrl = $news->other_url;
        }
        
        // ========== KAYNAK ADI ==========
        $sourceName = $categoryName; // Varsayılan olarak kategori adı
        
        // 1. source_name alanı varsa kullan
        if (!empty($news->source_name) && strtolower(trim($news->source_name)) !== 'genel') {
            $sourceName = $news->source_name;
        }
        // 2. Yoksa sourceUrl'den domain çıkar
        elseif (!empty($sourceUrl)) {
            try {
                $parsedUrl = parse_url($sourceUrl);
                if (isset($parsedUrl['host'])) {
                    $host = $parsedUrl['host'];
                    $host = str_replace('www.', '', $host);
                    // Domain'den site adı çıkar (örn: sabah.com.tr -> Sabah)
                    $parts = explode('.', $host);
                    if (count($parts) > 0) {
                        $sourceName = ucfirst($parts[0]);
                    }
                }
            } catch (\Exception $e) {
                // Hata olursa kategori adını kullan
            }
        }
        
        // Kaynak adını kategori ile birleştir (RSS'deki gibi)
        $fullSourceName = $sourceName;
        if ($sourceName !== $categoryName && !empty($categoryName)) {
            $fullSourceName = $sourceName . ' - ' . $categoryName;
        }
        
        // ========== TARİH ==========
        $dateStr = '';
        $publishedAt = null;
        
        // published_date varsa onu kullan, yoksa created_at
        $dateField = $news->published_date ?? $news->created_at;
        
        if ($dateField) {
            try {
                if (is_string($dateField)) {
                    $dateObj = new \DateTime($dateField);
                } else {
                    $dateObj = $dateField;
                }
                $dateStr = $dateObj->format('d M H:i');
                $publishedAt = $dateObj->format('c'); // ISO 8601
            } catch (\Exception $e) {
                $dateStr = (string) $dateField;
            }
        }
        
        // ========== İÇERİK ==========
        $description = $news->description ?? '';
        $content = $news->description ?? ''; // contentValue için de description kullan
        
        // short_description varsa description olarak kullan
        if (!empty($news->short_description)) {
            $description = $news->short_description;
        }
        
        // summarized_description varsa ekle
        if (!empty($news->summarized_description)) {
            $description = $news->summarized_description;
        }
        
        // ========== RESPONSE ==========
        $data = [
            'id' => (string) $news->id,
            'title' => $news->title ?? '',
            'image' => $imageUrl,
            'date' => $dateStr,
            'categoryName' => $categoryName,
            'description' => $description,
            'contentValue' => $content,
            'sourceUrl' => $sourceUrl,
            'sourceName' => $fullSourceName,
            'published_at' => $publishedAt,
        ];
        
        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
        
    } catch (\Exception $e) {
        \Log::error('news_detail hatası: ' . $e->getMessage() . ' - Line: ' . $e->getLine());
        
        return response()->json([
            'success' => false,
            'message' => 'Sunucu hatası: ' . $e->getMessage(),
            'data' => null,
        ], 500);
    }
}
