<?php
/**
 * ============================================
 * PANEL KAYNAKLARINI FIREBASE'E AKTAR (BASIT)
 * ============================================
 * 
 * Firebase Admin SDK gerektirmez!
 * Firestore REST API kullanır.
 * 
 * KULLANIM:
 * 1. Bu dosyayı Laravel projesine kopyala
 * 2. routes/web.php'ye route ekle
 * 3. Browser'dan çağır: /admin/sync-sources-firebase
 */

// ============================================
// routes/web.php'ye EKLE:
// ============================================
/*
Route::get('/admin/sync-sources-firebase', function() {
    
    // Firebase proje bilgileri
    $projectId = 'FIREBASE_PROJECT_ID'; // Firebase Console'dan al
    
    // Panel'deki kaynakları çek
    // TABLO ADINI DEĞİŞTİR: rss_sources, news_sources, sources vs.
    $sources = \DB::table('rss_sources')
        ->where('status', 1) // Sadece aktif olanlar
        ->get();
    
    $synced = 0;
    $errors = [];
    
    foreach ($sources as $source) {
        try {
            // Firestore document verisi
            $data = [
                'fields' => [
                    'name' => ['stringValue' => $source->name ?? $source->source_name ?? ''],
                    'rss_url' => ['stringValue' => $source->rss_url ?? $source->url ?? $source->feed_url ?? ''],
                    'category' => ['stringValue' => $source->category ?? $source->category_name ?? 'Genel'],
                    'logo_url' => ['stringValue' => $source->logo ?? $source->logo_url ?? $source->image ?? ''],
                    'is_active' => ['booleanValue' => true],
                    'panel_id' => ['integerValue' => (string) $source->id],
                ]
            ];
            
            // Firestore REST API
            $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/news_sources";
            
            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            
            if ($httpCode >= 200 && $httpCode < 300) {
                $synced++;
            } else {
                $errors[] = "ID {$source->id}: HTTP $httpCode";
            }
            
        } catch (\Exception $e) {
            $errors[] = "ID {$source->id}: " . $e->getMessage();
        }
    }
    
    return response()->json([
        'success' => true,
        'message' => "$synced kaynak Firebase'e aktarıldı",
        'total' => $sources->count(),
        'synced' => $synced,
        'errors' => $errors,
    ]);
});
*/

// ============================================
// VEYA: Artisan Command olarak
// ============================================
/*
php artisan make:command SyncSourcesToFirebase

// app/Console/Commands/SyncSourcesToFirebase.php içine:

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Kreait\Firebase\Factory;

class SyncSourcesToFirebase extends Command
{
    protected $signature = 'sources:sync-firebase';
    protected $description = 'Panel kaynaklarını Firebase\'e aktar';

    public function handle()
    {
        $factory = (new Factory)
            ->withServiceAccount(storage_path('app/firebase-credentials.json'));
        
        $firestore = $factory->createFirestore()->database();
        $collection = $firestore->collection('news_sources');
        
        $sources = \DB::table('rss_sources')->where('status', 1)->get();
        
        $bar = $this->output->createProgressBar($sources->count());
        $bar->start();
        
        $synced = 0;
        
        foreach ($sources as $source) {
            try {
                $collection->document((string) $source->id)->set([
                    'name' => $source->name ?? '',
                    'rss_url' => $source->rss_url ?? $source->url ?? '',
                    'category' => $source->category ?? 'Genel',
                    'logo_url' => $source->logo ?? '',
                    'is_active' => true,
                ]);
                $synced++;
            } catch (\Exception $e) {
                $this->error("\nHata ID {$source->id}: " . $e->getMessage());
            }
            $bar->advance();
        }
        
        $bar->finish();
        $this->info("\n$synced kaynak aktarıldı!");
    }
}

// Çalıştır:
// php artisan sources:sync-firebase
*/
