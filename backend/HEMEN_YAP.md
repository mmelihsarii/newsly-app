# HEMEN YAPILACAKLAR

## 1. Featured Sections Backend Düzeltmesi

Laravel projesinde `app/Http/Controllers/FeaturedSectionsController.php` dosyasını aç.

`getFeaturedSectionsForApp` fonksiyonunu BUL ve TAMAMEN SİL.

Sonra `backend/getFeaturedSectionsForApp_FINAL.php` dosyasındaki kodu yapıştır.

### Sorun Neydi?
- Eski kod `if (!empty($newsData))` kontrolü yapıyordu
- Bu yüzden haberi olmayan section'lar API'den dönmüyordu
- ID 6 "Öne Çıkanlar" section'ı bu yüzden gelmiyordu

### Düzeltme Ne Yaptı?
- `if (!empty($newsData))` kontrolü KALDIRILDI
- Artık TÜM aktif section'lar dönüyor (haberi olsun olmasın)
- Flutter tarafı RSS'ten haberleri dolduruyor

## 2. Test Et

API'yi test et:
```
GET /api/get_featured_sections
```

Beklenen sonuç: 2 section dönmeli (ID 4 ve ID 6)

---

## Flutter Tarafı (ZATEN HAZIR)

- `lib/controllers/home_controller.dart` - Panel'den section'ları çekiyor
- `lib/controllers/local_controller.dart` - 81 şehir yüklü
- `lib/services/local_news_service.dart` - Firestore + Hürriyet RSS

Yerel haberler için:
- 81 şehir butonu gösteriliyor
- Firestore'da "Yerel Haberler" kategorisindeki RSS'ler şehir adına göre eşleşiyor
- Eşleşme yoksa Hürriyet yerel RSS kullanılıyor
