# Şehirler Alfabetik Sıralama Güncelleme

## 📋 Özet
Yerel haberler sayfasındaki şehirler artık plaka koduna göre değil, alfabetik sıraya göre listeleniyor. A'dan Z'ye doğru sıralı 81 il.

## ✅ Yapılan Değişiklikler

### 1. `city_data.dart` Güncellendi
**Dosya**: `lib/utils/city_data.dart`

#### Önceki Durum:
- Şehirler plaka koduna göre sıralıydı (01-81)
- Plaka kodu yoktu, index'ten hesaplanıyordu

#### Yeni Durum:
- ✅ Şehirler alfabetik sıraya göre (A-Z)
- ✅ Her şehirde `plateCode` alanı eklendi
- ✅ 81 il tam liste

#### Örnek Veri Yapısı:
```dart
{
  "name": "Adana",
  "plateCode": "01",
  "rss": "https://www.hurriyet.com.tr/rss/yerel-haberler/adana",
}
```

### 2. `local_view.dart` Güncellendi
**Dosya**: `lib/views/local/local_view.dart`

#### Değişiklik:
```dart
// ÖNCE
final plateCode = (index + 1).toString().padLeft(2, '0');

// SONRA
final plateCode = city['plateCode'] ?? '';
```

#### Açıklama:
- Plaka kodu artık index'ten hesaplanmıyor
- Doğrudan `city_data.dart`'tan alınıyor
- Alfabetik sıralama ile plaka kodu uyumsuzluğu çözüldü

### 3. `city_selection_view.dart` Güncellendi
**Dosya**: `lib/views/city_selection_view.dart`

#### Önceki Durum:
- Şehirler `List<String>` olarak tutuluyordu
- Plaka kodları ayrı bir map'te tutuluyordu
- Plaka koduna göre sıralıydı

#### Yeni Durum:
- ✅ Şehirler `List<Map<String, dynamic>>` olarak tutuluyordu
- ✅ `CityData.cities` kullanılıyor
- ✅ Alfabetik sıralı
- ✅ Plaka kodu her şehirle birlikte geliyor
- ✅ `_getCityPlateCode()` metodu kaldırıldı

## 📊 Alfabetik Sıralama

### Şehir Listesi (A-Z)
```
A: Adana, Adıyaman, Afyonkarahisar, Ağrı, Aksaray, Amasya, Ankara, Antalya, Ardahan, Artvin, Aydın
B: Balıkesir, Bartın, Batman, Bayburt, Bilecik, Bingöl, Bitlis, Bolu, Burdur, Bursa
Ç: Çanakkale, Çankırı, Çorum
D: Denizli, Diyarbakır, Düzce
E: Edirne, Elazığ, Erzincan, Erzurum, Eskişehir
G: Gaziantep, Giresun, Gümüşhane
H: Hakkari, Hatay
I: Iğdır, Isparta
İ: İstanbul, İzmir
K: Kahramanmaraş, Karabük, Karaman, Kars, Kastamonu, Kayseri, Kilis, Kırıkkale, Kırklareli, Kırşehir, Kocaeli, Konya, Kütahya
M: Malatya, Manisa, Mardin, Mersin, Muğla, Muş
N: Nevşehir, Niğde
O: Ordu, Osmaniye
R: Rize
S: Sakarya, Samsun, Siirt, Sinop, Sivas
Ş: Şanlıurfa, Şırnak
T: Tekirdağ, Tokat, Trabzon, Tunceli
U: Uşak
V: Van
Y: Yalova, Yozgat
Z: Zonguldak
```

## 🎯 Özellikler

### Yerel Haberler Sayfası
- ✅ Şehirler alfabetik sıralı
- ✅ Yatay kaydırılabilir
- ✅ Plaka kodu + şehir adı gösterimi
- ✅ Seçili şehir vurgulanıyor
- ✅ 81 il tam liste

### Şehir Seçim Sayfası
- ✅ Şehirler alfabetik sıralı
- ✅ Arama özelliği
- ✅ Plaka kodu badge'i
- ✅ Seçim göstergesi
- ✅ 81 il tam liste

## 📱 Kullanıcı Deneyimi

### Önceki Durum
```
Yerel Haberler:
01 Adana → 02 Adıyaman → 03 Afyon → ... → 81 Düzce
(Plaka koduna göre)
```

### Yeni Durum
```
Yerel Haberler:
01 Adana → 02 Adıyaman → 03 Afyon → 04 Ağrı → 68 Aksaray → ...
(Alfabetik sıralı, plaka kodu gösteriliyor)
```

## 🔧 Teknik Detaylar

### Veri Yapısı
```dart
class CityData {
  static final List<Map<String, dynamic>> cities = [
    {
      "name": "Adana",
      "plateCode": "01",
      "rss": "https://www.hurriyet.com.tr/rss/yerel-haberler/adana",
    },
    // ... 81 şehir
  ];
}
```

### Kullanım (Local View)
```dart
final city = controller.cityList[index];
final cityName = city['name'] ?? '';
final plateCode = city['plateCode'] ?? '';
```

### Kullanım (City Selection)
```dart
final _cities = CityData.cities;

final city = _filteredCities[index];
final cityName = city['name'] ?? '';
final plateCode = city['plateCode'] ?? '';
```

## 🎨 UI Görünümü

### Yerel Haberler - Şehir Seçici
```
┌─────────────────────────────────────────┐
│ [01 Adana] [02 Adıyaman] [03 Afyon]... │
│                                         │
│ ← Yatay Kaydırılabilir →                │
└─────────────────────────────────────────┘
```

### Şehir Seçim Sayfası
```
┌─────────────────────────────┐
│  Şehrinizi seçin.           │
│                             │
│  [🔍 Şehir ara]             │
│                             │
│  ┌─────────────────────┐   │
│  │ [01] Adana       ✓  │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ [02] Adıyaman       │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ [03] Afyonkarahisar │   │
│  └─────────────────────┘   │
│  ...                        │
└─────────────────────────────┘
```

## 📊 Karşılaştırma

### Plaka Koduna Göre (Eski)
| Sıra | Plaka | Şehir |
|------|-------|-------|
| 1 | 01 | Adana |
| 2 | 02 | Adıyaman |
| 3 | 03 | Afyonkarahisar |
| ... | ... | ... |
| 81 | 81 | Düzce |

### Alfabetik Sıraya Göre (Yeni)
| Sıra | Plaka | Şehir |
|------|-------|-------|
| 1 | 01 | Adana |
| 2 | 02 | Adıyaman |
| 3 | 03 | Afyonkarahisar |
| 4 | 04 | Ağrı |
| 5 | 68 | Aksaray |
| 6 | 05 | Amasya |
| ... | ... | ... |
| 81 | 67 | Zonguldak |

## 💡 Avantajlar

### Kullanıcı Açısından
- ✅ Daha kolay bulma (alfabetik)
- ✅ Tahmin edilebilir sıralama
- ✅ Plaka kodu hala görünüyor
- ✅ Arama ile hızlı erişim

### Geliştirici Açısından
- ✅ Tek veri kaynağı (`CityData`)
- ✅ Tutarlı veri yapısı
- ✅ Kolay bakım
- ✅ Plaka kodu hesaplama yok

## 🔍 Arama Özelliği

### Şehir Seçim Sayfasında
```dart
List<Map<String, dynamic>> get _filteredCities {
  if (_searchQuery.isEmpty) return _cities;
  return _cities
      .where(
        (city) => city['name']!
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()),
      )
      .toList();
}
```

### Örnek Aramalar:
- "ank" → Ankara, Çankırı
- "ist" → İstanbul
- "bursa" → Bursa
- "a" → Adana, Adıyaman, Afyon, Ağrı, Aksaray, Amasya, Ankara, Antalya, Ardahan, Artvin, Aydın

## 📝 Notlar

### Önemli
- Şehirler artık alfabetik sıralı
- Plaka kodları korundu
- Tüm 81 il mevcut
- RSS linkleri değişmedi

### Dikkat Edilmesi Gerekenler
- `CityData.cities` kullanılmalı
- Plaka kodu `city['plateCode']` ile alınmalı
- Index'ten plaka kodu hesaplama yapılmamalı

## 🎯 Sonuç

Şehirler artık alfabetik sıraya göre listeleniyor. Kullanıcılar şehirlerini daha kolay bulabilecek. Plaka kodları hala gösteriliyor ve doğru şekilde eşleşiyor.

### Alfabetik Sıralama Avantajları:
1. **Kolay Bulma**: A'dan Z'ye sıralı
2. **Tahmin Edilebilir**: Kullanıcılar nerede olduğunu bilir
3. **Evrensel**: Tüm dillerde geçerli
4. **Arama Dostu**: Arama sonuçları mantıklı

### Plaka Kodu Korundu:
- Görsel olarak hala gösteriliyor
- Bilgi kaybı yok
- Eski kullanıcılar alışık

Artık hem alfabetik sıralama hem de plaka kodu bilgisi bir arada! 🎉
