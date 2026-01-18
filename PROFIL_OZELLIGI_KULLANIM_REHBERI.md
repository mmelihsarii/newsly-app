# Profil Özelliği Kullanım Rehberi

## 🎯 Genel Bakış

Kullanıcılar artık profil sayfasından:
- ✅ Profil resmi yükleyebilir (kamera veya galeri)
- ✅ Profil resmini Instagram tarzı kırpabilir (daire)
- ✅ Ad, soyad, hakkında bilgilerini düzenleyebilir
- ✅ Profil resmini kaldırabilir

## 📱 Kullanıcı Akışı

### 1. Profil Sayfasına Gitme
```
Dashboard → Profil İkonu → Profil Sayfası
```

### 2. Profil Resmi Yükleme

#### Adım 1: Kamera Butonuna Bas
- Profil resminin sağ alt köşesindeki kırmızı kamera butonuna bas

#### Adım 2: Kaynak Seç
Bottom sheet açılır, 3 seçenek:
- 📷 **Kamera** - Fotoğraf çek
- 🖼️ **Galeri** - Galeriden seç
- 🗑️ **Resmi Kaldır** - Profil resmini sil (sadece resim varsa görünür)

#### Adım 3: İzin Ver (İlk Seferde)
- Android: "Kamera/Galeri erişimine izin ver" → İzin Ver
- iOS: "Newsly kamera/galeri kullanmak istiyor" → İzin Ver

#### Adım 4: Resim Seç/Çek
- **Kamera**: Fotoğraf çek → ✓ işaretine bas
- **Galeri**: Resim seç → Seç butonuna bas

#### Adım 5: Resmi Kırp (Instagram Tarzı)
- Resim kırpma ekranı açılır
- Daire içinde resmi ayarla
- Pinch to zoom (yakınlaştır/uzaklaştır)
- Drag to move (sürükle)
- ✓ işaretine bas

#### Adım 6: Yükleme
- Loading gösterilir
- Firebase Storage'a yüklenir
- "Profil resminiz güncellendi" mesajı
- Profil resmi güncellenir

### 3. Profil Bilgilerini Düzenleme

#### Adım 1: Düzenle Butonuna Bas
- "Bilgileri Düzenle" butonuna bas
- Modal dialog açılır

#### Adım 2: Bilgileri Gir
- **Ad** (zorunlu)
- **Soyad** (opsiyonel)
- **Hakkında** (opsiyonel, 4 satır)

#### Adım 3: Kaydet
- "Kaydet" butonuna bas
- Loading gösterilir
- Firestore'da güncellenir
- "Profiliniz güncellendi" mesajı
- Dialog kapanır
- Profil bilgileri güncellenir

### 4. Profil Resmini Kaldırma

#### Adım 1: Kamera Butonuna Bas
- Profil resminin sağ alt köşesindeki kamera butonuna bas

#### Adım 2: Resmi Kaldır Seç
- "Resmi Kaldır" seçeneğine bas

#### Adım 3: Onay
- Firebase Storage'dan silinir
- Firestore'da güncellenir
- "Profil resminiz kaldırıldı" mesajı
- Placeholder gösterilir

## 🎨 Ekran Görünümleri

### Profil Sayfası
```
┌─────────────────────────────┐
│  ← Profil                   │
├─────────────────────────────┤
│                             │
│        ┌─────────┐          │
│        │         │          │
│        │  👤     │ 📷       │
│        │         │          │
│        └─────────┘          │
│                             │
│      Ahmet Yılmaz           │
│                             │
├─────────────────────────────┤
│  Profil Bilgileri           │
│                             │
│  ┌─────────────────────┐   │
│  │ 👤 Ad                │   │
│  │    Ahmet             │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ 👤 Soyad             │   │
│  │    Yılmaz            │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ ℹ️ Hakkında          │   │
│  │    Teknoloji...      │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │  ✏️ Bilgileri Düzenle│   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │  🗑️ Hesabımı Sil     │   │
│  └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

### Bottom Sheet (Resim Kaynağı)
```
┌─────────────────────────────┐
│      Profil Resmi Seç       │
├─────────────────────────────┤
│  ┌─────────────────────┐   │
│  │ 📷 Kamera            →│   │
│  │    Fotoğraf çek      │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ 🖼️ Galeri            →│   │
│  │    Galeriden seç     │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ 🗑️ Resmi Kaldır      →│   │
│  │    Profil resmini sil│   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

### Düzenleme Dialog'u
```
┌─────────────────────────────┐
│  Profili Düzenle        ✕   │
├─────────────────────────────┤
│                             │
│  Ad                         │
│  ┌─────────────────────┐   │
│  │ Ahmet            👤 │   │
│  └─────────────────────┘   │
│                             │
│  Soyad                      │
│  ┌─────────────────────┐   │
│  │ Yılmaz           👤 │   │
│  └─────────────────────┘   │
│                             │
│  Hakkında                   │
│  ┌─────────────────────┐   │
│  │ Teknoloji           │   │
│  │ meraklısı...     ℹ️ │   │
│  │                     │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │      Kaydet          │   │
│  └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

### Resim Kırpma Ekranı
```
┌─────────────────────────────┐
│  Resmi Düzenle          ✓   │
├─────────────────────────────┤
│                             │
│      ┌───────────┐          │
│      │           │          │
│      │   ╭───╮   │          │
│      │   │   │   │          │
│      │   │ 📷│   │          │
│      │   │   │   │          │
│      │   ╰───╯   │          │
│      │           │          │
│      └───────────┘          │
│                             │
│  Pinch to zoom              │
│  Drag to move               │
│                             │
└─────────────────────────────┘
```

## 🔧 Teknik Detaylar

### Dosya Yapısı
```
lib/
├── controllers/
│   └── profile_controller.dart    # Profil yönetimi
├── views/
│   └── profile/
│       └── profile_view.dart      # Profil UI
└── services/
    └── user_service.dart          # Firestore işlemleri
```

### Firebase Storage Yapısı
```
firebase_storage/
└── profile_images/
    ├── user123.jpg
    ├── user456.jpg
    └── user789.jpg
```

### Firestore Yapısı
```json
users/{userId}
{
  "uid": "user123",
  "email": "user@example.com",
  "firstName": "Ahmet",
  "lastName": "Yılmaz",
  "displayName": "Ahmet Yılmaz",
  "about": "Teknoloji meraklısı",
  "photoUrl": "https://firebasestorage.../user123.jpg",
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

## ⚡ Performans

### Resim Optimizasyonu
- Resim kalitesi: %80
- Format: JPEG
- Kırpma: 1:1 (kare)
- Maksimum boyut: 5MB

### Yükleme Süreleri
- Resim seçme: Anında
- Kırpma: 1-2 saniye
- Firebase yükleme: 2-5 saniye (internet hızına bağlı)
- Firestore güncelleme: 1 saniye

## 🔒 Güvenlik

### Firebase Storage Rules
- Herkes profil resimlerini görebilir (read: true)
- Sadece kendi resmini yükleyebilir (write: auth.uid == userId)
- Maksimum dosya boyutu: 5MB
- Sadece resim dosyaları (image/*)

### Firestore Rules
- Herkes profil bilgilerini okuyabilir
- Sadece kendi profilini güncelleyebilir
- Email değiştirilemez

## ❌ Hata Durumları

### İzin Reddedildi
```
Mesaj: "Kamera/Galeri erişimi reddedildi"
Çözüm: Ayarlar → Uygulamalar → Newsly → İzinler
```

### Resim Yüklenemedi
```
Mesaj: "Resim yüklenirken hata oluştu"
Çözüm: İnternet bağlantısını kontrol et
```

### Profil Güncellenemedi
```
Mesaj: "Profil güncellenemedi"
Çözüm: İnternet bağlantısını kontrol et
```

### Ad Boş
```
Mesaj: "Lütfen adınızı girin"
Çözüm: Ad alanını doldur
```

## 📊 Kullanıcı İstatistikleri

### Başarılı İşlemler
- ✅ Profil resmi yüklendi
- ✅ Profil güncellendi
- ✅ Profil resmi kaldırıldı

### Hata İşlemleri
- ❌ İzin reddedildi
- ❌ Resim yüklenemedi
- ❌ Profil güncellenemedi

## 🎓 İpuçları

### Profil Resmi İçin
- ✅ Yüzünüzün net göründüğü bir resim seçin
- ✅ İyi aydınlatılmış fotoğraflar kullanın
- ✅ Kare formatında resimler daha iyi görünür
- ❌ Çok karanlık veya bulanık resimler kullanmayın

### Profil Bilgileri İçin
- ✅ Gerçek adınızı kullanın
- ✅ Hakkında kısmını doldurun (opsiyonel)
- ✅ Kısa ve öz bilgiler verin
- ❌ Çok uzun metinler yazmayın

## 🔄 Güncelleme Süreci

### Profil Resmi Güncelleme
1. Yeni resim seç
2. Kırp
3. Yükle
4. Eski resim otomatik silinir
5. Yeni resim gösterilir

### Profil Bilgileri Güncelleme
1. Bilgileri düzenle
2. Kaydet
3. Firestore'da güncellenir
4. Anında yansır

## 📞 Destek

### Sorun Yaşıyorsanız
1. İnternet bağlantınızı kontrol edin
2. Uygulama izinlerini kontrol edin
3. Uygulamayı yeniden başlatın
4. Uygulamayı güncelleyin

### Yaygın Sorular

**S: Profil resmim neden yüklenmiyor?**
C: İnternet bağlantınızı ve kamera/galeri izinlerini kontrol edin.

**S: Profil resmimi nasıl değiştirebilirim?**
C: Profil resmindeki kamera butonuna basın ve yeni resim seçin.

**S: Profil resmimi nasıl kaldırabilirim?**
C: Kamera butonuna basın ve "Resmi Kaldır" seçeneğini seçin.

**S: Profil bilgilerimi nasıl düzenleyebilirim?**
C: "Bilgileri Düzenle" butonuna basın ve bilgilerinizi güncelleyin.

**S: Ad alanı zorunlu mu?**
C: Evet, ad alanı zorunludur. Soyad ve hakkında opsiyoneldir.

## ✨ Özellikler

- ✅ Instagram tarzı resim kırpma
- ✅ Kamera ve galeri desteği
- ✅ Firebase Storage entegrasyonu
- ✅ Gerçek zamanlı güncelleme
- ✅ Loading göstergeleri
- ✅ Hata yönetimi
- ✅ Responsive tasarım
- ✅ Modern UI/UX

## 🎯 Sonuç

Profil özelliği kullanıcı dostu, güvenli ve performanslı bir şekilde çalışmaktadır. Kullanıcılar kolayca profil resmi yükleyebilir ve bilgilerini düzenleyebilir.
