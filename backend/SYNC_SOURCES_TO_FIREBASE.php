<?php
/**
 * ============================================
 * PANEL KAYNAKLARINI FIREBASE'E AKTAR
 * ============================================
 * 
 * Bu scripti Laravel projesinde çalıştır:
 * php artisan tinker < SYNC_SOURCES_TO_FIREBASE.php
 * 
 * VEYA routes/web.php'ye ekle ve browser'dan çağır
 */

// routes/web.php'ye ekle:
/*
Route::get('/sync-sources-to-firebase', function() {
    return app()->call('App\Http\Controllers\SourceSyncController@syncToFirebase');
});
*/

// ============================================
// CONTROLLER DOSYASI OLUŞTUR:
// app/Http/Controllers/SourceSyncController.php
// ============================================

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\RssSource; // veya NewsSource - tablonun adına göre değiştir
use Kreait\Firebase\Factory;
use Kreait\Firebase\ServiceAccount;

class SourceSyncController extends Controller
{
    public function syncToFirebase()
    {
        // Firebase Admin SDK
        $factory = (new Factory)
            ->withServiceAccount(storage_path('app/firebase-credentials.json'))
            ->withDatabaseUri(env('FIREBASE_DATABASE_URL'));
        
        $firestore = $factory->createFirestore();
        $database = $firestore->database();
        $collection = $database->collection('news_sources');
        
        // Panel'deki tüm kaynakları çek
        // Tablo adını kendi projenize göre değiştirin: rss_sources, news_sources, sources vs.
        $sources = \DB::table('rss_sources')->get();
        
        $synced = 0;
        $errors = [];
        
        foreach ($sources as $source) {
            try {
                // Firebase'e kaydet
                $docRef = $collection->document((string) $source->id);
                
                $docRef->set([
                    'name' => $source->name ?? $source->source_name ?? '',
                    'rss_url' => $source->rss_url ?? $source->url ?? $source->feed_url ?? '',
                    'category' => $source->category ?? $source->category_name ?? 'Genel',
                    'logo_url' => $source->logo ?? $source->logo_url ?? $source->image ?? '',
                    'is_active' => (bool) ($source->status ?? $source->is_active ?? true),
                    'created_at' => now()->toDateTimeString(),
                    'updated_at' => now()->toDateTimeString(),
                ]);
                
                $synced++;
                
            } catch (\Exception $e) {
                $errors[] = "ID {$source->id}: " . $e->getMessage();
            }
        }
        
        return response()->json([
            'success' => true,
            'message' => "$synced kaynak Firebase'e aktarıldı",
            'total' => count($sources),
            'synced' => $synced,
            'errors' => $errors,
        ]);
    }
}
