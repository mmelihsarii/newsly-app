# Bildirim - Haber Seçimli Sistem Kurulumu

Bu güncelleme ile admin panelden bildirim gönderirken:
- Kategori seç → Haber seç → Otomatik gönder
- Başlık = Haber başlığı
- Mesaj = Haber açıklaması (ilk 150 karakter)
- Resim = Haber resmi

## Kurulum Adımları

### 1. Route Ekle

`routes/web.php` dosyasında `Route::group(['prefix' => 'common'], ...)` bloğunun içine ekle:

```php
// Bildirim için haber detaylarını getir
Route::post('get_news_details_for_notification', function(Illuminate\Http\Request $request) {
    try {
        $news_id = $request->news_id;
        
        if (empty($news_id)) {
            return response()->json(['error' => true, 'message' => 'Haber ID gerekli']);
        }
        
        $news = \DB::table('tbl_news')
            ->where('id', $news_id)
            ->where('status', 1)
            ->first(['id', 'title', 'description', 'image']);
        
        if (!$news) {
            return response()->json(['error' => true, 'message' => 'Haber bulunamadı']);
        }
        
        $description = strip_tags($news->description ?? '');
        $description = html_entity_decode($description, ENT_QUOTES, 'UTF-8');
        $description = preg_replace('/\s+/', ' ', $description);
        $description = trim($description);
        if (mb_strlen($description) > 150) {
            $description = mb_substr($description, 0, 147) . '...';
        }
        
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
        return response()->json(['error' => true, 'message' => 'Bir hata oluştu']);
    }
})->name('get_news_details_for_notification');
```

### 2. Blade Dosyasını Değiştir

Kaynak: `backend/BILDIRIM_HABER_SECIMLI/notifications.blade.php`
Hedef: `/resources/views/notifications.blade.php`

### 3. Controller'ı Değiştir

Kaynak: `backend/BILDIRIM_HABER_SECIMLI/SendNotificationController.php`
Hedef: `/app/Http/Controllers/SendNotificationController.php`

### 4. Cache Temizle

```bash
php artisan cache:clear
php artisan view:clear
php artisan route:clear
```

## Nasıl Çalışır?

1. Admin panelde "Bildirim Gönder" sayfasına git
2. Dil seç (varsa)
3. Kategori seç
4. Haber listesinden bir haber seç
5. Seçilen haberin önizlemesi görünür (başlık, açıklama, resim)
6. "Gönder" butonuna bas

Bildirim otomatik olarak:
- Başlık = Haber başlığı
- Mesaj = Haber açıklaması (max 150 karakter)
- Resim = Haber resmi
- news_id = Seçilen haberin ID'si (uygulama tıklandığında habere yönlendirir)

## Dosya Listesi

| Dosya | Açıklama |
|-------|----------|
| `notifications.blade.php` | Yeni bildirim formu |
| `SendNotificationController.php` | Güncellenmiş controller |
| `WEB_ROUTES_EKLE.php` | Eklenecek route |
