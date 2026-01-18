# 🚀 Hızlı Başlangıç Kılavuzu

## 📋 Ön Gereksinimler

### Kurulu Olması Gerekenler:
- ✅ Flutter SDK (3.38.6+)
- ✅ Dart SDK
- ✅ Android Studio / VS Code
- ✅ Git

### Kontrol:
```bash
flutter doctor
```

Tüm checkmark'lar yeşil olmalı! ✅

---

## 🔧 Kurulum Adımları

### 1. Bağımlılıkları Yükle
```bash
flutter pub get
```

### 2. Firebase Yapılandırması
Aşağıdaki dosyaların mevcut olduğundan emin olun:
- ✅ `android/app/google-services.json`
- ✅ `ios/Runner/GoogleService-Info.plist`
- ✅ `lib/firebase_options.dart`

### 3. Uygulamayı Çalıştır

#### Android:
```bash
flutter run
```

#### iOS:
```bash
flutter run -d ios
```

#### Web:
```bash
flutter run -d chrome
```

#### Windows:
```bash
flutter run -d windows
```

---

## 🎯 İlk Kullanım

### 1. Uygulama Açılır
- Splash screen gösterilir
- Firebase bağlantısı kurulur

### 2. Onboarding
- Uygulama tanıtımı
- Swipe ile ilerle

### 3. Giriş Yap
Seçenekler:
- 📧 Email/Şifre
- 🔵 Google ile Giriş
- 🍎 Apple ile Giriş

### 4. Kaynak Seçimi
- İlgi alanlarına göre haber kaynakları seç
- En az 1 kaynak seçilmeli
- "Kaydet" butonuna tıkla

### 5. Ana Sayfa
- Haberler yüklenir
- Carousel'de popüler haberler
- Aşağıda haber listesi

---

## 🎨 Özellikler

### Ana Sayfa (Home)
- **Popüler Haberler**: Carousel formatında
- **Haber Listesi**: Scroll ile daha fazla
- **Arama**: 🔍 butonuna tıkla
- **Canlı Yayın**: 📹 butonuna tıkla
- **Bildirimler**: 🔔 butonuna tıkla

### Arama
1. 🔍 butonuna tıkla
2. Kelime yaz
3. Anlık sonuçlar gösterilir
4. Habere tıkla → Detay sayfası

### Haber Detayı
- Kapak resmi
- Başlık ve kategori
- Kaynak bilgisi
- Tarih (göreceli)
- İçerik
- **"Devamını Gör"** butonu → Orijinal kaynak

### Yerel Haberler (Local)
1. Şehir seç
2. Yerel haberler gösterilir

### Takip (Follow)
- Takip edilen kaynakların haberleri
- Özel haber akışı

### Kaydedilenler (Saved)
- Bookmark edilen haberler
- Silme özelliği

### Profil
- Kullanıcı bilgileri
- Profil düzenleme
- **Hesap Silme** (App Store uyumlu)

---

## 🔍 Arama Özelliği

### Nasıl Kullanılır?
1. Ana sayfada 🔍 butonuna tıkla
2. Arama bar açılır
3. Kelime veya cümle yaz
4. Anlık sonuçlar gösterilir

### Arama Tipleri:
- **Tek Kelime**: "ekonomi"
- **Çoklu Kelime**: "dolar kur"
- **Kaynak**: "BBC"
- **Kategori**: "spor"
- **Fuzzy**: "ekonom" → "ekonomi", "ekonomik"

### Skorlama:
- Başlıkta eşleşme: En yüksek skor
- Açıklamada eşleşme: Orta skor
- Kaynak/Kategori: Düşük skor

---

## 📱 Navigasyon

### Bottom Navigation (5 Tab):
1. **🏠 Ana Sayfa**: Tüm haberler
2. **📍 Yerel**: Şehir bazlı haberler
3. **➕ Ekle**: Haber kaynağı ekle
4. **👥 Takip**: Takip edilen kaynaklar
5. **🔖 Kaydedilenler**: Bookmark'lar

### Drawer Menu:
- Profil
- Ayarlar
- Bildirim Ayarları
- Hakkında
- Çıkış Yap

---

## 🔔 Bildirimler

### Bildirim Ayarları:
1. Drawer → Bildirim Ayarları
2. Kategori bazlı açma/kapama
3. Kaydet

### Bildirim Türleri:
- Yeni haberler
- Popüler haberler
- Takip edilen kaynaklardan haberler

---

## 🔒 Hesap Silme

### Nasıl Silinir?
1. Profil sayfasına git
2. En alta scroll et
3. "Hesabımı Sil" butonuna tıkla
4. Onay dialogu açılır
5. "Evet" butonuna tıkla
6. Hesap silinir
7. Login sayfasına yönlendirilir

### Ne Silinir?
- ✅ Kullanıcı hesabı (soft delete)
- ✅ Firestore verileri
- ✅ Local storage verileri
- ✅ Oturum bilgileri

---

## 🎯 Haber Kaynakları

### Mevcut Kaynaklar:
- **Gündem**: Hürriyet, Sözcü, Milliyet, vb.
- **Ekonomi**: Bloomberg, Dünya, Para, vb.
- **Spor**: Fanatik, Fotomaç, Sporx, vb.
- **Teknoloji**: Webrazzi, ShiftDelete, vb.
- **Dünya**: BBC, CNN, Reuters, vb.

### Kaynak Ekleme:
1. Bottom Navigation → ➕ Ekle
2. Kategori seç
3. Kaynakları seç
4. Kaydet

---

## 🐛 Sorun Giderme

### Hata: "Haber bulunamadı"
**Çözüm:**
1. Kaynak seçimi yaptığınızdan emin olun
2. İnternet bağlantınızı kontrol edin
3. Uygulamayı yeniden başlatın

### Hata: "Firebase bağlantı hatası"
**Çözüm:**
1. `google-services.json` dosyasını kontrol edin
2. Firebase Console'da proje ayarlarını kontrol edin
3. İnternet bağlantınızı kontrol edin

### Hata: "Arama çalışmıyor"
**Çözüm:**
1. Önce haberler yüklensin
2. Sonra arama yapın
3. En az 3 karakter yazın

### Hata: "Profil kaydedilmiyor"
**Çözüm:**
1. Tüm alanları doldurun
2. İnternet bağlantınızı kontrol edin
3. Tekrar deneyin

---

## 📊 Performans İpuçları

### Hızlı Kullanım:
- ✅ Pull-to-refresh ile haberleri yenile
- ✅ Arama yerine kategori filtrele
- ✅ Gereksiz kaynakları kaldır
- ✅ Cache'i temizle (ayarlar)

### Pil Tasarrufu:
- ✅ Bildirimleri kapat
- ✅ Otomatik yenilemeyi kapat
- ✅ Dark mode kullan (gelecek)

---

## 🔐 Güvenlik İpuçları

### Hesap Güvenliği:
- ✅ Güçlü şifre kullan
- ✅ 2FA aktif et (gelecek)
- ✅ Düzenli şifre değiştir

### Gizlilik:
- ✅ Gereksiz izinleri kapat
- ✅ Konum paylaşımını kapat
- ✅ Bildirim izinlerini kontrol et

---

## 📞 Destek

### Dokümantasyon:
- `README.md` - Genel bilgiler
- `PROJE_DURUMU.md` - Proje durumu
- `ARAMA_VE_PROFIL_GUNCELLEME.md` - Arama özelliği
- `DEVAMINI_GOR_BUTONU.md` - Devamını gör butonu
- `HABER_KAYNAGI_EKLEME.md` - Kaynak gösterimi
- `HESAP_SILME_OZELLIGI_KURULUM.md` - Hesap silme

### Backend:
- `BACKEND_DELETE_USER_FUNCTION.php` - Backend kodu
- `BACKEND_KURULUM_ADIMLAR.md` - Backend kurulum

---

## 🎉 Başarılar!

Artık uygulamayı kullanmaya hazırsınız! 🚀

### Önemli Notlar:
- ✅ İlk açılışta kaynak seçimi yapın
- ✅ Bildirimlere izin verin
- ✅ Profil bilgilerinizi tamamlayın
- ✅ Haberleri kaydedin ve paylaşın

**İyi haberler!** 📰

---

**Hazırlayan:** Kiro AI Assistant  
**Tarih:** 17 Ocak 2026  
**Versiyon:** 1.0  
**Durum:** ✅ Kullanıma Hazır
