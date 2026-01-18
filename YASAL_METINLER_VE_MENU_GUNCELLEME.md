# Yasal Metinler ve Menü Güncelleme

## 📋 Özet
Burger menüden "Bildirim Ayarları" ve "İlgi Alanları" kaldırıldı. Tüm yasal metinler (KVKK, Çerez Politikası, Hakkımızda, İletişim, vb.) tek bir dropdown başlık altında toplandı ve her biri ayrı sayfalara yönlendiriyor.

## ✅ Yapılan Değişiklikler

### 1. Yeni Yasal Sayfalar View'ı Oluşturuldu
**Dosya**: `lib/views/legal/legal_page_view.dart`

#### Özellikler:
- Dinamik içerik yükleme (slug bazlı)
- Modern ve temiz tasarım
- Loading state
- Error handling
- Scroll edilebilir içerik
- Son güncelleme tarihi gösterimi

#### Desteklenen Sayfalar:
1. **KVKK** (`kvkk`)
2. **Kişisel Verilerin Saklama ve İmha Etme** (`kisisel-verilerin-saklama-ve-imha-etme-proseduru`)
3. **Çerez Politikası** (`cerez-politikasi`)
4. **Hakkımızda** (`about-us`)
5. **İletişim** (`contact-us`)
6. **Şartlar & Koşullar** (`terms-condition`)
7. **Gizlilik Politikası** (`privacy-policy`)

### 2. Burger Menü Güncellendi
**Dosya**: `lib/widgets/shared_app_bar.dart`

#### Kaldırılan Öğeler:
- ❌ Bildirim Ayarları
- ❌ İlgi Alanları
- ❌ Eski dialog'lar (Hakkımızda, İletişim, Gizlilik Politikası)

#### Eklenen Öğeler:
- ✅ Yasal Metinler (Dropdown)
  - KVKK
  - Kişisel Verilerin Saklama ve İmha Etme
  - Çerez Politikası
  - Hakkımızda
  - İletişim
  - Şartlar & Koşullar
  - Gizlilik Politikası

#### Yeni Özellikler:
- **Dropdown Animasyonu**: Smooth açılma/kapanma
- **Alt Menü Tasarımı**: Gri arka plan, girintili
- **Chevron Animasyonu**: Açık/kapalı duruma göre döner
- **Scrollable**: Uzun menü için kaydırma desteği

### 3. MainMenuDrawer StatefulWidget'a Dönüştürüldü
- Dropdown state yönetimi için
- `_isLegalExpanded` state değişkeni eklendi
- `setState()` ile animasyonlu açılma/kapanma

## 🎨 Tasarım Detayları

### Burger Menü Yapısı
```
┌─────────────────────────────┐
│  👤 Kullanıcı Adı           │
│     email@example.com       │
├─────────────────────────────┤
│  👤 Profil               →  │
│  📰 Kaynak Seçimi        →  │
├─────────────────────────────┤
│  ⚖️ Yasal Metinler        ▼  │  ← Dropdown
│     • KVKK               →  │
│     • Kişisel Verilerin... →│
│     • Çerez Politikası   →  │
│     • Hakkımızda         →  │
│     • İletişim           →  │
│     • Şartlar & Koşullar →  │
│     • Gizlilik Politikası→  │
├─────────────────────────────┤
│  🚪 Çıkış Yap            →  │
└─────────────────────────────┘
```

### Yasal Sayfa Tasarımı
```
┌─────────────────────────────┐
│  ← Başlık                   │
├─────────────────────────────┤
│                             │
│  Başlık                     │
│  Son güncelleme: 18/01/2026 │
│                             │
│  İçerik metni...            │
│  Lorem ipsum dolor sit...   │
│                             │
│  1. Başlık                  │
│  İçerik...                  │
│                             │
│  2. Başlık                  │
│  İçerik...                  │
│                             │
└─────────────────────────────┘
```

## 📱 Kullanıcı Akışı

### Yasal Metinlere Erişim
1. Burger menüyü aç (☰)
2. "Yasal Metinler" başlığına tıkla
3. Dropdown açılır (animasyonlu)
4. İstediğin metni seç
5. Ayrı sayfada açılır
6. İçeriği oku
7. Geri dön (←)

### Dropdown Animasyonu
- **Kapalı**: Chevron aşağı (▼)
- **Açık**: Chevron yukarı (▲)
- **Geçiş**: 200ms smooth animasyon
- **Alt Menü**: Fade in/out efekti

## 🔧 Teknik Detaylar

### Yasal Sayfa Parametreleri
```dart
LegalPageView(
  title: 'KVKK',           // Sayfa başlığı
  slug: 'kvkk',            // İçerik slug'ı
)
```

### İçerik Yükleme
```dart
Future<String> _loadContent() async {
  await Future.delayed(const Duration(milliseconds: 500));
  
  switch (slug) {
    case 'kvkk':
      return _getKvkkContent();
    case 'cerez-politikasi':
      return _getCookiePolicyContent();
    // ...
  }
}
```

### Dropdown State Yönetimi
```dart
bool _isLegalExpanded = false;

setState(() {
  _isLegalExpanded = !_isLegalExpanded;
});
```

### Animasyonlar
```dart
// Chevron rotasyonu
AnimatedRotation(
  turns: isExpanded ? 0.5 : 0,
  duration: const Duration(milliseconds: 200),
)

// İçerik fade
AnimatedCrossFade(
  crossFadeState: isExpanded 
    ? CrossFadeState.showSecond 
    : CrossFadeState.showFirst,
  duration: const Duration(milliseconds: 200),
)
```

## 📄 İçerik Detayları

### 1. KVKK
- Veri sorumlusu bilgileri
- Kişisel verilerin işlenme amaçları
- İşlenen kişisel veriler
- Veri aktarımı
- Veri sahibinin hakları
- Başvuru yolları

### 2. Kişisel Verilerin Saklama ve İmha
- Amaç ve kapsam
- Saklama süreleri
- İmha yöntemleri
- Periyodik imha
- Olağanüstü imha
- Sorumluluklar

### 3. Çerez Politikası
- Çerez tanımı
- Kullanım amaçları
- Çerez türleri
- Üçüncü taraf çerezleri
- Çerez yönetimi
- Saklama süreleri

### 4. Hakkımızda
- Vizyon ve misyon
- Özellikler
- Değerler
- Ekip bilgileri
- İletişim bilgileri

### 5. İletişim
- Genel iletişim
- Adres bilgileri
- Teknik destek
- İş birliği
- Basın ve medya
- Sosyal medya

### 6. Şartlar & Koşullar
- Genel hükümler
- Hizmet tanımı
- Kullanıcı hesabı
- Kullanım kuralları
- İçerik ve telif hakları
- Sorumluluk sınırlamaları

### 7. Gizlilik Politikası
- Toplanan bilgiler
- Bilgilerin kullanımı
- Bilgi paylaşımı
- Veri güvenliği
- Veri saklama
- Kullanıcı hakları

## 🎯 Özellikler

### Burger Menü
- ✅ Dropdown animasyonu
- ✅ Smooth geçişler
- ✅ Scrollable içerik
- ✅ Modern tasarım
- ✅ Responsive

### Yasal Sayfalar
- ✅ Dinamik içerik
- ✅ Loading state
- ✅ Error handling
- ✅ Scroll edilebilir
- ✅ Temiz tipografi
- ✅ Tarih gösterimi

## 📊 Menü Karşılaştırması

### Eski Menü
```
- Profil
- Kaynak Seçimi
- İlgi Alanları ❌
- Bildirim Ayarları ❌
- Hakkımızda (Dialog) ❌
- İletişim (Dialog) ❌
- Gizlilik Politikası (Dialog) ❌
- Çıkış Yap
```

### Yeni Menü
```
- Profil
- Kaynak Seçimi
- Yasal Metinler (Dropdown) ✅
  - KVKK ✅
  - Kişisel Verilerin Saklama... ✅
  - Çerez Politikası ✅
  - Hakkımızda ✅
  - İletişim ✅
  - Şartlar & Koşullar ✅
  - Gizlilik Politikası ✅
- Çıkış Yap
```

## 🔄 Navigasyon Akışı

### Eski Akış
```
Menü → Hakkımızda → Dialog (Sınırlı içerik)
```

### Yeni Akış
```
Menü → Yasal Metinler → Dropdown → KVKK → Tam Sayfa (Detaylı içerik)
```

## 💡 Avantajlar

### Kullanıcı Deneyimi
- ✅ Daha organize menü
- ✅ Daha fazla içerik
- ✅ Daha iyi okunabilirlik
- ✅ Profesyonel görünüm

### Teknik
- ✅ Modüler yapı
- ✅ Kolay güncelleme
- ✅ Yeniden kullanılabilir
- ✅ Ölçeklenebilir

### Yasal Uyumluluk
- ✅ KVKK uyumlu
- ✅ Detaylı bilgilendirme
- ✅ Kolay erişim
- ✅ Güncellenebilir içerik

## 🎨 Stil Rehberi

### Renkler
- **Primary**: #F4220B (Kırmızı)
- **Text**: #212121 (Koyu Gri)
- **Secondary Text**: #757575 (Orta Gri)
- **Background**: #FFFFFF (Beyaz)
- **Dropdown BG**: #F5F5F5 (Açık Gri)

### Tipografi
- **Başlık**: 24px, Bold
- **Alt Başlık**: 18px, SemiBold
- **İçerik**: 15px, Regular
- **Tarih**: 13px, Regular
- **Menü**: 14-16px, Medium

### Spacing
- **Padding**: 20px
- **Item Spacing**: 16px
- **Section Spacing**: 24px

## 📝 Notlar

### İçerik Güncelleme
İçerikleri güncellemek için `lib/views/legal/legal_page_view.dart` dosyasındaki ilgili `_get...Content()` metodunu düzenleyin.

### Yeni Sayfa Ekleme
1. `_loadContent()` metoduna yeni case ekle
2. İçerik metodu oluştur (`_getYeniSayfaContent()`)
3. Menüye yeni item ekle
4. `LegalPageView` ile yönlendir

### Animasyon Süresi
Tüm animasyonlar 200ms olarak ayarlanmıştır. Değiştirmek için `Duration(milliseconds: 200)` değerini güncelleyin.

## 🔍 Test Senaryoları

### Dropdown Testi
- [ ] Yasal Metinler'e tıkla
- [ ] Dropdown açılıyor mu?
- [ ] Chevron dönüyor mu?
- [ ] Animasyon smooth mu?
- [ ] Tekrar tıklayınca kapanıyor mu?

### Sayfa Navigasyonu
- [ ] Her bir yasal metne tıkla
- [ ] Sayfa açılıyor mu?
- [ ] İçerik yükleniyor mu?
- [ ] Geri butonu çalışıyor mu?
- [ ] Scroll edilebiliyor mu?

### Loading State
- [ ] Sayfa açılırken loading gösteriliyor mu?
- [ ] 500ms sonra içerik görünüyor mu?

### Error Handling
- [ ] Geçersiz slug ile test et
- [ ] Error mesajı gösteriliyor mu?

## ✨ Gelecek Geliştirmeler (Opsiyonel)

- [ ] İçerikleri backend'den çek
- [ ] Çoklu dil desteği
- [ ] Arama özelliği
- [ ] Favorilere ekleme
- [ ] Paylaşma özelliği
- [ ] PDF export
- [ ] Versiyon geçmişi

## 🎯 Sonuç

Burger menü daha organize ve profesyonel hale geldi. Tüm yasal metinler tek bir dropdown altında toplandı ve her biri detaylı içerikle ayrı sayfalarda gösteriliyor. Kullanıcı deneyimi ve yasal uyumluluk iyileştirildi.
