# Bildirim Paneli Kurulum Rehberi

## SORUN
Kategori seçildiğinde haberler yüklenmiyor - 405 Method Not Allowed hatası

## ÇÖZÜM ADIMLARI

### Adım 1: Route Ekle
Dosya: `/home/newslyco/public_html/admin/routes/web.php`

Bu satırı dosyanın sonuna (son `});` öncesine) ekle:
```php
Route::match(['get', 'post'], 'get_news_by_category', [App\Http\Controllers\NewsController::class, 'getNewsByCategory'])->name('get_news_by_category');
```

### Adım 2: Controller Fonksiyonu Ekle
Dosya: `/home/newslyco/public_html/admin/app/Http/Controllers/NewsController.php`

Bu fonksiyonu class'ın içine ekle:
```php
public function getNewsByCategory(Request $request)
{
    $category_id = $request->category_id;
    
    if (empty($category_id)) {
        return response()->json(['error' => false, 'data' => []]);
    }
    
    try {
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
        
    } catch (\Exception $e) {
        return response()->json(['error' => true, 'data' => []]);
    }
}
```

### Adım 3: Blade Dosyasını Yükle
Kaynak: `backend/notifications_v5.blade.php`
Hedef: `/home/newslyco/public_html/admin/resources/views/notifications.blade.php`

### Adım 4: Controller'ı Yükle
Kaynak: `backend/SendNotificationController_minimal.php`
Hedef: `/home/newslyco/public_html/admin/app/Http/Controllers/SendNotificationController.php`

### Adım 5: Cache Temizle
SSH ile sunucuya bağlan ve şu komutları çalıştır:
```bash
cd /home/newslyco/public_html/admin
php artisan route:clear
php artisan cache:clear
php artisan config:clear
php artisan view:clear
```

### Adım 6: Test Et
1. Panel'de Bildirim sayfasını aç
2. Tip: "Kategori" seç
3. Dil seç (Türkçe)
4. Kategori seç
5. Haberler yüklenmeli

## DOSYA LİSTESİ

| Kaynak Dosya | Hedef Yol |
|--------------|-----------|
| `backend/notifications_v5.blade.php` | `/home/newslyco/public_html/admin/resources/views/notifications.blade.php` |
| `backend/SendNotificationController_minimal.php` | `/home/newslyco/public_html/admin/app/Http/Controllers/SendNotificationController.php` |
| `backend/HELPERS_KATEGORI_BILDIRIM.php` içeriği | `/home/newslyco/public_html/admin/app/helpers.php` (send_notification fonksiyonunu değiştir) |

## HATA AYIKLAMA

Eğer hala çalışmıyorsa:

1. Browser Console'u aç (F12)
2. Network sekmesine bak
3. Kategori seçtiğinde hangi URL'e istek gidiyor kontrol et
4. Response'u kontrol et

Eğer route bulunamıyorsa:
```bash
php artisan route:list | grep news
```

## ÖNEMLİ NOTLAR

- Alt kategori (subcategory) kaldırıldı, hidden field olarak 0 gönderiliyor
- news_id boş olabilir, controller'da 0'a çevriliyor
- Haberler sadece status=1 olanlar listeleniyor
- Maksimum 100 haber listeleniyor
