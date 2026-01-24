# Flutter API Endpoint Kurulumu

Senin mevcut `FeaturedSectionsController.php` dosyana sadece 1 fonksiyon eklememiz gerekiyor.

---

## Adım 1: Fonksiyonu Ekle

`app/Http/Controllers/FeaturedSectionsController.php` dosyasını aç.

Dosyanın **EN SONUNA**, son `}` karakterinden **ÖNCE** `SADECE_BU_FONKSIYONU_EKLE.php` dosyasındaki kodu yapıştır.

---

## Adım 2: Route Ekle

`routes/api.php` dosyasını aç.

**En üste ekle (use satırlarının yanına):**
```php
use App\Http\Controllers\FeaturedSectionsController;
```

**Route tanımlarının arasına ekle:**
```php
Route::get('get_featured_sections', [FeaturedSectionsController::class, 'getFeaturedSectionsForApp']);
```

---

## Adım 3: Test Et

Tarayıcıda şu URL'i aç:
```
https://senin-domain.com/api/get_featured_sections
```

Şöyle bir JSON görmen lazım:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Günün Öne Çıkanları",
      "type": "slider",
      "is_active": true,
      "order": 1,
      "news": [
        {
          "id": "1",
          "title": "Haber Başlığı",
          "image": "https://...",
          "date": "18 Oca 14:30",
          "categoryName": "Gündem",
          "description": "...",
          "sourceUrl": "...",
          "sourceName": "..."
        }
      ]
    }
  ]
}
```

---

## Style Mapping

Senin `style_app` değerlerin Flutter'da şöyle görünecek:

| style_app | Flutter Tipi | Görünüm |
|-----------|--------------|---------|
| style_1 | slider | Büyük kayan kartlar |
| style_2 | horizontal_list | Yatay kaydırılabilir liste |
| style_3 | horizontal_list | Yatay kaydırılabilir liste |
| style_4 | breaking_news | Son dakika bandı (kırmızı) |
| style_5 | horizontal_list | Yatay kaydırılabilir liste |
| style_6 | slider | Büyük kayan kartlar |

İstersen bu mapping'i değiştirebilirsin. Fonksiyondaki `match` bloğunu düzenle.

---

## Hepsi Bu Kadar!

- Migration eklemeye gerek yok (tablonuz zaten var)
- Model eklemeye gerek yok (FeaturedSections modeliniz zaten var)
- View eklemeye gerek yok (admin paneliniz zaten var)
- Sadece 1 fonksiyon + 1 route
