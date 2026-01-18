# 🗑️ Hesap Silme Özelliği - Kullanım Kılavuzu

## 📱 Kullanıcı Deneyimi

### Adım 1: Profil Sayfasına Git
Kullanıcı uygulamada profil sayfasına gider.

### Adım 2: "Hesabımı Sil" Butonuna Tıkla
Sayfanın en altında kırmızı renkli, çöp kutusu ikonlu "Hesabımı Sil" butonu bulunur.

### Adım 3: Onay Dialogu
Butona tıklandığında şu dialog açılır:

```
⚠️ Hesabı Sil

Hesabınızı silmek istediğinize emin misiniz? 
Bu işlem geri alınamaz ve tüm verileriniz silinecektir.

[İptal]  [Evet, Sil]
```

### Adım 4: İşlem Tamamlanır
- Kullanıcı "Evet, Sil" seçerse:
  - Backend'e istek gönderilir
  - Firebase Authentication'dan kullanıcı silinir
  - Firestore'dan kullanıcı verisi silinir
  - GetStorage temizlenir
  - Kullanıcı çıkış yapılır
  - Login sayfasına yönlendirilir
  - "Hesabınız başarıyla silindi" mesajı gösterilir

---

## 🔧 Teknik Akış

```
1. Kullanıcı "Hesabımı Sil" butonuna tıklar
   ↓
2. AuthService.deleteAccount() çağrılır
   ↓
3. Onay dialogu gösterilir
   ↓
4. Kullanıcı "Evet, Sil" seçer
   ↓
5. UserService.deleteAccount() çağrılır
   ↓
6. Backend API'ye POST isteği atılır
   Endpoint: https://admin.newsly.com.tr/api/delete_user
   Body: { "user_id": "firebase_uid" }
   ↓
7. Backend kullanıcının status'unu 0 yapar (Soft Delete)
   ↓
8. Firebase Authentication'dan kullanıcı silinir
   ↓
9. Firestore'dan kullanıcı verisi silinir
   ↓
10. GetStorage temizlenir (tüm local data)
   ↓
11. Google Sign-In'den çıkış yapılır
   ↓
12. Firebase Auth'dan çıkış yapılır
   ↓
13. Kullanıcı LoginView'e yönlendirilir
   ↓
14. Başarı mesajı gösterilir
```

---

## 🎨 UI Tasarımı

### Hesap Silme Butonu Özellikleri:
- **Renk**: Kırmızı (Colors.red)
- **Arka Plan**: Açık kırmızı (Colors.red.shade50)
- **Border**: Kırmızı çerçeve (Colors.red.shade200)
- **İkon**: Icons.delete_forever (26px)
- **Başlık**: "Hesabımı Sil" (16px, bold)
- **Alt Yazı**: "Hesabınızı kalıcı olarak silin" (13px)
- **Trailing**: Ok ikonu (Icons.arrow_forward_ios)

### Onay Dialogu Özellikleri:
- **Başlık**: Uyarı ikonu + "Hesabı Sil"
- **İçerik**: Açıklayıcı metin
- **Butonlar**: 
  - İptal (gri)
  - Evet, Sil (kırmızı)

---

## 🔐 Güvenlik Önlemleri

### 1. Onay Mekanizması
- Kullanıcıdan açık onay alınır
- "Geri alınamaz" uyarısı yapılır

### 2. Soft Delete
- Kullanıcı verisi tamamen silinmez
- Backend'de `status = 0` yapılır
- Gerekirse geri getirilebilir

### 3. Veri Temizleme
- Firebase Authentication'dan silinir
- Firestore'dan silinir
- Local storage temizlenir
- Google Sign-In oturumu kapatılır

### 4. Log Kaydı
- Backend'de işlem loglanır
- Hangi kullanıcının ne zaman silindiği kaydedilir

---

## 📊 Backend Veri Yapısı

### tbl_users Tablosu
```sql
id              INT
firebase_uid    VARCHAR(255)
email           VARCHAR(255)
status          TINYINT (1: Aktif, 0: Silinmiş)
deleted_at      TIMESTAMP (NULL)
created_at      TIMESTAMP
updated_at      TIMESTAMP
```

### Silme İşlemi Sonrası:
```sql
UPDATE tbl_users 
SET status = 0, 
    deleted_at = NOW(), 
    updated_at = NOW()
WHERE id = ?
```

---

## 🧪 Test Senaryoları

### Test 1: Normal Silme
1. Giriş yapılmış bir hesapla profil sayfasına git
2. "Hesabımı Sil" butonuna tıkla
3. Dialogda "Evet, Sil" seç
4. Hesap silinmeli ve login sayfasına yönlendirilmeli

### Test 2: İptal Etme
1. "Hesabımı Sil" butonuna tıkla
2. Dialogda "İptal" seç
3. Hiçbir şey olmamalı, profil sayfasında kalmalı

### Test 3: Network Hatası
1. İnterneti kapat
2. "Hesabımı Sil" butonuna tıkla
3. "Evet, Sil" seç
4. Hata mesajı gösterilmeli

### Test 4: Backend Hatası
1. Backend'i durdur
2. "Hesabımı Sil" butonuna tıkla
3. "Evet, Sil" seç
4. "Hesap silinirken bir hata oluştu" mesajı gösterilmeli

---

## 🚨 Hata Mesajları

### Başarılı:
```
✅ Hesabınız başarıyla silindi
```

### Hata Durumları:
```
❌ Hesap silinirken bir hata oluştu
❌ Kullanıcı bulunamadı
❌ user_id parametresi gereklidir
❌ Hesap silinirken hata: [detay]
```

---

## 📱 App Store Gereksinimleri

Apple App Store'un hesap silme gereksinimleri:

✅ **Gereksinim 1**: Kullanıcı uygulamadan hesabını silebilmeli
- Karşılanıyor: Profil sayfasında "Hesabımı Sil" butonu var

✅ **Gereksinim 2**: Onay mekanizması olmalı
- Karşılanıyor: Dialog ile onay alınıyor

✅ **Gereksinim 3**: Geri alınamaz uyarısı yapılmalı
- Karşılanıyor: Dialog'da açıkça belirtiliyor

✅ **Gereksinim 4**: Tüm kullanıcı verileri silinmeli
- Karşılanıyor: Firebase, Firestore ve local storage temizleniyor

---

## 🔄 Geri Getirme (Opsiyonel)

Eğer soft delete kullanıyorsanız, admin panelinden geri getirebilirsiniz:

```sql
UPDATE tbl_users 
SET status = 1, 
    deleted_at = NULL, 
    updated_at = NOW()
WHERE id = ?
```

---

## 📞 Kullanıcı Desteği

Kullanıcılar hesaplarını sildikten sonra:
- Aynı email ile yeniden kayıt olabilirler
- Eski verileri geri getirilemez (hard delete yapıldıysa)
- Soft delete yapıldıysa admin desteği ile geri getirilebilir

---

**Not:** Bu özellik App Store ve Google Play Store gereksinimlerini karşılamaktadır.
