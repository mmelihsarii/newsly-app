# iOS Push Notification Kurulum Rehberi

## ÖNEMLİ: Apple Developer Console Ayarları

iOS'a bildirim göndermek için Apple Developer Console'da APNs (Apple Push Notification service) yapılandırması gerekiyor.

### 1. APNs Key Oluşturma (Önerilen Yöntem)

1. [Apple Developer Console](https://developer.apple.com/account) → Certificates, Identifiers & Profiles
2. **Keys** → **+** butonuna tıkla
3. Key Name: `Newsly Push Key`
4. **Apple Push Notifications service (APNs)** kutusunu işaretle
5. **Continue** → **Register**
6. **.p8 dosyasını indir** (sadece 1 kez indirilir!)
7. **Key ID**'yi not al (10 karakterlik kod)

### 2. Firebase'e APNs Key Yükleme

1. [Firebase Console](https://console.firebase.google.com) → Projenizi seçin
2. ⚙️ **Project Settings** → **Cloud Messaging** sekmesi
3. **Apple app configuration** bölümünde:
   - **APNs Authentication Key** → **Upload**
   - İndirdiğiniz **.p8 dosyasını** yükleyin
   - **Key ID**: Apple'dan aldığınız 10 karakterlik kod
   - **Team ID**: Apple Developer hesabınızın Team ID'si
     - (Developer Console → Membership → Team ID)

### 3. App ID Yapılandırması

1. Apple Developer Console → **Identifiers**
2. `com.newsly.haber` App ID'sini seçin (yoksa oluşturun)
3. **Capabilities** bölümünde:
   - ✅ **Push Notifications** - Enabled
   - ✅ **Background Modes** - Enabled

### 4. Provisioning Profile Güncelleme

APNs capability ekledikten sonra:
1. **Profiles** → Mevcut profilleri seçin
2. **Edit** → **Generate**
3. Yeni profilleri indirin
4. Xcode'da: **Preferences** → **Accounts** → **Download Manual Profiles**

---

## Kod Değişiklikleri (Zaten Yapıldı)

### AppDelegate.swift
- ✅ UNUserNotificationCenter delegate
- ✅ MessagingDelegate
- ✅ APNS token → FCM token aktarımı
- ✅ Ön plan bildirim gösterimi
- ✅ Arka plan bildirim işleme

### Info.plist
- ✅ UIBackgroundModes: remote-notification, fetch
- ✅ FirebaseAppDelegateProxyEnabled: false

### Entitlements
- ✅ Runner.entitlements (Debug)
- ✅ RunnerRelease.entitlements (Release/Profile)
- ✅ aps-environment: development/production

### Backend (helpers_UPDATED.php)
- ✅ APNS headers: apns-priority, apns-push-type
- ✅ APNS payload: alert, sound, badge, content-available, mutable-content
- ✅ fcm_options: image

---

## Test Etme

### Firebase Console'dan Test
1. Firebase Console → Cloud Messaging → **Send your first message**
2. Notification title ve text girin
3. **Send test message** → FCM Token girin
4. iOS cihazda bildirimi görmelisiniz

### Backend'den Test
Admin panelden bildirim gönderdiğinizde hem Android hem iOS'a gitmeli.

---

## Sorun Giderme

### Bildirim Gelmiyor
1. APNs Key Firebase'e yüklendi mi?
2. App ID'de Push Notifications enabled mı?
3. Provisioning Profile güncel mi?
4. Cihazda bildirim izni verildi mi?

### Token Alınamıyor
- Simülatörde push notification çalışmaz, gerçek cihaz gerekli
- Info.plist'te UIBackgroundModes doğru mu?

### Arka Planda Gelmiyor
- content-available: 1 olmalı
- Background Modes capability aktif olmalı
