# Panel Bildirim Sistemi - Route ve Controller Ekleme

## SORUN
Kategori seçildiğinde haberler yüklenmiyor çünkü `get_news_by_category` route'u 405 hatası veriyor.

## ÇÖZÜM

### 1. Route Ekle
Dosya: `/home/newslyco/public_html/admin/routes/web.php`

Bu satırı diğer route'ların yanına ekle:
```php
Route::get('get_news_by_category', [App\Http\Controllers\NewsController::class, 'getNewsByCategory'])->name('get_news_by_category');
```

### 2. NewsController'a Fonksiyon Ekle
Dosya: `/home/newslyco/public_html/admin/app/Http/Controllers/NewsController.php`

Bu fonksiyonu NewsController class'ının içine ekle:
```php
public function getNewsByCategory(Request $request)
{
    $category_id = $request->category_id;
    
    if (empty($category_id)) {
        return response()->json(['error' => false, 'data' => []]);
    }
    
    // tbl_news tablosundan haberleri çek
    $news = \DB::table('tbl_news')
        ->where('category_id', $category_id)
        ->where('status', 1)
        ->orderBy('id', 'desc')
        ->limit(100)
        ->get(['id', 'title']);
    
    $data = [];
    foreach ($news as $item) {
        $data[] = [
            'id' => $item->id,
            'value' => $item->title
        ];
    }
    
    return response()->json(['error' => false, 'data' => $data]);
}
```

### 3. Alternatif: Helpers.php'ye Ekle
Eğer NewsController'ı değiştirmek istemiyorsan, route'u farklı bir controller'a yönlendirebilirsin.

Dosya: `/home/newslyco/public_html/admin/routes/web.php`
```php
Route::get('get_news_by_category', function(Request $request) {
    $category_id = $request->category_id;
    
    if (empty($category_id)) {
        return response()->json(['error' => false, 'data' => []]);
    }
    
    $news = \DB::table('tbl_news')
        ->where('category_id', $category_id)
        ->where('status', 1)
        ->orderBy('id', 'desc')
        ->limit(100)
        ->get(['id', 'title']);
    
    $data = [];
    foreach ($news as $item) {
        $data[] = [
            'id' => $item->id,
            'value' => $item->title
        ];
    }
    
    return response()->json(['error' => false, 'data' => $data]);
})->name('get_news_by_category');
```

## KONTROL

1. Route'un eklendiğini kontrol et:
```bash
php artisan route:list | grep news_by_category
```

2. Eğer cache varsa temizle:
```bash
php artisan route:clear
php artisan cache:clear
```

## BLADE DOSYASI

`backend/notifications_v4.blade.php` dosyasını şuraya yükle:
`/home/newslyco/public_html/admin/resources/views/notifications.blade.php`

## TEST

1. Panel'de Bildirim sayfasını aç
2. Tip olarak "Kategori" seç
3. Dil seç
4. Kategori seç
5. Haberler yüklenmeli
