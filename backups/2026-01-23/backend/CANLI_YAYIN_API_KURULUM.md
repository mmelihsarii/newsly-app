# Canlı Yayın API Kurulumu

Admin panelden canlı yayınları Flutter uygulamasına çekmek için yapılan kurulum.

---

## Özet

- **Tablo:** `tbl_live_streaming`
- **Controller:** `app/Http/Controllers/LiveStreamingController.php`
- **View:** `resources/views/live-streaming.blade.php`
- **API Endpoint:** `GET https://admin.newsly.com.tr/api/get_live_streams`

---

## Veritabanı Tablosu

Tablo adı: `tbl_live_streaming`

| Kolon | Tip | Açıklama |
|-------|-----|----------|
| id | int | Primary key |
| language_id | int | Dil ID (varsayılan: 1) |
| title | varchar | Yayın başlığı |
| image | varchar | Thumbnail görsel |
| type | varchar | Yayın tipi (url_youtube, m3u8, vb.) |
| url | varchar | YouTube veya stream linki |
| meta_title | varchar | SEO başlık |
| meta_description | text | SEO açıklama |
| meta_keyword | varchar | SEO anahtar kelimeler |
| schema_markup | text | Schema markup |
| created_at | timestamp | Oluşturulma tarihi |
| updated_at | timestamp | Güncellenme tarihi |

---

## LiveStreamingController.php

Dosya yolu: `app/Http/Controllers/LiveStreamingController.php`

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LiveStreamingController extends Controller
{
    /**
     * Panel için canlı yayın listesi sayfası
     */
    public function index()
    {
        $languageList = DB::table('tbl_language')->get();
        $streams = DB::table('tbl_live_streaming')->get();
        
        return view('live-streaming', compact('languageList', 'streams'));
    }

    /**
     * DataTable için liste
     */
    public function show(Request $request)
    {
        $streams = DB::table('tbl_live_streaming')->get();
        return response()->json($streams);
    }

    /**
     * Yeni canlı yayın kaydet
     */
    public function store(Request $request)
    {
        $data = [
            'language_id' => $request->language_id ?? 1,
            'title' => $request->title,
            'image' => $request->image,
            'type' => $request->type,
            'url' => $request->url,
            'meta_title' => $request->meta_title,
            'meta_description' => $request->meta_description,
            'meta_keyword' => $request->meta_keyword,
            'schema_markup' => $request->schema_markup,
            'created_at' => now(),
            'updated_at' => now(),
        ];
        
        DB::table('tbl_live_streaming')->insert($data);
        return response()->json(['success' => true]);
    }

    /**
     * Canlı yayın güncelle
     */
    public function update(Request $request, $id)
    {
        $data = [
            'language_id' => $request->language_id ?? 1,
            'title' => $request->title,
            'image' => $request->image,
            'type' => $request->type,
            'url' => $request->url,
            'meta_title' => $request->meta_title,
            'meta_description' => $request->meta_description,
            'meta_keyword' => $request->meta_keyword,
            'schema_markup' => $request->schema_markup,
            'updated_at' => now(),
        ];
        
        DB::table('tbl_live_streaming')->where('id', $id)->update($data);
        return response()->json(['success' => true]);
    }

    /**
     * Canlı yayın sil
     */
    public function destroy($id)
    {
        DB::table('tbl_live_streaming')->where('id', $id)->delete();
        return response()->json(['success' => true]);
    }

    /**
     * Flutter uygulaması için API endpoint
     */
    public function getLiveStreamsForApp()
    {
        try {
            $streams = DB::table('tbl_live_streaming')
                ->orderBy('id', 'asc')
                ->get();

            $formattedStreams = $streams->map(function ($stream) {
                // YouTube video ID çıkar
                preg_match('/[?&]v=([^&]+)/', $stream->url ?? '', $matches);
                $videoId = $matches[1] ?? null;
                
                // Thumbnail: varsa image, yoksa YouTube'dan otomatik
                $thumbnail = $stream->image;
                if (empty($thumbnail) && $videoId) {
                    $thumbnail = 'https://img.youtube.com/vi/' . $videoId . '/hqdefault.jpg';
                }

                return [
                    'id' => $stream->id,
                    'title' => $stream->title,
                    'url' => $stream->url,
                    'type' => $stream->type ?? 'youtube',
                    'image' => $thumbnail,
                    'thumbnail' => $thumbnail,
                    'source_name' => $stream->title,
                    'is_active' => true,
                    'order' => $stream->id,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $formattedStreams,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Canlı yayınlar yüklenemedi',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
```

---

## API Route

Dosya: `routes/api.php`

```php
use App\Http\Controllers\LiveStreamingController;

Route::get('get_live_streams', [LiveStreamingController::class, 'getLiveStreamsForApp']);
```

---

## Test

API'yi test et:
```
https://admin.newsly.com.tr/api/get_live_streams
```

Beklenen JSON:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "CNN Türk Canlı",
      "url": "https://www.youtube.com/watch?v=6N8_r2uwLEc",
      "type": "url_youtube",
      "image": "https://img.youtube.com/vi/6N8_r2uwLEc/hqdefault.jpg",
      "thumbnail": "https://img.youtube.com/vi/6N8_r2uwLEc/hqdefault.jpg",
      "source_name": "CNN Türk Canlı",
      "is_active": true,
      "order": 1
    }
  ]
}
```

---

## Flutter Tarafı

Flutter servisi (`lib/services/live_stream_service.dart`) bu API'yi otomatik çağırır.

API çalışmazsa fallback yayınlar gösterilir:
- Tele 2 Haber
- Halk TV
- CNN Türk
- Sözcü TV

---

## Notlar

1. `language_id` zorunlu alan, varsayılan 1 (Türkçe)
2. `type` alanı: `url_youtube`, `m3u8`, `rtmp` olabilir
3. Thumbnail yüklenmezse YouTube'dan otomatik çekilir
4. Panel'de Live Streaming menüsünden yönetilir
