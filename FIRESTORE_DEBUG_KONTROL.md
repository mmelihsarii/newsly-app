# 🔍 Firestore Debug Kontrol Listesi

**Tarih:** 17 Ocak 2026  
**Sorun:** Sadece Webtekno gözüküyor

---

## 🎯 Muhtemel Sebepler

### 1. ❌ Firestore'da Sadece 1 Kaynak Var
**En Olası Sebep!**

Firestore'da `news_sources` collection'ında sadece Webtekno kaynağı var.

**Kontrol:**
1. Firebase Console'a git: https://console.firebase.google.com
2. Projenizi seçin
3. Firestore Database'e git
4. `news_sources` collection'ını aç
5. Kaç tane kaynak var? Sadece 1 mi?

**Çözüm:**
Daha fazla kaynak ekle! (Aşağıda script var)

---

### 2. ❌ Diğer Kaynaklar `is_active: false`
Diğer kaynaklar var ama `is_active` alanı `false` olabilir.

**Kontrol:**
```javascript
// Firebase Console > Firestore > news_sources
// Her kaynağın is_active alanına bak
```

**Çözüm:**
```javascript
// Tüm kaynakları aktif yap
db.collection('news_sources').get().then(snapshot => {
  snapshot.forEach(doc => {
    doc.ref.update({ is_active: true });
  });
});
```

---

### 3. ❌ RSS URL'leri Çalışmıyor
Diğer kaynakların RSS URL'leri geçersiz veya erişilemiyor olabilir.

**Kontrol:**
Console loglarına bak:
```
⚠️ Hürriyet (https://...) hatası: Failed to load
⚠️ Sözcü (https://...) hatası: Connection timeout
```

**Çözüm:**
RSS URL'lerini test et ve düzelt.

---

### 4. ❌ Firestore Bağlantı Sorunu
Firebase bağlantısı çalışmıyor olabilir.

**Kontrol:**
Console'da şunu gör:
```
❌ Kaynak çekme hatası: [firebase_core/no-app]
```

**Çözüm:**
- `google-services.json` dosyasını kontrol et
- Firebase yapılandırmasını kontrol et
- İnternet bağlantısını kontrol et

---

### 5. ❌ Cache Sorunu
Eski veriler cache'de kalmış olabilir.

**Çözüm:**
```bash
# Uygulamayı tamamen kapat
# Cache'i temizle
flutter clean
flutter pub get
flutter run
```

---

## 🔍 Debug Adımları

### Adım 1: Console Loglarını Kontrol Et

Uygulamayı çalıştır ve console'da şunu ara:

```
🔥 Firestore'dan kaynaklar çekiliyor...
📰 Firestore'da X aktif kaynak var
```

**X = 1 ise:**
```
⚠️⚠️⚠️ FIRESTORE'DA SADECE 1 KAYNAK VAR! ⚠️⚠️⚠️
📋 Tek kaynak: Webtekno (Bilim & Teknoloji)
⚠️ Daha fazla kaynak eklemen gerekiyor!
```
→ **Firestore'a kaynak ekle!**

**X = 0 ise:**
```
❌❌❌ FIRESTORE'DA HİÇ KAYNAK YOK! ❌❌❌
⚠️ Firebase Console'a git ve 'news_sources' collection'ına kaynak ekle!
```
→ **Firestore'a kaynak ekle!**

**X > 1 ise:**
```
✅ TÜM KAYNAKLAR KULLANILIYOR: 218
📋 FIRESTORE'DAKİ TÜM KAYNAKLAR:
   1. Hürriyet - Gündem - https://...
   2. Sözcü - Gündem - https://...
   3. Webtekno - Bilim & Teknoloji - https://...
   ...
```
→ **Sorun başka yerde!**

---

### Adım 2: Firestore'u Kontrol Et

1. **Firebase Console'a git:**
   https://console.firebase.google.com

2. **Projenizi seçin**

3. **Firestore Database'e git**

4. **`news_sources` collection'ını kontrol et:**
   - Kaç tane document var?
   - Her document'in yapısı doğru mu?
   - `is_active` alanı `true` mu?

---

### Adım 3: Örnek Kaynak Ekle

Firebase Console > Firestore > news_sources > Add Document

**Document ID:** `hurriyet`

**Fields:**
```json
{
  "id": "hurriyet",
  "name": "Hürriyet",
  "rss_url": "https://www.hurriyet.com.tr/rss/anasayfa",
  "category": "Gündem",
  "is_active": true
}
```

Kaydet ve uygulamayı yeniden başlat!

---

## 🚀 Toplu Kaynak Ekleme Scripti

### JavaScript (Firebase Console)

```javascript
// Firebase Console > Firestore > news_sources
// Console'u aç (F12) ve şunu çalıştır:

const db = firebase.firestore();
const batch = db.batch();

const sources = [
  // Gündem
  { id: 'hurriyet', name: 'Hürriyet', rss: 'https://www.hurriyet.com.tr/rss/anasayfa', category: 'Gündem' },
  { id: 'sozcu', name: 'Sözcü', rss: 'https://www.sozcu.com.tr/feed/', category: 'Gündem' },
  { id: 'ntv', name: 'NTV', rss: 'https://www.ntv.com.tr/gundem.rss', category: 'Gündem' },
  { id: 'cnn_turk', name: 'CNN Türk', rss: 'https://www.cnnturk.com/feed/rss/all/news', category: 'Gündem' },
  { id: 'bbc', name: 'BBC Türkçe', rss: 'https://feeds.bbci.co.uk/turkce/rss.xml', category: 'Gündem' },
  
  // Teknoloji
  { id: 'webtekno', name: 'Webtekno', rss: 'https://www.webtekno.com/rss.xml', category: 'Bilim & Teknoloji' },
  { id: 'teknoblog', name: 'Teknoblog', rss: 'https://www.teknoblog.com/feed/', category: 'Bilim & Teknoloji' },
  { id: 'donanim_haber', name: 'Donanım Haber', rss: 'https://www.donanimhaber.com/rss', category: 'Bilim & Teknoloji' },
  
  // Spor
  { id: 'fotomac', name: 'Fotomaç', rss: 'https://www.fotomac.com.tr/rss', category: 'Spor' },
  { id: 'a_spor', name: 'A Spor', rss: 'https://www.aspor.com.tr/rss', category: 'Spor' },
  
  // Ekonomi
  { id: 'bloomberg_ht', name: 'Bloomberg HT', rss: 'https://www.bloomberght.com/rss', category: 'Ekonomi' },
  { id: 'bigpara', name: 'BigPara', rss: 'https://bigpara.hurriyet.com.tr/rss', category: 'Ekonomi' },
];

sources.forEach(source => {
  const ref = db.collection('news_sources').doc(source.id);
  batch.set(ref, {
    id: source.id,
    name: source.name,
    rss_url: source.rss,
    category: source.category,
    is_active: true,
    created_at: firebase.firestore.FieldValue.serverTimestamp(),
  });
});

batch.commit().then(() => {
  console.log('✅ 12 kaynak eklendi!');
}).catch(err => {
  console.error('❌ Hata:', err);
});
```

---

## 📱 Manuel Ekleme (Firebase Console)

### 1. Hürriyet Ekle

**Document ID:** `hurriyet`

```
id: "hurriyet"
name: "Hürriyet"
rss_url: "https://www.hurriyet.com.tr/rss/anasayfa"
category: "Gündem"
is_active: true
```

### 2. Sözcü Ekle

**Document ID:** `sozcu`

```
id: "sozcu"
name: "Sözcü"
rss_url: "https://www.sozcu.com.tr/feed/"
category: "Gündem"
is_active: true
```

### 3. NTV Ekle

**Document ID:** `ntv`

```
id: "ntv"
name: "NTV"
rss_url: "https://www.ntv.com.tr/gundem.rss"
category: "Gündem"
is_active: true
```

### 4. Teknoblog Ekle

**Document ID:** `teknoblog`

```
id: "teknoblog"
name: "Teknoblog"
rss_url: "https://www.teknoblog.com/feed/"
category: "Bilim & Teknoloji"
is_active: true
```

### 5. Fotomaç Ekle

**Document ID:** `fotomac`

```
id: "fotomac"
name: "Fotomaç"
rss_url: "https://www.fotomac.com.tr/rss"
category: "Spor"
is_active: true
```

---

## 🧪 Test Adımları

### Test 1: Kaynak Sayısını Kontrol Et

1. Uygulamayı çalıştır
2. Console'da şunu ara:
   ```
   📰 Firestore'da X aktif kaynak var
   ```
3. X > 1 olmalı!

### Test 2: Kaynak Listesini Kontrol Et

Console'da şunu ara:
```
📋 FIRESTORE'DAKİ TÜM KAYNAKLAR:
   1. Hürriyet - Gündem - https://...
   2. Sözcü - Gündem - https://...
   3. Webtekno - Bilim & Teknoloji - https://...
```

Birden fazla kaynak görmeli!

### Test 3: Haber Sayısını Kontrol Et

Console'da şunu ara:
```
🚀 X kaynaktan haberler çekiliyor...
✅ Hürriyet: 25 haber
✅ Sözcü: 30 haber
✅ Webtekno: 15 haber
...
📰 TOPLAM X HABER ÇEKİLDİ!
```

Birden fazla kaynaktan haber gelmeli!

---

## 🎯 Beklenen Sonuç

### Console Logları:
```
🔥 Firestore'dan kaynaklar çekiliyor...
📰 Firestore'da 12 aktif kaynak var
✅ TÜM KAYNAKLAR KULLANILIYOR: 12
📋 FIRESTORE'DAKİ TÜM KAYNAKLAR:
   1. Hürriyet - Gündem - https://www.hurriyet.com.tr/rss/anasayfa
   2. Sözcü - Gündem - https://www.sozcu.com.tr/feed/
   3. NTV - Gündem - https://www.ntv.com.tr/gundem.rss
   4. CNN Türk - Gündem - https://www.cnnturk.com/feed/rss/all/news
   5. BBC Türkçe - Gündem - https://feeds.bbci.co.uk/turkce/rss.xml
   6. Webtekno - Bilim & Teknoloji - https://www.webtekno.com/rss.xml
   7. Teknoblog - Bilim & Teknoloji - https://www.teknoblog.com/feed/
   8. Donanım Haber - Bilim & Teknoloji - https://www.donanimhaber.com/rss
   9. Fotomaç - Spor - https://www.fotomac.com.tr/rss
   10. A Spor - Spor - https://www.aspor.com.tr/rss
   11. Bloomberg HT - Ekonomi - https://www.bloomberght.com/rss
   12. BigPara - Ekonomi - https://bigpara.hurriyet.com.tr/rss

🚀 12 kaynaktan haberler çekiliyor...
✅ Hürriyet: 25 haber
✅ Sözcü: 30 haber
✅ NTV: 20 haber
✅ CNN Türk: 22 haber
✅ BBC Türkçe: 18 haber
✅ Webtekno: 15 haber
✅ Teknoblog: 18 haber
✅ Donanım Haber: 12 haber
✅ Fotomaç: 20 haber
✅ A Spor: 25 haber
✅ Bloomberg HT: 15 haber
✅ BigPara: 12 haber

📰 TOPLAM 232 HABER ÇEKİLDİ!
🔀 Haberler karıştırıldı!
```

---

## ✅ Kontrol Listesi

- [ ] Firebase Console'a gittim
- [ ] `news_sources` collection'ını kontrol ettim
- [ ] Kaç tane kaynak var? _____ (1'den fazla olmalı!)
- [ ] Tüm kaynakların `is_active: true` olduğunu kontrol ettim
- [ ] Yeni kaynaklar ekledim (en az 10 tane)
- [ ] Uygulamayı yeniden başlattım
- [ ] Console loglarını kontrol ettim
- [ ] Birden fazla kaynaktan haber geliyor mu?

---

## 🎉 Sonuç

Eğer Firestore'da sadece Webtekno varsa, **daha fazla kaynak eklemen gerekiyor!**

Yukarıdaki scriptleri kullanarak 10-20 kaynak ekle ve uygulamayı yeniden başlat.

**Durum:** 🔍 Debug Modu Aktif - Console Loglarını Kontrol Et!

---

**Hazırlayan:** Kiro AI Assistant  
**Tarih:** 17 Ocak 2026  
**Versiyon:** 1.0  
**Amaç:** Firestore Debug ve Kaynak Ekleme
