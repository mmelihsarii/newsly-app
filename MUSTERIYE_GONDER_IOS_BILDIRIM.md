# iOS Bildirim Kurulumu - Müşteriden İstenenler



Hocam iOS cihazlara bildirim gönderilebilmesi için Apple Developer hesabınızdan bazı bilgilere ihtiyacım var. Aşağıdaki adımları takip edip bana göndermeniz yeterli.

---

## 1. APNs Key Oluşturma (.p8 dosyası)

1. https://developer.apple.com/account adresine giriş yapın
2. Sol menüden **"Certificates, Identifiers & Profiles"** tıklayın
3. Sol menüden **"Keys"** tıklayın
4. Sağ üstteki **"+"** (artı) butonuna tıklayın
5. **Key Name** kısmına: `Newsly Push Key` yazın
6. **"Apple Push Notifications service (APNs)"** kutusunu işaretleyin ✅
7. **"Continue"** butonuna tıklayın
8. **"Register"** butonuna tıklayın
9. **"Download"** butonuna tıklayarak .p8 dosyasını indirin
   - ⚠️ **ÖNEMLİ:** Bu dosya sadece 1 kez indirilebilir! Kaybetmeyin!
10. Aynı sayfada görünen **"Key ID"** değerini not alın (10 karakterlik kod, örn: ABC123XYZ0)

---

## 2. Team ID Bulma

1. https://developer.apple.com/account adresinde
2. Sol menüden **"Membership"** veya **"Membership details"** tıklayın
3. **"Team ID"** değerini not alın (10 karakterlik kod, örn: 9ABC12DEF3)

---

## 3. App ID'de Push Notifications Aktifleştirme

1. https://developer.apple.com/account → **"Certificates, Identifiers & Profiles"**
2. Sol menüden **"Identifiers"** tıklayın
3. Listeden **"com.newsly.haber"** App ID'sini bulun ve tıklayın
   - (Eğer yoksa yeni oluşturmanız gerekebilir)
4. Aşağı kaydırın, **"Capabilities"** bölümünde:
   - **"Push Notifications"** yanındaki kutucuğu işaretleyin ✅
5. Sağ üstten **"Save"** butonuna tıklayın

---

## Bana Göndermeniz Gerekenler

| # | Ne | Örnek |
|---|---|---|
| 1 | **.p8 dosyası** | AuthKey_ABC123XYZ0.p8 |
| 2 | **Key ID** | ABC123XYZ0 |
| 3 | **Team ID** | 9ABC12DEF3 |

Bu 3 bilgiyi bana gönderdikten sonra Firebase'e ekleyip iOS bildirimlerini aktif edeceğim.

---

## Ekran Görüntüleri (Yardımcı)

### Keys Sayfası:
```
developer.apple.com/account/resources/authkeys/list
```

### Membership Sayfası (Team ID için):
```
developer.apple.com/account → Membership
```

---

Herhangi bir sorun olursa yazabilirsiniz hocam

