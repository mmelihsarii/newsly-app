# Newsly Uygulama Kurulum Rehberi

## Gereksinimler

- Flutter SDK 3.38+ kurulu olmalı
- Android Studio veya Xcode (iOS için)
- Git

---

## ADIM 1: Proje Dosyalarını Yerleştirme

1. Gönderilen ZIP dosyasını açın
2. Tüm dosyaları proje klasörüne kopyalayın (mevcut dosyaların üzerine yazın)

---

## ADIM 2: Bağımlılıkları Yükleme

Terminal/Komut satırında proje klasörüne gidin ve çalıştırın:

```bash
flutter clean
flutter pub get
```

---

## ADIM 3: Android Build (APK/AAB)

### Debug APK (Test için):
```bash
flutter build apk --debug
```
Çıktı: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (Dağıtım için):
```bash
flutter build apk --release
```
Çıktı: `build/app/outputs/flutter-apk/app-release.apk`

### Google Play için AAB:
```bash
flutter build appbundle --release
```
Çıktı: `build/app/outputs/bundle/release/app-release.aab`

---

## ADIM 4: iOS Build

### 1. iOS bağımlılıklarını yükleyin:
```bash
cd ios
pod install --repo-update
cd ..
```

### 2. Xcode'da açın:
```bash
open ios/Runner.xcworkspace
```

### 3. Xcode'da yapılacaklar:

**a) Signing & Capabilities:**
- Runner > Signing & Capabilities
- Team: Apple Developer hesabınızı seçin
- Bundle Identifier: `com.newsly.haber` (veya kendi identifier'ınız)

**b) Push Notifications (Bildirimler için):**
- "+ Capability" butonuna tıklayın
- "Push Notifications" ekleyin
- "Background Modes" ekleyin → "Remote notifications" işaretleyin

**c) Build:**
- Product > Archive (App Store için)
- Veya Product > Build (test için)

---

## ADIM 5: Firebase Ayarları (Zaten yapılmış olmalı)

Eğer Firebase yapılandırması eksikse:

### Android:
- `android/app/google-services.json` dosyası mevcut olmalı

### iOS:
- `ios/Runner/GoogleService-Info.plist` dosyası mevcut olmalı

---

## ADIM 6: iOS Google Sign-In (Önemli!)

iOS'ta Google girişinin çalışması için Firebase Console'da:

1. Firebase Console > Authentication > Sign-in method
2. Google provider'ı etkinleştirin
3. iOS uygulaması için SHA-1 sertifikası ekleyin

---

## ADIM 7: iOS Push Notifications (Önemli!)

iOS'ta bildirimlerin çalışması için:

1. Apple Developer Console'da:
   - Certificates, Identifiers & Profiles > Keys
   - Yeni bir key oluşturun, "Apple Push Notifications service (APNs)" seçin
   - Key'i indirin (.p8 dosyası)

2. Firebase Console'da:
   - Project Settings > Cloud Messaging > Apple app configuration
   - APNs Authentication Key yükleyin (.p8 dosyası)
   - Key ID ve Team ID girin

---

## Sorun Giderme

### "CocoaPods not found" hatası:
```bash
sudo gem install cocoapods
```

### iOS build hatası:
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter clean
flutter build ios
```

### Android keystore hatası:
`android/key.properties` dosyasının mevcut olduğundan emin olun:
```
storePassword=newsly2026
keyPassword=newsly2026
keyAlias=upload
storeFile=upload-keystore.jks
```

### Gradle hatası:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk
```

---

## Önemli Dosyalar (Saklanmalı!)

| Dosya | Açıklama |
|-------|----------|
| `android/app/upload-keystore.jks` | Android imza dosyası - KAYBETMEYİN! |
| `android/key.properties` | Keystore şifreleri |
| `android/app/google-services.json` | Firebase Android config |
| `ios/Runner/GoogleService-Info.plist` | Firebase iOS config |

---

## Hızlı Komutlar

```bash
# Temiz build
flutter clean && flutter pub get && flutter build apk --release

# iOS temiz build
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter build ios --release

# Cihazda çalıştır
flutter run

# Bağlı cihazları listele
flutter devices
```

---

## Destek

Herhangi bir sorun yaşarsanız hata mesajını paylaşın.
