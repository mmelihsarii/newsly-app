# Featured Sections Filtreleme Çözümü
**Tarih:** 19 Ocak 2026

---

## MEVCUT DURUM ANALİZİ

### Firestore Yapısı
```
users/{userId}/selectedSources: ["cnn_turk", "ntv", "a_spor", "fotomac"]
```
> Kaynak **ID'leri** tutuluyor (snake_case)

### Flutter Eşleştirmesi (news_sources_data.dart)
```dart
NewsSourceItem(id: 'cnn_turk', name: 'CNN Türk')
NewsSourceItem(id: 'ntv', name: 'NTV')
NewsSourceItem(id: 'a_spor', name: 'A Spor')
```

### MySQL Beklenen Yapı
```
tbl_news.source_name = 'CNN Türk' (şu an NULL)
```

---

## ADIM 1: SQL İYİLEŞTİRMESİ (VERİTABANI)

### 1.1 Önce Mevcut Durumu Kontrol Et
```sql
-- NULL olan kayıtları say
SELECT COUNT(*) as total_news, 
       SUM(CASE WHEN source_name IS NULL OR source_name = '' THEN 1 ELSE 0 END) as null_count
FROM tbl_news;

-- Mevcut category_id dağılımını gör
SELECT category_id, COUNT(*) as count 
FROM tbl_news 
GROUP BY category_id 
ORDER BY count DESC;
```

### 1.2 Kategori ID'lerine Göre Toplu Güncelleme (CASE WHEN)

> ⚠️ **ÖNEMLİ:** Aşağıdaki SQL'i çalıştırmadan önce kendi `category_id` → `source_name` eşleştirmeni yap!
> Admin panelinden kategori listesini kontrol et.

```sql
-- ============================================================================
-- tbl_news.source_name'i category_id'ye göre güncelle
-- ÖNCELİKLE BACKUP AL: CREATE TABLE tbl_news_backup AS SELECT * FROM tbl_news;
-- ============================================================================

UPDATE tbl_news 
SET source_name = CASE category_id
    -- GÜNDEM KATEGORİSİ (Örnek ID'ler - kendi ID'lerinle değiştir)
    WHEN 1 THEN 'NTV'
    WHEN 2 THEN 'CNN Türk'
    WHEN 3 THEN 'Habertürk'
    WHEN 4 THEN 'TRT Haber'
    WHEN 5 THEN 'A Haber'
    WHEN 6 THEN 'Hürriyet'
    WHEN 7 THEN 'Sözcü'
    WHEN 8 THEN 'Sabah'
    
    -- SPOR KATEGORİSİ
    WHEN 10 THEN 'A Spor'
    WHEN 11 THEN 'Fotomaç'
    WHEN 12 THEN 'Kontraspor'
    
    -- EKONOMİ KATEGORİSİ
    WHEN 20 THEN 'Bloomberg HT'
    WHEN 21 THEN 'BigPara'
    
    -- TEKNOLOJİ KATEGORİSİ
    WHEN 30 THEN 'Webtekno'
    WHEN 31 THEN 'Teknoblog'
    WHEN 32 THEN 'Donanım Haber'
    
    -- Eşleşmeyen kategoriler için varsayılan
    ELSE source_name
END
WHERE source_name IS NULL OR source_name = '';

-- Sonucu kontrol et
SELECT source_name, COUNT(*) as count 
FROM tbl_news 
WHERE source_name IS NOT NULL AND source_name != ''
GROUP BY source_name 
ORDER BY count DESC;
```

### 1.3 Alternatif: URL'den Kaynak Tespiti (other_url varsa)

Eğer `other_url` veya `source_url` kolonun varsa:

```sql
-- URL'den kaynak adı çıkarma
UPDATE tbl_news SET source_name = 'NTV' 
WHERE (other_url LIKE '%ntv.com.tr%' OR source_url LIKE '%ntv.com.tr%') 
  AND (source_name IS NULL OR source_name = '');

UPDATE tbl_news SET source_name = 'CNN Türk' 
WHERE (other_url LIKE '%cnnturk.com%' OR source_url LIKE '%cnnturk.com%') 
  AND (source_name IS NULL OR source_name = '');

-- ... diğer kaynaklar için devam et
```

---

## ADIM 2: PHP BACKEND (API GÜVENLİĞİ)

### 2.1 FeaturedSectionsController Güncellemesi

`FeaturedSectionsController.php` dosyasında haberleri JSON'a çevirirken fallback ekle:

```php
<?php
// FeaturedSectionsController.php içinde

/**
 * Kategori ID'sine göre varsayılan kaynak adı döndür
 * Bu fonksiyonu controller'ın başına ekle
 */
private function getDefaultSourceName($categoryId) {
    // Kendi kategori ID'lerinle eşleştir
    $categorySourceMap = [
        1 => 'NTV',
        2 => 'CNN Türk',
        3 => 'Habertürk',
        4 => 'TRT Haber',
        5 => 'A Haber',
        6 => 'Hürriyet',
        7 => 'Sözcü',
        8 => 'Sabah',
        10 => 'A Spor',
        11 => 'Fotomaç',
        12 => 'Kontraspor',
        20 => 'Bloomberg HT',
        21 => 'BigPara',
        30 => 'Webtekno',
        31 => 'Teknoblog',
        32 => 'Donanım Haber',
        // ... diğer kategoriler
    ];
    
    return $categorySourceMap[$categoryId] ?? 'Bilinmeyen Kaynak';
}

/**
 * Haber verisini JSON'a çevirirken kullan
 */
private function formatNewsItem($news) {
    // source_name kontrolü - boşsa fallback uygula
    $sourceName = $news->source_name;
    
    if (empty($sourceName)) {
        // 1. Önce URL'den çıkarmayı dene
        if (!empty($news->other_url)) {
            $sourceName = $this->extractSourceFromUrl($news->other_url);
        }
        
        // 2. Hala boşsa kategori ID'sine göre varsayılan ata
        if (empty($sourceName) && !empty($news->category_id)) {
            $sourceName = $this->getDefaultSourceName($news->category_id);
        }
        
        // 3. Son çare: Bilinmeyen Kaynak
        if (empty($sourceName)) {
            $sourceName = 'Bilinmeyen Kaynak';
        }
    }
    
    return [
        'id' => $news->id,
        'title' => $news->title,
        'description' => $news->description ?? '',
        'image' => $news->image,
        'date' => $news->created_at,
        'category_name' => $news->category_name ?? '',
        'content_type' => $news->content_type ?? 'standard_post',
        'content_value' => $news->content_value ?? '',
        'source_url' => $news->other_url ?? '',
        'source_name' => $sourceName,  // ← Artık asla NULL olmayacak
    ];
}

/**
 * URL'den kaynak adı çıkar
 */
private function extractSourceFromUrl($url) {
    if (empty($url)) return null;
    
    $urlSourceMap = [
        'ntv.com.tr' => 'NTV',
        'cnnturk.com' => 'CNN Türk',
        'haberturk.com' => 'Habertürk',
        'trthaber.com' => 'TRT Haber',
        'ahaber.com' => 'A Haber',
        'hurriyet.com.tr' => 'Hürriyet',
        'sozcu.com' => 'Sözcü',
        'sabah.com.tr' => 'Sabah',
        'aspor.com' => 'A Spor',
        'fotomac.com' => 'Fotomaç',
        'webtekno.com' => 'Webtekno',
        'teknoblog.com' => 'Teknoblog',
        'bloomberght.com' => 'Bloomberg HT',
        // ... diğer URL'ler
    ];
    
    foreach ($urlSourceMap as $domain => $sourceName) {
        if (strpos($url, $domain) !== false) {
            return $sourceName;
        }
    }
    
    return null;
}
```

### 2.2 get_featured_sections Endpoint'ini Güncelle

```php
public function get_featured_sections() {
    try {
        $sections = FeaturedSection::where('is_active', 1)
            ->orderBy('sort_order', 'ASC')
            ->get();
        
        $result = [];
        
        foreach ($sections as $section) {
            $newsItems = $this->getNewsForSection($section);
            
            // Her haberi formatla (source_name fallback dahil)
            $formattedNews = [];
            foreach ($newsItems as $news) {
                $formattedNews[] = $this->formatNewsItem($news);
            }
            
            $result[] = [
                'id' => $section->id,
                'title' => $section->title,
                'type' => $this->getSectionType($section->style_app),
                'order' => $section->sort_order,
                'is_active' => true,
                'news' => $formattedNews,
            ];
        }
        
        return response()->json($result);
        
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
}
```

---

## ADIM 3: FLUTTER FİLTRELEME MANTIĞI

### 3.1 HomeController'a Filtreleme Fonksiyonu Ekle

`lib/controllers/home_controller.dart` dosyasını güncelle:

```dart
import '../utils/news_sources_data.dart';

// ... mevcut kodlar ...

/// Kullanıcının seçtiği kaynaklara göre section'ları filtrele
/// 
/// Mantık:
/// 1. Kullanıcının Firestore'daki selectedSources listesini al (ID'ler)
/// 2. ID'leri kaynak isimlerine çevir (news_sources_data.dart kullanarak)
/// 3. Her section'daki haberleri filtrele
/// 4. Boş kalan section'ları listeden çıkar
List<FeaturedSectionModel> _filterSectionsByUserSources(List<FeaturedSectionModel> sections) {
  // Kullanıcının seçtiği kaynak ID'lerini al
  final Set<String> selectedSourceIds = _sourceController?.selectedSources ?? {};
  
  // Eğer hiç kaynak seçilmemişse, tüm haberleri göster
  if (selectedSourceIds.isEmpty) {
    print("📰 Kaynak seçimi yok - tüm haberler gösteriliyor");
    return sections.where((s) => s.news.isNotEmpty).toList();
  }
  
  // Seçili ID'leri kaynak isimlerine çevir (case-insensitive karşılaştırma için lowercase)
  final Set<String> selectedSourceNames = selectedSourceIds
      .map((id) => getSourceById(id)?.name.toLowerCase())
      .whereType<String>()
      .toSet();
  
  print("🔍 Aktif kaynaklar (${selectedSourceNames.length}): $selectedSourceNames");
  
  // Her section'ı filtrele
  final List<FeaturedSectionModel> filteredSections = [];
  
  for (final section in sections) {
    // Section içindeki haberleri filtrele
    final List<NewsModel> filteredNews = section.news.where((news) {
      final String? newsSourceName = news.sourceName?.toLowerCase().trim();
      
      // Kaynak adı yoksa veya boşsa, haberi göster (fallback)
      if (newsSourceName == null || newsSourceName.isEmpty) {
        return true;
      }
      
      // Kaynak adı kullanıcının seçtiklerinde var mı?
      // Partial match de kontrol et (örn: "CNN Türk" içinde "cnn" var mı)
      final bool isSelected = selectedSourceNames.any((selected) {
        return newsSourceName.contains(selected) || selected.contains(newsSourceName);
      });
      
      return isSelected;
    }).toList();
    
    // Eğer section'da haber kaldıysa, listeye ekle
    if (filteredNews.isNotEmpty) {
      filteredSections.add(FeaturedSectionModel(
        id: section.id,
        title: section.title,
        type: section.type,
        order: section.order,
        isActive: section.isActive,
        news: filteredNews,
      ));
    }
  }
  
  print("📊 Filtreleme: ${sections.length} section → ${filteredSections.length} section");
  
  return filteredSections;
}
```

### 3.2 fetchFeaturedSections'da Filtrelemeyi Aktifleştir

Mevcut `fetchFeaturedSections` fonksiyonunda şu satırı bul:

```dart
// Kullanıcının seçtiği kaynaklara göre haberleri filtrele
allSections = _filterSectionsByUserSources(allSections);
```

Bu satır zaten var, sadece `_filterSectionsByUserSources` fonksiyonunu yukarıdaki gibi güncelle.

### 3.3 Kaynak Değişikliğinde Otomatik Yenileme

Kullanıcı kaynak seçimini değiştirdiğinde haberlerin otomatik yenilenmesi için:

```dart
// HomeController.onInit() içine ekle
@override
void onInit() {
  super.onInit();
  _apiService = ApiService();
  scrollController = ScrollController();
  
  // SourceSelectionController'ı al veya oluştur
  if (Get.isRegistered<SourceSelectionController>()) {
    _sourceController = Get.find<SourceSelectionController>();
  } else {
    _sourceController = Get.put(SourceSelectionController());
  }
  
  // Kaynak seçimi değiştiğinde haberleri yenile
  ever(_sourceController!.selectedSources, (_) {
    print("🔄 Kaynak seçimi değişti, haberler yenileniyor...");
    fetchFeaturedSections();
  });
  
  _loadInitialData();
}
```

---

## ADIM 4: TEST VE DOĞRULAMA KONTROL LİSTESİ

### 4.1 Veritabanı Testi
```
□ 1. phpMyAdmin'e gir
□ 2. Önce backup al: CREATE TABLE tbl_news_backup AS SELECT * FROM tbl_news;
□ 3. NULL sayısını kontrol et: SELECT COUNT(*) FROM tbl_news WHERE source_name IS NULL;
□ 4. CASE WHEN UPDATE sorgusunu çalıştır
□ 5. Tekrar kontrol et: SELECT source_name, COUNT(*) FROM tbl_news GROUP BY source_name;
□ 6. NULL sayısı 0 olmalı
```

### 4.2 API Testi
```
□ 1. Tarayıcıda aç: https://admin.newsly.com.tr/api/get_featured_sections
□ 2. JSON yanıtında her haberin "source_name" alanını kontrol et
□ 3. Hiçbir "source_name" null veya boş olmamalı
□ 4. Örnek çıktı:
   {
     "id": 123,
     "title": "Haber Başlığı",
     "source_name": "CNN Türk",  ← Bu dolu olmalı
     ...
   }
```

### 4.3 Flutter Testi
```
□ 1. Uygulamayı tamamen kapat (force stop)
□ 2. flutter clean && flutter pub get
□ 3. Uygulamayı başlat
□ 4. Debug console'da şu logları ara:
   - "🔍 Aktif kaynaklar: {cnn türk, ntv, ...}"
   - "📊 Filtreleme: X section → Y section"
□ 5. Kaynak seçim ekranına git, bir kaynağı kaldır
□ 6. Ana sayfaya dön, o kaynağın haberleri görünmemeli
□ 7. Kaynağı tekrar ekle, haberler geri gelmeli
```

### 4.4 Edge Case Testleri
```
□ 1. Hiç kaynak seçilmemişken: Tüm haberler görünmeli
□ 2. Sadece 1 kaynak seçiliyken: Sadece o kaynağın haberleri
□ 3. Tüm kaynaklar seçiliyken: Tüm haberler görünmeli
□ 4. Yeni eklenen haber (source_name boş): Fallback çalışmalı
```

---

## ÖZET

| Adım | Dosya | Değişiklik |
|------|-------|------------|
| 1 | MySQL | `tbl_news.source_name` güncelleme |
| 2 | PHP | `formatNewsItem()` fallback ekleme |
| 3 | Flutter | `_filterSectionsByUserSources()` güncelleme |
| 4 | Test | 4 aşamalı doğrulama |

**Kritik Notlar:**
- SQL çalıştırmadan önce mutlaka backup al
- PHP değişikliği yapıldıktan sonra cache temizle
- Flutter'da `flutter clean` yap
- Case-insensitive karşılaştırma kullan

---

**Son Güncelleme:** 19 Ocak 2026
