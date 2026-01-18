# 🔥 Firestore'a Kaynak Ekleme Rehberi

**Sorun:** Realtime Database'de kaynaklar var ama Firestore'da sadece Webtekno var.

**Çözüm:** Realtime Database'deki kaynakları Firestore'a taşı!

---

## 📋 Adım Adım Rehber

### Adım 1: Firebase Console'a Git

1. https://console.firebase.google.com adresine git
2. Projenizi seçin (newsly-70ef9)
3. Sol menüden **Firestore Database** seçin

---

### Adım 2: news_sources Collection'ını Aç

1. Firestore'da `news_sources` collection'ını bul
2. Şu an sadece 1 document var (Webtekno)

---

### Adım 3: Yeni Kaynak Ekle (Manuel)

#### Örnek 1: Hürriyet Ekle

1. **"Add document"** butonuna tıkla
2. **Document ID:** `hurriyet` yaz
3. **Add field** ile alanları ekle:

```
Field: id          Type: string    Value: hurriyet
Field: name        Type: string    Value: Hürriyet
Field: rss_url     Type: string    Value: https://www.hurriyet.com.tr/rss/anasayfa
Field: category    Type: string    Value: Gündem
Field: is_active   Type: boolean   Value: true
```

4. **Save** butonuna tıkla

#### Örnek 2: Sözcü Ekle

1. **"Add document"** butonuna tıkla
2. **Document ID:** `sozcu` yaz
3. Alanları ekle:

```
Field: id          Type: string    Value: sozcu
Field: name        Type: string    Value: Sözcü
Field: rss_url     Type: string    Value: https://www.sozcu.com.tr/feed/
Field: category    Type: string    Value: Gündem
Field: is_active   Type: boolean   Value: true
```

4. **Save** butonuna tıkla

---

### Adım 4: Toplu Ekleme (JavaScript ile)

Firebase Console'da **Firestore** sayfasındayken:

1. **F12** tuşuna bas (Developer Tools)
2. **Console** sekmesine git
3. Aşağıdaki kodu yapıştır ve **Enter**'a bas:

```javascript
// Firestore referansı
const db = firebase.firestore();

// Eklenecek kaynaklar
const sources = [
  // GÜNDEM
  { id: 'hurriyet', name: 'Hürriyet', rss: 'https://www.hurriyet.com.tr/rss/anasayfa', category: 'Gündem' },
  { id: 'sozcu', name: 'Sözcü', rss: 'https://www.sozcu.com.tr/feed/', category: 'Gündem' },
  { id: 'ntv', name: 'NTV', rss: 'https://www.ntv.com.tr/gundem.rss', category: 'Gündem' },
  { id: 'cnn_turk', name: 'CNN Türk', rss: 'https://www.cnnturk.com/feed/rss/all/news', category: 'Gündem' },
  { id: 'sabah', name: 'Sabah', rss: 'https://www.sabah.com.tr/rss/anasayfa.xml', category: 'Gündem' },
  { id: 'aksam', name: 'Akşam', rss: 'https://www.aksam.com.tr/rss/anasayfa.xml', category: 'Gündem' },
  { id: 'star', name: 'Star', rss: 'https://www.star.com.tr/rss/rss.asp', category: 'Gündem' },
  { id: 'milliyet', name: 'Milliyet', rss: 'https://www.milliyet.com.tr/rss/rssnew/gundemrss.xml', category: 'Gündem' },
  
  // TEKNOLOJİ
  { id: 'teknoblog', name: 'Teknoblog', rss: 'https://www.teknoblog.com/feed/', category: 'Bilim & Teknoloji' },
  { id: 'donanim_haber', name: 'Donanım Haber', rss: 'https://www.donanimhaber.com/rss', category: 'Bilim & Teknoloji' },
  { id: 'webrazzi', name: 'Webrazzi', rss: 'https://webrazzi.com/feed/', category: 'Bilim & Teknoloji' },
  { id: 'shiftdelete', name: 'ShiftDelete', rss: 'https://shiftdelete.net/feed', category: 'Bilim & Teknoloji' },
  
  // SPOR
  { id: 'fotomac', name: 'Fotomaç', rss: 'https://www.fotomac.com.tr/rss', category: 'Spor' },
  { id: 'a_spor', name: 'A Spor', rss: 'https://www.aspor.com.tr/rss', category: 'Spor' },
  { id: 'fanatik', name: 'Fanatik', rss: 'https://www.fanatik.com.tr/rss', category: 'Spor' },
  { id: 'sporx', name: 'Sporx', rss: 'https://www.sporx.com/rss', category: 'Spor' },
  
  // EKONOMİ
  { id: 'bloomberg_ht', name: 'Bloomberg HT', rss: 'https://www.bloomberght.com/rss', category: 'Ekonomi' },
  { id: 'bigpara', name: 'BigPara', rss: 'https://bigpara.hurriyet.com.tr/rss', category: 'Ekonomi' },
  { id: 'dunya', name: 'Dünya', rss: 'https://www.dunya.com/rss', category: 'Ekonomi' },
  { id: 'ekonomim', name: 'Ekonomim', rss: 'https://www.ekonomim.com/rss', category: 'Ekonomi' },
];

// Batch işlemi başlat
const batch = db.batch();

// Her kaynağı ekle
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

// Batch'i commit et
batch.commit()
  .then(() => {
    console.log('✅ ' + sources.length + ' kaynak başarıyla eklendi!');
    alert('✅ ' + sources.length + ' kaynak eklendi! Sayfayı yenile.');
  })
  .catch(err => {
    console.error('❌ Hata:', err);
    alert('❌ Hata: ' + err.message);
  });
```

4. İşlem tamamlanınca **"✅ 20 kaynak eklendi!"** mesajı göreceksin
5. Sayfayı yenile (F5)
6. Artık 21 kaynak göreceksin (Webtekno + 20 yeni)

---

## 🚀 Hızlı Ekleme (5 Kaynak)

Sadece test için 5 kaynak eklemek istersen:

```javascript
const db = firebase.firestore();
const batch = db.batch();

const sources = [
  { id: 'hurriyet', name: 'Hürriyet', rss: 'https://www.hurriyet.com.tr/rss/anasayfa', category: 'Gündem' },
  { id: 'sozcu', name: 'Sözcü', rss: 'https://www.sozcu.com.tr/feed/', category: 'Gündem' },
  { id: 'teknoblog', name: 'Teknoblog', rss: 'https://www.teknoblog.com/feed/', category: 'Bilim & Teknoloji' },
  { id: 'fotomac', name: 'Fotomaç', rss: 'https://www.fotomac.com.tr/rss', category: 'Spor' },
  { id: 'bloomberg_ht', name: 'Bloomberg HT', rss: 'https://www.bloomberght.com/rss', category: 'Ekonomi' },
];

sources.forEach(s => {
  batch.set(db.collection('news_sources').doc(s.id), {
    id: s.id, name: s.name, rss_url: s.rss, category: s.category, is_active: true
  });
});

batch.commit().then(() => alert('✅ 5 kaynak eklendi!'));
```

---

## 📊 Realtime Database'den Firestore'a Taşıma

Eğer Realtime Database'deki TÜM kaynakları taşımak istersen:

### Adım 1: Realtime Database'den Export Et

1. Firebase Console → **Realtime Database**
2. `rss_sources` node'una git
3. Sağ üstteki **⋮** menüsüne tıkla
4. **Export JSON** seç
5. JSON dosyasını indir

### Adım 2: JSON'u Firestore'a Import Et

JSON dosyasını aç ve şu formatta düzenle:

```json
[
  {
    "id": "hurriyet",
    "name": "Hürriyet",
    "rss_url": "https://www.hurriyet.com.tr/rss/anasayfa",
    "category": "Gündem",
    "is_active": true
  },
  {
    "id": "sozcu",
    "name": "Sözcü",
    "rss_url": "https://www.sozcu.com.tr/feed/",
    "category": "Gündem",
    "is_active": true
  }
]
```

Sonra Firebase Console'da şu scripti çalıştır:

```javascript
const db = firebase.firestore();
const sources = [/* Yukarıdaki JSON'u buraya yapıştır */];

const batch = db.batch();
sources.forEach(s => {
  batch.set(db.collection('news_sources').doc(s.id), s);
});

batch.commit().then(() => alert('✅ Tüm kaynaklar eklendi!'));
```

---

## ✅ Kontrol Et

Kaynakları ekledikten sonra:

1. Firestore'da `news_sources` collection'ını aç
2. Kaç tane document var? (21+ olmalı)
3. Her document'in yapısı doğru mu?
4. `is_active: true` mi?

---

## 🎯 Uygulamayı Test Et

1. Uygulamayı kapat
2. Yeniden başlat: `flutter run`
3. Kaynak seçim ekranına git
4. Artık birden fazla kaynak göreceksin!
5. Birkaç kaynak seç (Hürriyet, Sözcü, Webtekno, vb.)
6. Anasayfaya dön
7. Artık farklı kaynaklardan haberler göreceksin!

---

## 📋 Örnek Kaynak Listesi (Kopyala-Yapıştır)

### Gündem (10 kaynak)
```
hurriyet - Hürriyet - https://www.hurriyet.com.tr/rss/anasayfa
sozcu - Sözcü - https://www.sozcu.com.tr/feed/
ntv - NTV - https://www.ntv.com.tr/gundem.rss
cnn_turk - CNN Türk - https://www.cnnturk.com/feed/rss/all/news
sabah - Sabah - https://www.sabah.com.tr/rss/anasayfa.xml
aksam - Akşam - https://www.aksam.com.tr/rss/anasayfa.xml
star - Star - https://www.star.com.tr/rss/rss.asp
milliyet - Milliyet - https://www.milliyet.com.tr/rss/rssnew/gundemrss.xml
trt_haber - TRT Haber - https://www.trthaber.com/sondakika.rss
a_haber - A Haber - https://www.ahaber.com.tr/rss/anasayfa.xml
```

### Teknoloji (5 kaynak)
```
webtekno - Webtekno - https://www.webtekno.com/rss.xml
teknoblog - Teknoblog - https://www.teknoblog.com/feed/
donanim_haber - Donanım Haber - https://www.donanimhaber.com/rss
webrazzi - Webrazzi - https://webrazzi.com/feed/
shiftdelete - ShiftDelete - https://shiftdelete.net/feed
```

### Spor (5 kaynak)
```
fotomac - Fotomaç - https://www.fotomac.com.tr/rss
a_spor - A Spor - https://www.aspor.com.tr/rss
fanatik - Fanatik - https://www.fanatik.com.tr/rss
sporx - Sporx - https://www.sporx.com/rss
fotospor - Fotospor - https://www.fotospor.com/rss
```

### Ekonomi (5 kaynak)
```
bloomberg_ht - Bloomberg HT - https://www.bloomberght.com/rss
bigpara - BigPara - https://bigpara.hurriyet.com.tr/rss
dunya - Dünya - https://www.dunya.com/rss
ekonomim - Ekonomim - https://www.ekonomim.com/rss
para - Para - https://www.para.com.tr/rss
```

---

## 🎉 Sonuç

Firestore'a en az 20-25 kaynak ekle, sonra uygulamayı test et!

**Önemli:** Her kaynağın şu alanları olmalı:
- `id` (string)
- `name` (string)
- `rss_url` (string)
- `category` (string)
- `is_active` (boolean - true)

---

**Hazırlayan:** Kiro AI Assistant  
**Tarih:** 17 Ocak 2026  
**Amaç:** Firestore'a Kaynak Ekleme
