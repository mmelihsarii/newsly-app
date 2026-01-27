# BİLDİRİM SİSTEMİ DÜZELTME - YAPILACAKLAR

## SORUN
1. Bildirime tıklanınca haberin KENDİSİ açılmıyor, replika/kopya açılıyor
2. Bildirim panelinde az haber görünüyor
3. Haber detayında kaynak adı yerine kategori adı görünüyor

## ÇÖZÜM

### 1. API ROUTE EKLE (routes/api.php)
```php
Route::get('news_detail', [NewsController::class, 'getNewsDetail']);
```

### 2. NewsController.php'ye FONKSİYON EKLE
`backend/NEWS_DETAIL_API.php` dosyasındaki `getNewsDetail` fonksiyonunu kopyala.

Bu fonksiyon:
- Haber ID'si ile haberi veritabanından çeker
- Tüm detayları döndürür (title, description, content, image, sourceName, sourceUrl)
- Bildirimden habere giderken bu API kullanılır

### 3. HABER LİMİTİNİ ARTIR
`helpers.php` veya `web.php`'deki `get_news_by_category` fonksiyonunda:
```php
->take(500)  // 50'den 500'e çıkar
```

### 4. TEST ET
1. Panelden bildirim gönder (bir haber seç)
2. Uygulamada bildirime tıkla
3. Haberin KENDİSİ açılmalı (ID, başlık, kaynak adı doğru olmalı)

## FLUTTER TARAFI (ZATEN YAPILDI)
- `notification_service.dart` güncellendi
- Bildirimden gelen `news_id` ile API'den haber çekiliyor
- `api_constants.dart`'a `getNewsDetail` endpoint'i eklendi

## ÖNEMLİ
`news_detail` API'si OLMADAN bildirimden habere gitme ÇALIŞMAZ!
