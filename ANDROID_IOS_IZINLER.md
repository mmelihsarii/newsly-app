# Android ve iOS İzin Konfigürasyonları

## 📱 Android Konfigürasyonu

### 1. AndroidManifest.xml
**Dosya**: `android/app/src/main/AndroidManifest.xml`

`<manifest>` tagının içine, `<application>` tagından ÖNCE ekleyin:

```xml
<!-- Kamera izni -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Galeri izni (Android 12 ve altı) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="32" />

<!-- Galeri izni (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Kamera özelliği (opsiyonel, sadece kameralı cihazlarda çalışır) -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

`<application>` tagının içine ekleyin:

```xml
<!-- Image Cropper için UCrop Activity -->
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

### Tam Örnek:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- İZİNLER BURAYA -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
    
    <application
        android:label="haber"
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon">
        
        <!-- UCrop Activity -->
        <activity
            android:name="com.yalantis.ucrop.UCropActivity"
            android:screenOrientation="portrait"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
        
        <!-- Diğer activity'ler... -->
        <activity
            android:name=".MainActivity"
            ...>
        </activity>
    </application>
</manifest>
```

### 2. build.gradle.kts (Zaten Ayarlı)
**Dosya**: `android/app/build.gradle.kts`

```kotlin
android {
    defaultConfig {
        minSdk = 21  // Image Cropper için minimum
    }
}
```

## 🍎 iOS Konfigürasyonu

### Info.plist
**Dosya**: `ios/Runner/Info.plist`

`<dict>` tagının içine ekleyin:

```xml
<!-- Kamera İzni -->
<key>NSCameraUsageDescription</key>
<string>Profil resmi çekmek için kamera erişimi gerekiyor</string>

<!-- Galeri İzni (Okuma) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Profil resmi seçmek için galeri erişimi gerekiyor</string>

<!-- Galeri İzni (Yazma - iOS 14+) -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Profil resmi kaydetmek için galeri erişimi gerekiyor</string>
```

### Tam Örnek:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Mevcut ayarlar... -->
    <key>CFBundleName</key>
    <string>haber</string>
    
    <!-- KAMERA VE GALERİ İZİNLERİ -->
    <key>NSCameraUsageDescription</key>
    <string>Profil resmi çekmek için kamera erişimi gerekiyor</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Profil resmi seçmek için galeri erişimi gerekiyor</string>
    
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Profil resmi kaydetmek için galeri erişimi gerekiyor</string>
    
    <!-- Diğer ayarlar... -->
</dict>
</plist>
```

## 🔥 Firebase Storage Rules

**Firebase Console** > **Storage** > **Rules**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profil resimleri
    match /profile_images/{userId}.jpg {
      // Herkes okuyabilir (profil resimlerini görmek için)
      allow read: if true;
      
      // Sadece kendi profil resmini yükleyebilir/silebilir
      allow write: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
      
      // Dosya boyutu kontrolü (max 5MB)
      allow write: if request.resource.size < 5 * 1024 * 1024;
      
      // Dosya tipi kontrolü (sadece resim)
      allow write: if request.resource.contentType.matches('image/.*');
    }
  }
}
```

## 📋 Kontrol Listesi

### Android
- [ ] `AndroidManifest.xml` dosyasına kamera izni eklendi
- [ ] `AndroidManifest.xml` dosyasına galeri izinleri eklendi
- [ ] `AndroidManifest.xml` dosyasına UCrop activity eklendi
- [ ] `minSdk = 21` ayarlandı (zaten var)

### iOS
- [ ] `Info.plist` dosyasına kamera izni eklendi
- [ ] `Info.plist` dosyasına galeri izinleri eklendi
- [ ] İzin açıklamaları Türkçe ve anlaşılır

### Firebase
- [ ] Firebase Storage aktif
- [ ] Storage Rules ayarlandı
- [ ] `profile_images` klasörü oluşturuldu (otomatik oluşur)

### Flutter
- [ ] `flutter pub get` çalıştırıldı
- [ ] Paketler yüklendi (image_picker, firebase_storage, image_cropper)

## 🧪 Test Adımları

### 1. İzin Testi
```bash
# Android
flutter run

# iOS
flutter run
```

### 2. Kamera Testi
- Profil sayfasına git
- Kamera butonuna bas
- "Kamera" seçeneğini seç
- İzin isteyecek (ilk seferde)
- Fotoğraf çek
- Kırpma ekranı açılacak

### 3. Galeri Testi
- Profil sayfasına git
- Kamera butonuna bas
- "Galeri" seçeneğini seç
- İzin isteyecek (ilk seferde)
- Resim seç
- Kırpma ekranı açılacak

### 4. Firebase Storage Testi
- Resim yükle
- Firebase Console > Storage'a git
- `profile_images/{userId}.jpg` dosyasını gör
- Download URL'i kontrol et

## ⚠️ Yaygın Hatalar ve Çözümleri

### Hata 1: "Permission denied"
**Çözüm**: AndroidManifest.xml veya Info.plist'e izinleri ekleyin

### Hata 2: "UCropActivity not found"
**Çözüm**: AndroidManifest.xml'e UCrop activity'yi ekleyin

### Hata 3: "Image picker not working"
**Çözüm**: 
```bash
flutter clean
flutter pub get
flutter run
```

### Hata 4: "Firebase Storage upload failed"
**Çözüm**: Firebase Storage Rules'u kontrol edin

### Hata 5: "Image cropper crashes on Android"
**Çözüm**: `minSdk = 21` olduğundan emin olun

## 📱 Platform Özellikleri

### Android
- Kamera ve galeri ayrı izinler
- Android 13+ için yeni izin sistemi
- UCrop kütüphanesi kullanılır
- Material Design

### iOS
- Kamera ve galeri ayrı izinler
- iOS 14+ için yeni izin sistemi
- Native iOS cropper kullanılır
- Cupertino Design

## 🎯 Sonuç

Tüm izinler eklendikten sonra:
1. Uygulamayı yeniden derleyin
2. İzinleri test edin
3. Firebase Storage'ı kontrol edin
4. Profil resmi yükleme/silme işlemlerini test edin

## 📞 Destek

Sorun yaşarsanız:
1. `flutter doctor` çalıştırın
2. `flutter clean` yapın
3. Paketleri yeniden yükleyin
4. Firebase konfigürasyonunu kontrol edin
