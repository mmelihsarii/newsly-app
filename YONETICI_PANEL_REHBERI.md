# 🛠️ Newsly - Yönetici Panel Rehberi

Bu rehber, Laravel admin panelini kullanan yöneticiler için hazırlanmıştır.

---

## 📋 Günlük Kontroller

Her gün yapılması gereken kontroller:

### 1. RSS Kaynaklarını Kontrol Et
**Panel → RSS Akışları**

- Tüm kaynakların "Aktif" durumda olduğunu kontrol edin
- Kırmızı "Deaktif" olanları inceleyin
- Hatalı URL'leri düzeltin

### 2. Haberleri Kontrol Et
**Panel → Haberler**

- Son 24 saatte haber gelip gelmediğini kontrol edin
- Boş veya bozuk haberler varsa silin

### 3. Kullanıcı Şikayetlerini İncele
- E-posta veya uygulama içi geri bildirimleri kontrol edin

---

## ➕ Yeni Haber Kaynağı Ekleme

### Adım Adım:

1. **Panel → RSS Akışları → Oluştur**

2. **Formu doldurun:**
   - **Dil:** Turkish
   - **Kategori:** Uygun kategoriyi seçin (Gündem, Ekonomi, Spor vs.)
   - **Feed Name:** Kaynak adı (örn: "CNN Türk")
   - **Feed URL:** RSS adresi (örn: https://www.cnnturk.com/rss)

3. **Gönder** butonuna tıklayın

4. **Kontrol:** 
   - Firebase Console → Firestore → news_sources
   - Yeni kaynak orada görünmeli

### ⚠️ Dikkat:
- RSS URL'sinin çalıştığından emin olun
- Tarayıcıda URL'yi açarak test edin
- XML formatında veri gelmeli

---

## 🔧 Sık Karşılaşılan Sorunlar ve Çözümleri

### Sorun 1: RSS Eklenmiyor / Sayfa Donuyor

**Belirtiler:**
- Gönder butonuna basınca sayfa donuyor
- Uzun süre yükleniyor

**Çözüm:**
1. Sayfayı yenileyin
2. Tekrar deneyin
3. Hala olmuyorsa: Sunucu loglarını kontrol edin

---

### Sorun 2: Haberler Uygulamada Görünmüyor

**Kontrol Listesi:**

1. **RSS kaynağı aktif mi?**
   - Panel → RSS Akışları
   - Kaynağın yanında yeşil "Aktif" yazmalı

2. **RSS URL çalışıyor mu?**
   - URL'yi tarayıcıda açın
   - XML verisi gelmeli

3. **Firebase'de kaynak var mı?**
   - Firebase Console → Firestore → news_sources
   - Kaynak orada olmalı

4. **Kategori doğru mu?**
   - Kaynak kategorisi uygulamadaki kategoriyle eşleşmeli

---

### Sorun 3: Türkçe Karakterler Bozuk Görünüyor

**Belirtiler:**
- "Gündem" yerine "GÃ¼ndem" görünüyor
- Ş, İ, Ğ, Ü harfleri bozuk

**Çözüm:**
Bu sorun otomatik düzeltilmeli. Düzelmiyorsa:
1. Kaynağı silin
2. Yeniden ekleyin

---

### Sorun 4: Bildirimler Gitmiyor

**Kontrol Listesi:**

1. **Firebase Cloud Messaging aktif mi?**
   - Firebase Console → Cloud Messaging

2. **Bildirim gönderme:**
   - Panel → Bildirimler → Yeni Bildirim
   - Başlık ve mesaj girin
   - Gönder

---

## 🗑️ Kaynak Silme

### Adımlar:
1. Panel → RSS Akışları
2. Silmek istediğiniz kaynağı bulun
3. Sağdaki üç nokta menüsüne tıklayın
4. "Sil" seçin
5. Onaylayın

**Not:** Silinen kaynak Firebase'den de otomatik silinir.

---

## 📊 Firebase Console Kullanımı

### Giriş:
1. https://console.firebase.google.com adresine gidin
2. Google hesabınızla giriş yapın
3. "newsly-70ef9" projesini seçin

### Firestore (Veritabanı):
- Sol menü → Firestore Database
- **news_sources:** Haber kaynakları
- **users:** Kullanıcılar

### Analytics (İstatistikler):
- Sol menü → Analytics
- Kullanıcı sayısı, en çok okunan haberler vs.

### Cloud Messaging (Bildirimler):
- Sol menü → Cloud Messaging
- Toplu bildirim gönderme

---

## 🆘 Acil Durumlar

### Uygulama Tamamen Çalışmıyor

1. **Firebase durumunu kontrol edin:**
   - https://status.firebase.google.com

2. **Sunucu durumunu kontrol edin:**
   - Hosting sağlayıcınızın panelini kontrol edin

3. **Geliştiriciyle iletişime geçin**

---

### Tüm Haberler Kayboldu

1. **Panik yapmayın** - Muhtemelen geçici bir sorun

2. **Kontrol edin:**
   - Firebase Console → Firestore → news_sources
   - Kaynaklar orada mı?

3. **RSS'leri yeniden çalıştırın:**
   - Panel → RSS Akışları
   - Tüm kaynakların aktif olduğunu kontrol edin

---

## 📞 Teknik Destek

Çözemediğiniz sorunlar için:

1. **Sorunu detaylı açıklayın:**
   - Ne yapmaya çalıştınız?
   - Ne oldu?
   - Ekran görüntüsü alın

2. **Geliştiriciyle paylaşın**

---

## ✅ Haftalık Bakım Kontrol Listesi

Her hafta yapılması gerekenler:

- [ ] Tüm RSS kaynaklarının aktif olduğunu kontrol et
- [ ] Son 7 günde haber gelmeyen kaynakları incele
- [ ] Firebase Analytics'ten kullanıcı istatistiklerini kontrol et
- [ ] Kullanıcı geri bildirimlerini incele
- [ ] Disk alanı ve sunucu durumunu kontrol et

---

## 📝 Notlar

- **Değişiklikler anında yansır:** RSS eklediğinizde veya sildiğinizde uygulama otomatik güncellenir
- **Yedekleme:** Firebase otomatik yedekleme yapar
- **Güvenlik:** Admin panel şifrenizi kimseyle paylaşmayın

---

**Sorularınız için geliştiriciyle iletişime geçin.**
