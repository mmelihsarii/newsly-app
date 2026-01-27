<?php
/**
 * ============================================
 * TEK SEFERLİK BULK IMPORT - EN HIZLI ÇÖZÜM
 * ============================================
 * 
 * Bu kodu routes/web.php'ye ekle ve browser'dan çağır.
 * 200 kaynağı birkaç saniyede aktarır.
 * 
 * ÖNCESİNDE:
 * 1. composer require kreait/firebase-php
 * 2. Firebase Console > Project Settings > Service Accounts
 * 3. "Generate new private key" tıkla
 * 4. İndirilen JSON'ı storage/app/firebase-credentials.json olarak kaydet
 */

// ============================================
// routes/web.php'ye EKLE:
// ============================================

use Kreait\Firebase\Factory;

Route::get('/admin/import-sources-to-firebase', function() {
    
    // Firebase bağlantısı
    try {
        $factory = (new Factory)
            ->withServiceAccount(storage_path('app/firebase-credentials.json'));
        
        $firestore = $factory->createFirestore()->database();
        $collection = $firestore->collection('news_sources');
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'error' => 'Firebase bağlantı hatası: ' . $e->getMessage(),
            'tip' => 'firebase-credentials.json dosyasını kontrol et'
        ], 500);
    }
    
    // ============================================
    // TABLO ADINI DEĞİŞTİR!
    // Paneldeki kaynak tablosunun adı ne ise onu yaz
    // Örnek: rss_sources, news_sources, sources
    // ============================================
    $tableName = 'rss_sources';
    
    // Tüm aktif kaynakları çek
    $sources = \DB::table($tableName)
        ->where('status', 1)
        ->get();
    
    if ($sources->isEmpty()) {
        return response()->json([
            'success' => false,
            'error' => "Tabloda kaynak bulunamadı: $tableName",
            'tip' => 'Tablo adını kontrol et'
        ]);
    }
    
    $synced = 0;
    $failed = 0;
    $errors = [];
    
    foreach ($sources as $source) {
        try {
            // Firebase field yapısına göre - AYNI YAPIYI KULLAN
            $sourceName = $source->name ?? $source->source_name ?? $source->title ?? '';
            $rssUrl = $source->rss_url ?? $source->url ?? $source->feed_url ?? $source->rss ?? '';
            $category = $source->category ?? $source->category_name ?? $source->cat ?? 'Genel';
            
            // Document ID için slug oluştur (küçük harf, boşluksuz)
            $docId = strtolower(trim($sourceName));
            $docId = preg_replace('/[^a-z0-9]+/', '_', $docId);
            $docId = trim($docId, '_');
            
            // Boş isim veya URL varsa atla
            if (empty($sourceName) || empty($rssUrl)) {
                $failed++;
                $errors[] = "ID {$source->id}: Boş isim veya URL";
                continue;
            }
            
            // Firebase yapısına UYGUN data - ekran görüntüsündeki gibi
            $data = [
                'category' => $category,
                'id' => $docId,
                'is_active' => true,
                'name' => $sourceName,
                'rss_url' => $rssUrl,
            ];
            
            // Firebase'e yaz (document ID = slug formatında)
            $collection->document($docId)->set($data);
            $synced++;
            
        } catch (\Exception $e) {
            $failed++;
            $errors[] = "ID {$source->id}: " . $e->getMessage();
        }
    }
    
    return response()->json([
        'success' => true,
        'message' => "✅ Import tamamlandı!",
        'total' => $sources->count(),
        'synced' => $synced,
        'failed' => $failed,
        'errors' => array_slice($errors, 0, 10), // İlk 10 hata
    ]);
    
})->middleware('auth'); // Admin girişi gerekli

// ============================================
// KULLANIM:
// ============================================
// 1. Admin olarak giriş yap
// 2. Browser'da: https://admin.newsly.com.tr/admin/import-sources-to-firebase
// 3. JSON sonucu göreceksin
// 4. Firebase Console'dan news_sources koleksiyonunu kontrol et
