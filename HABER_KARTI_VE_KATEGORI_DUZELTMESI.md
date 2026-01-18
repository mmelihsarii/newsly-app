# 🔧 Haber Kartı Hizalama ve Kategori Filtreleme Düzeltmesi

**Tarih:** 17 Ocak 2026  
**Durum:** ✅ Düzeltildi

---

## 🐛 Sorunlar

### 1. Haber Başlıkları Sağa Kaymış
**Problem:**
- Anasayfadaki haber başlıkları sağa kaymış görünüyordu
- Başlıklar ortada değil, sağda duruyordu
- Görsel denge bozuktu

### 2. Kategori Filtreleme Hatası
**Problem:**
- Webtekno "Teknoloji" kategorisinde olmasına rağmen "Gündem" başlığı altında görünüyordu
- Tüm haberler "Gündem" kategorisi olarak işaretleniyordu
- Kaynak seçimi doğru çalışıyordu ama kategori yanlış geliyordu

---

## ✅ Çözümler

### 1. Haber Kartı Hizalama Düzeltmesi

**Dosya:** `lib/views/home/home_view.dart`

#### Değişiklikler:

**Önceki:**
```dart
Row(
  children: [
    // Resim: 100x80
    ClipRRect(...),
    const SizedBox(width: 12),
    Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Container(...), // Kategori
              const Spacer(), // Çok fazla boşluk!
              Icon(...), // Bookmark
            ],
          ),
          // Başlık
        ],
      ),
    ),
  ],
)
```

**Yeni:**
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start, // ÜST HIZALAMA
  children: [
    // Resim: 90x75 (daha küçük)
    ClipRRect(...),
    const SizedBox(width: 10), // Daha az boşluk
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible( // Spacer yerine Flexible
                child: Container(...), // Kategori
              ),
              const SizedBox(width: 8), // Sabit boşluk
              Icon(...), // Bookmark
            ],
          ),
          // Başlık
        ],
      ),
    ),
  ],
)
```

#### İyileştirmeler:
- ✅ **crossAxisAlignment: CrossAxisAlignment.start** - Üstten hizalama
- ✅ **Resim boyutu**: 100x80 → 90x75 (daha kompakt)
- ✅ **Boşluk**: 12px → 10px (daha az boşluk)
- ✅ **Spacer kaldırıldı**: Flexible + SizedBox kullanıldı
- ✅ **Font boyutu**: 14 → 13.5 (daha dengeli)
- ✅ **Kategori badge**: Flexible ile sarıldı (taşma önlendi)
- ✅ **Tarih**: Flexible ile sarıldı (taşma önlendi)

---

### 2. Kategori Filtreleme Düzeltmesi

**Dosya:** `lib/services/news_service.dart`

#### Sorunun Kök Nedeni:

**Önceki Kod:**
```dart
Future<List<NewsModel>> _fetchRssFeed(String url, String sourceName) async {
  // ...
  newsList.add(
    NewsModel(
      title: title,
      description: description,
      sourceName: sourceName,
      categoryName: "Gündem", // ❌ SABİT DEĞER!
    ),
  );
}
```

**Problem:**
- Tüm haberler için kategori sabit olarak "Gündem" atanıyordu
- Firestore'daki kaynak bilgisindeki `category` alanı kullanılmıyordu
- Bu yüzden Webtekno haberleri "Teknoloji" yerine "Gündem" olarak gösteriliyordu

#### Çözüm:

**Yeni Kod:**
```dart
Future<List<NewsModel>> fetchAllNews() async {
  // ...
  await Future.wait(
    sources.map((source) async {
      String url = source['rss_url'] ?? '';
      String sourceName = source['name'] ?? 'Bilinmeyen Kaynak';
      String categoryName = source['category'] ?? 'Gündem'; // ✅ Firestore'dan al
      
      if (url.isNotEmpty) {
        var fetchedNews = await _fetchRssFeed(url, sourceName, categoryName);
        allNews.addAll(fetchedNews);
      }
    }),
  );
}

Future<List<NewsModel>> _fetchRssFeed(
  String url, 
  String sourceName, 
  String categoryName // ✅ Parametre eklendi
) async {
  // ...
  newsList.add(
    NewsModel(
      title: title,
      description: description,
      sourceName: sourceName,
      categoryName: categoryName, // ✅ Dinamik kategori
    ),
  );
}
```

#### İyileştirmeler:
- ✅ **Firestore'dan kategori**: `source['category']` alanı kullanılıyor
- ✅ **Dinamik kategori**: Her kaynak kendi kategorisini taşıyor
- ✅ **Fallback**: Kategori yoksa "Gündem" kullanılıyor
- ✅ **Parametre geçişi**: `_fetchRssFeed` fonksiyonuna kategori parametresi eklendi

---

## 📊 Firestore Veri Yapısı

### news_sources Collection

Her kaynak şu yapıda olmalı:

```json
{
  "id": "webtekno",
  "name": "Webtekno",
  "rss_url": "https://www.webtekno.com/rss.xml",
  "category": "Bilim & Teknoloji", // ✅ Kategori alanı
  "is_active": true
}
```

### Kategori İsimleri (news_sources_data.dart ile eşleşmeli):

```dart
"Bilim & Teknoloji"  // Webtekno, Teknoblog, vb.
"Gündem"             // Hürriyet, Sözcü, vb.
"Spor"               // Fotomaç, A Spor, vb.
"Ekonomi"            // Bloomberg HT, BigPara, vb.
"Son Dakika"         // Son dakika haberleri
"Yabancı Kaynaklar"  // BBC, CNN, vb.
"Haber Ajansları"    // AA, İHA, vb.
"Yerel Haberler"     // Şehir bazlı haberler
```

---

## 🎨 Görsel Karşılaştırma

### Önceki Haber Kartı:
```
┌────────┬─────────────────────────────┐
│        │ Kategori          [🔖]      │
│  Resim │                             │
│ 100x80 │ Haber Başlığı (sağa kaymış)│
│        │ Kaynak • Tarih              │
└────────┴─────────────────────────────┘
```

### Yeni Haber Kartı:
```
┌───────┬──────────────────────────────┐
│       │ Kategori        [🔖]         │
│ Resim │ Haber Başlığı (ortalı)      │
│ 90x75 │ Kaynak • Tarih               │
└───────┴──────────────────────────────┘
```

---

## 🧪 Test Senaryoları

### Test 1: Haber Kartı Hizalama
1. Anasayfayı aç
2. Haber kartlarına bak
3. ✅ Başlıklar sola yaslanmış olmalı
4. ✅ Kategori badge taşmamalı
5. ✅ Bookmark ikonu sağda olmalı

### Test 2: Kategori Filtreleme
1. Kaynak seçiminde "Webtekno" seç
2. Anasayfaya dön
3. Webtekno haberlerine bak
4. ✅ Kategori "Bilim & Teknoloji" olmalı
5. ✅ "Gündem" olmamalı

### Test 3: Çoklu Kategori
1. Farklı kategorilerden kaynaklar seç:
   - Webtekno (Teknoloji)
   - Hürriyet (Gündem)
   - Fotomaç (Spor)
2. Anasayfaya dön
3. ✅ Her haber kendi kategorisini göstermeli

### Test 4: Firestore Kategori Eksik
1. Firestore'da `category` alanı olmayan bir kaynak ekle
2. O kaynağı seç
3. ✅ Haberleri "Gündem" kategorisinde göstermeli (fallback)

---

## 📝 Firestore Güncelleme Scripti

Eğer Firestore'daki kaynaklarda `category` alanı yoksa, şu script ile ekleyebilirsiniz:

```javascript
// Firebase Console > Firestore > news_sources
// Her kaynak için category alanı ekle

// Örnek:
db.collection('news_sources').doc('webtekno').update({
  category: 'Bilim & Teknoloji'
});

db.collection('news_sources').doc('hurriyet').update({
  category: 'Gündem'
});

db.collection('news_sources').doc('fotomac').update({
  category: 'Spor'
});

// Toplu güncelleme:
const batch = db.batch();

// Teknoloji kaynakları
['webtekno', 'teknoblog', 'donanim_haber'].forEach(id => {
  const ref = db.collection('news_sources').doc(id);
  batch.update(ref, { category: 'Bilim & Teknoloji' });
});

// Gündem kaynakları
['hurriyet', 'sozcu', 'ntv', 'cnn_turk'].forEach(id => {
  const ref = db.collection('news_sources').doc(id);
  batch.update(ref, { category: 'Gündem' });
});

// Spor kaynakları
['fotomac', 'a_spor', 'fanatik'].forEach(id => {
  const ref = db.collection('news_sources').doc(id);
  batch.update(ref, { category: 'Spor' });
});

await batch.commit();
```

---

## 🔍 Debug İpuçları

### Kategori Hala Yanlış Görünüyorsa:

1. **Firestore'u Kontrol Et:**
```dart
// news_service.dart içinde debug log ekle:
print("📋 Kaynak: $sourceName, Kategori: $categoryName");
```

2. **Kategori İsimlerini Kontrol Et:**
- Firestore'daki kategori isimleri
- news_sources_data.dart'daki kategori isimleri
- Tam eşleşmeli!

3. **Cache Temizle:**
```dart
// Uygulamayı tamamen kapat
// Yeniden başlat
// Veya:
flutter clean
flutter pub get
flutter run
```

---

## ✅ Kontrol Listesi

- [x] Haber kartı hizalaması düzeltildi
- [x] crossAxisAlignment eklendi
- [x] Resim boyutu küçültüldü (90x75)
- [x] Spacer kaldırıldı, Flexible kullanıldı
- [x] Kategori badge Flexible ile sarıldı
- [x] Tarih Flexible ile sarıldı
- [x] Kategori filtreleme düzeltildi
- [x] Firestore'dan kategori alınıyor
- [x] _fetchRssFeed'e kategori parametresi eklendi
- [x] Fallback kategori eklendi
- [x] Arama sonuçları da düzeltildi
- [x] Test edildi (0 hata)

---

## 🎉 Sonuç

### Haber Kartı:
- ✅ Başlıklar artık düzgün hizalı
- ✅ Sola yaslanmış, ortalı görünüm
- ✅ Daha kompakt ve dengeli
- ✅ Taşma sorunları çözüldü

### Kategori Filtreleme:
- ✅ Her haber doğru kategorisini gösteriyor
- ✅ Webtekno → "Bilim & Teknoloji"
- ✅ Hürriyet → "Gündem"
- ✅ Fotomaç → "Spor"
- ✅ Firestore'dan dinamik kategori

**Durum:** Hazır ve Çalışıyor ✅

---

**Hazırlayan:** Kiro AI Assistant  
**Tarih:** 17 Ocak 2026  
**Versiyon:** 1.0  
**Düzeltmeler:** Hizalama + Kategori Filtreleme
