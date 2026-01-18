# Firebase Storage Kurulum Rehberi

## 🔥 Sorun
Profil resmi yüklenirken şu hata alınıyor:
```
E/StorageException: Object does not exist at location.
Code: -13010 HttpResult: 404
```

Bu hata, Firebase Storage'ın doğru yapılandırılmadığını gösteriyor.

## ✅ Çözüm Adımları

### 1. Firebase Console'a Git
1. [Firebase Console](https://console.firebase.google.com/) aç
2. Projenizi seçin (`newsly` veya proje adınız)

### 2. Storage'ı Aktifleştir
1. Sol menüden **Build** > **Storage** seçin
2. Eğer Storage aktif değilse **Get Started** butonuna tıklayın
3. **Start in test mode** seçin (geliştirme için)
4. **Next** ve **Done** tıklayın

### 3. Storage Rules'ı Ayarla
1. Storage sayfasında **Rules** sekmesine git
2. Aşağıdaki kuralları yapıştır:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Profil resimleri - Sadece kendi resmini yükleyebilir/silebilir
    match /profile_images/{userId}.jpg {
      allow read: if true; // Herkes okuyabilir
      allow write: if request.auth != null && request.auth.uid == userId; // Sadece sahibi yazabilir
      allow delete: if request.auth != null && request.auth.uid == userId; // Sadece sahibi silebilir
    }
    
    // Diğer tüm dosyalar için varsayılan kural
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. **Publish** butonuna tıklayın

### 4. Storage Location Kontrol
1. Storage sayfasında bucket adını kontrol edin
2. Genellikle şu formatta olur: `your-project-id.appspot.com`
3. Eğer bucket yoksa, yeni bir bucket oluşturun

### 5. Firebase Config Kontrol
`android/app/google-services.json` dosyasında Storage bucket'ı kontrol edin:

```json
{
  "project_info": {
    "storage_bucket": "your-project-id.appspot.com"
  }
}
```

`ios/Runner/GoogleService-Info.plist` dosyasında:

```xml
<key>STORAGE_BUCKET</key>
<string>your-project-id.appspot.com</string>
```

## 🎯 Test Etme

### 1. Uygulamayı Yeniden Başlat
```bash
flutter clean
flutter pub get
flutter run
```

### 2. Profil Resmi Yükle
1. Profil sayfasına git
2. Kamera ikonuna tıkla
3. Galeri veya kamera seç
4. Resmi kırp
5. Yükleme başarılı olmalı

### 3. Firebase Console'da Kontrol
1. Storage > Files sekmesine git
2. `profile_images/` klasörünü aç
3. `{userId}.jpg` dosyasını görmelisin

## 🔒 Güvenlik Kuralları Açıklaması

### Test Mode (Geliştirme)
```javascript
match /{allPaths=**} {
  allow read, write: if true; // Herkes her şeyi yapabilir (GÜVENLİ DEĞİL!)
}
```

### Production Mode (Önerilen)
```javascript
match /profile_images/{userId}.jpg {
  allow read: if true; // Herkes profil resimlerini görebilir
  allow write: if request.auth != null && request.auth.uid == userId; // Sadece sahibi değiştirebilir
}
```

## 🐛 Yaygın Hatalar ve Çözümleri

### Hata 1: "Object does not exist"
**Sebep**: Storage bucket'ı aktif değil veya rules yanlış
**Çözüm**: Yukarıdaki adımları takip et

### Hata 2: "Permission denied"
**Sebep**: Storage rules çok kısıtlayıcı
**Çözüm**: Rules'ı kontrol et, test mode'da dene

### Hata 3: "No AppCheckProvider installed"
**Sebep**: App Check yapılandırılmamış (opsiyonel)
**Çözüm**: Şimdilik görmezden gelebilirsin, kritik değil

### Hata 4: "Unknown calling package name"
**Sebep**: Google Play Services sorunu
**Çözüm**: Emülatörde test ediyorsan normal, gerçek cihazda dene

## 📱 Platform Özel Ayarlar

### Android
`android/app/build.gradle.kts` dosyasında Firebase Storage dependency'si olmalı:
```kotlin
dependencies {
    implementation("com.google.firebase:firebase-storage")
}
```

### iOS
`ios/Podfile` dosyasında:
```ruby
pod 'FirebaseStorage'
```

Sonra:
```bash
cd ios
pod install
cd ..
```

## 🎨 Storage Yapısı

```
your-project-bucket/
└── profile_images/
    ├── user1-uid.jpg
    ├── user2-uid.jpg
    └── user3-uid.jpg
```

## 💡 İpuçları

1. **Dosya Boyutu**: Resimler otomatik olarak 80% kalitede sıkıştırılıyor
2. **Format**: Tüm resimler JPEG olarak kaydediliyor
3. **İsimlendirme**: `{userId}.jpg` formatı kullanılıyor
4. **Güvenlik**: Her kullanıcı sadece kendi resmini değiştirebilir
5. **Okuma**: Herkes profil resimlerini görebilir (public)

## 🔄 Güncelleme Akışı

```
1. Kullanıcı resim seçer
   ↓
2. Resim kırpılır (1:1 oran, daire)
   ↓
3. Firebase Storage'a yüklenir
   ↓
4. Download URL alınır
   ↓
5. Firestore'da photoUrl güncellenir
   ↓
6. UI otomatik güncellenir
```

## ✅ Kontrol Listesi

- [ ] Firebase Console'da Storage aktif
- [ ] Storage Rules yapılandırıldı
- [ ] google-services.json güncel
- [ ] GoogleService-Info.plist güncel
- [ ] Flutter clean yapıldı
- [ ] Uygulama yeniden başlatıldı
- [ ] Gerçek cihazda test edildi

## 🎯 Sonuç

Bu adımları tamamladıktan sonra profil resmi yükleme özelliği çalışmalı. Hala sorun yaşıyorsan:

1. Firebase Console'da Storage logs'ları kontrol et
2. Flutter logs'ları dikkatlice oku
3. Gerçek cihazda test et (emülatör sorunlu olabilir)
4. Firebase config dosyalarını yeniden indir

Başarılar! 🚀
