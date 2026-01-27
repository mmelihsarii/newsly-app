<?php
/**
 * ============================================
 * OTOMATİK FIREBASE SYNC - OBSERVER
 * ============================================
 * 
 * Panel'de kaynak eklendiğinde/güncellendiğinde
 * otomatik olarak Firebase'e de yazar.
 * 
 * KURULUM:
 * 1. composer require kreait/firebase-php
 * 2. firebase-credentials.json'ı storage/app/ altına koy
 * 3. Bu observer'ı oluştur
 * 4. Model'e observer'ı bağla
 */

// ============================================
// 1. OBSERVER OLUŞTUR
// app/Observers/RssSourceObserver.php
// ============================================

namespace App\Observers;

use App\Models\RssSource; // Model adını değiştir
use Kreait\Firebase\Factory;

class RssSourceObserver
{
    protected $firestore;
    protected $collection;

    public function __construct()
    {
        try {
            $factory = (new Factory)
                ->withServiceAccount(storage_path('app/firebase-credentials.json'));
            
            $this->firestore = $factory->createFirestore()->database();
            $this->collection = $this->firestore->collection('news_sources');
        } catch (\Exception $e) {
            \Log::error('Firebase bağlantı hatası: ' . $e->getMessage());
        }
    }

    /**
     * Kaynak oluşturulduğunda
     */
    public function created(RssSource $source)
    {
        $this->syncToFirebase($source);
    }

    /**
     * Kaynak güncellendiğinde
     */
    public function updated(RssSource $source)
    {
        $this->syncToFirebase($source);
    }

    /**
     * Kaynak silindiğinde
     */
    public function deleted(RssSource $source)
    {
        try {
            if ($this->collection) {
                $this->collection->document((string) $source->id)->delete();
                \Log::info("Firebase'den silindi: {$source->id}");
            }
        } catch (\Exception $e) {
            \Log::error("Firebase silme hatası: " . $e->getMessage());
        }
    }

    /**
     * Firebase'e sync et
     */
    protected function syncToFirebase(RssSource $source)
    {
        try {
            if (!$this->collection) return;

            $this->collection->document((string) $source->id)->set([
                'name' => $source->name ?? $source->source_name ?? '',
                'rss_url' => $source->rss_url ?? $source->url ?? '',
                'category' => $source->category ?? $source->category_name ?? 'Genel',
                'logo_url' => $source->logo ?? $source->logo_url ?? '',
                'is_active' => (bool) ($source->status ?? $source->is_active ?? true),
                'panel_id' => $source->id,
                'synced_at' => now()->toDateTimeString(),
            ]);

            \Log::info("Firebase'e sync edildi: {$source->id} - {$source->name}");

        } catch (\Exception $e) {
            \Log::error("Firebase sync hatası: " . $e->getMessage());
        }
    }
}

// ============================================
// 2. MODEL'E OBSERVER'I BAĞLA
// app/Models/RssSource.php (veya NewsSource.php)
// ============================================

/*
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Observers\RssSourceObserver;

class RssSource extends Model
{
    protected $table = 'rss_sources'; // Tablo adı
    
    protected static function boot()
    {
        parent::boot();
        static::observe(RssSourceObserver::class);
    }
}
*/

// ============================================
// 3. VEYA AppServiceProvider'da kaydet
// app/Providers/AppServiceProvider.php
// ============================================

/*
use App\Models\RssSource;
use App\Observers\RssSourceObserver;

public function boot()
{
    RssSource::observe(RssSourceObserver::class);
}
*/

// ============================================
// 4. MEVCUT KAYNAKLARI TEK SEFERLIK AKTAR
// routes/web.php veya artisan tinker
// ============================================

/*
Route::get('/admin/bulk-sync-firebase', function() {
    $sources = \App\Models\RssSource::where('status', 1)->get();
    
    $factory = (new \Kreait\Firebase\Factory)
        ->withServiceAccount(storage_path('app/firebase-credentials.json'));
    
    $firestore = $factory->createFirestore()->database();
    $collection = $firestore->collection('news_sources');
    
    $synced = 0;
    
    foreach ($sources as $source) {
        try {
            $collection->document((string) $source->id)->set([
                'name' => $source->name ?? '',
                'rss_url' => $source->rss_url ?? $source->url ?? '',
                'category' => $source->category ?? 'Genel',
                'logo_url' => $source->logo ?? '',
                'is_active' => (bool) $source->status,
                'panel_id' => $source->id,
            ]);
            $synced++;
        } catch (\Exception $e) {
            // Hata logla
        }
    }
    
    return "✅ $synced kaynak Firebase'e aktarıldı!";
});
*/
