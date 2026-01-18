# Dark Mode Özelliği

## 📋 Özet
Uygulama artık Dark Mode (Karanlık Mod) desteğine sahip. Kullanıcılar profil sayfasından tema tercihlerini değiştirebilir. Ayar hem local storage'da hem de Firestore'da saklanır.

## ✅ Yapılan Değişiklikler

### 1. Yeni Controller Oluşturuldu
**Dosya**: `lib/controllers/theme_controller.dart`

#### Özellikler:
- **Theme Management**: Light ve Dark theme yönetimi
- **Local Storage**: GetStorage ile local kayıt
- **Firestore Sync**: Kullanıcı ayarlarını Firestore'da sakla
- **Auto Load**: Uygulama açılışında tema yükle
- **Reactive**: GetX ile reaktif tema değişimi

#### Metodlar:
- `loadThemeMode()`: Tema modunu yükle
- `toggleTheme()`: Tema modunu değiştir
- `lightTheme`: Light theme tanımı
- `darkTheme`: Dark theme tanımı

### 2. UserService Güncellendi
**Dosya**: `lib/services/user_service.dart`

#### Yeni Metod:
```dart
Future<bool> saveDarkModeSetting(bool isDarkMode)
```

#### Açıklama:
- Firestore'a `isDarkMode` alanını kaydeder
- Kullanıcı ayarlarını senkronize eder

### 3. Main.dart Güncellendi
**Dosya**: `lib/main.dart`

#### Değişiklikler:
- `ThemeController` import edildi
- Dependency injection'a eklendi
- `GetMaterialApp` Obx ile sarıldı
- `theme`, `darkTheme`, `themeMode` parametreleri eklendi

### 4. Profil Sayfası Güncellendi
**Dosya**: `lib/views/profile/profile_view.dart`

#### Yeni Widget:
- `_buildDarkModeSwitch()`: Dark mode switch widget'ı
- Switch butonu ile tema değiştirme
- Görsel geri bildirim (ikon değişimi)

## 🎨 Tema Renkleri

### Light Mode (Varsayılan)
```dart
Primary: #F4220B (Kırmızı)
Background: #F8F9FA (Açık Gri)
Surface: #FFFFFF (Beyaz)
Text: #000000 (Siyah)
```

### Dark Mode
```dart
Primary: #F4220B (Kırmızı) - Aynı
Background: #132440 (Lacivert)
Surface: #1A2F47 (Koyu Lacivert)
Text: #FFFFFF (Beyaz)
```

## 🎯 Dark Mode Renk Paleti

### Ana Renkler
- **Background**: `#132440` (Lacivert - Ana arka plan)
- **Surface**: `#1A2F47` (Koyu Lacivert - Kartlar, AppBar)
- **Primary**: `#F4220B` (Kırmızı - Butonlar, vurgular)
- **Text**: `#FFFFFF` (Beyaz - Ana metin)
- **Text Secondary**: `#FFFFFF70` (Beyaz %70 - İkincil metin)

### Kullanım Alanları
```
AppBar: #1A2F47
Cards: #1A2F47
Bottom Nav: #1A2F47
Scaffold: #132440
Buttons: #F4220B (değişmedi)
Icons: #F4220B (değişmedi)
```

## 📱 Kullanıcı Akışı

### Tema Değiştirme
1. Profil sayfasına git
2. "Karanlık Mod" switch'ini bul
3. Switch'e tıkla
4. Tema anında değişir
5. Ayar otomatik kaydedilir

### İlk Açılış
1. Uygulama açılır
2. Local storage kontrol edilir
3. Kayıtlı tema varsa yüklenir
4. Yoksa Light Mode (varsayılan)
5. Firestore'dan senkronize edilir

## 🔧 Teknik Detaylar

### Theme Controller
```dart
class ThemeController extends GetxController {
  var isDarkMode = false.obs;
  
  Future<void> toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    await _storage.write(_themeKey, isDarkMode.value);
    await _saveThemeToFirestore();
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}
```

### Local Storage
```dart
// Kaydet
await _storage.write('isDarkMode', true);

// Yükle
final savedTheme = _storage.read('isDarkMode');
```

### Firestore Storage
```dart
// Kaydet
await _db.collection('users').doc(userId).set({
  'isDarkMode': isDarkMode,
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

// Yükle
final profile = _userService.userProfile.value;
if (profile != null && profile['isDarkMode'] != null) {
  isDarkMode.value = profile['isDarkMode'];
}
```

### Main.dart Integration
```dart
final themeController = Get.find<ThemeController>();

return Obx(() => GetMaterialApp(
  theme: themeController.lightTheme,
  darkTheme: themeController.darkTheme,
  themeMode: themeController.isDarkMode.value 
    ? ThemeMode.dark 
    : ThemeMode.light,
));
```

## 🎨 UI Görünümü

### Profil Sayfası - Dark Mode Switch
```
┌─────────────────────────────┐
│  🌙 Karanlık Mod            │
│     Karanlık tema aktif     │
│                      [ON]   │
└─────────────────────────────┘
```

### Light Mode
```
┌─────────────────────────────┐
│  ☀️ Karanlık Mod             │
│     Aydınlık tema aktif     │
│                      [OFF]  │
└─────────────────────────────┘
```

## 📊 Veri Akışı

### Tema Değiştirme Akışı
```
1. Kullanıcı switch'e tıklar
   ↓
2. toggleTheme() çağrılır
   ↓
3. isDarkMode değeri değişir
   ↓
4. Local storage'a kaydedilir
   ↓
5. Firestore'a kaydedilir
   ↓
6. Get.changeThemeMode() çağrılır
   ↓
7. UI anında güncellenir
```

### Uygulama Açılış Akışı
```
1. Uygulama başlar
   ↓
2. ThemeController.onInit() çağrılır
   ↓
3. loadThemeMode() çalışır
   ↓
4. Local storage kontrol edilir
   ↓
5. Firestore'dan senkronize edilir
   ↓
6. Tema uygulanır
```

## 🎯 Özellikler

### Kullanıcı Açısından
- ✅ Kolay tema değiştirme (tek tıkla)
- ✅ Anında görsel geri bildirim
- ✅ Ayar kalıcı (kapatıp açınca korunur)
- ✅ Cihazlar arası senkronizasyon
- ✅ Göz dostu dark mode

### Geliştirici Açısından
- ✅ GetX ile reaktif
- ✅ Merkezi tema yönetimi
- ✅ Kolay özelleştirme
- ✅ Local + Cloud storage
- ✅ Otomatik senkronizasyon

## 💾 Veri Saklama

### Local Storage (GetStorage)
```dart
Key: 'isDarkMode'
Value: true/false
Location: Device local storage
Purpose: Hızlı erişim, offline çalışma
```

### Firestore
```json
users/{userId}
{
  "isDarkMode": true,
  "updatedAt": Timestamp
}
```

## 🎨 Tema Özelleştirme

### Light Theme
```dart
ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFFF4220B),
  scaffoldBackgroundColor: Color(0xFFF8F9FA),
  colorScheme: ColorScheme.light(
    primary: Color(0xFFF4220B),
    secondary: Color(0xFF1E3A5F),
    surface: Colors.white,
    background: Color(0xFFF8F9FA),
  ),
)
```

### Dark Theme
```dart
ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFFF4220B),
  scaffoldBackgroundColor: Color(0xFF132440),
  colorScheme: ColorScheme.dark(
    primary: Color(0xFFF4220B),
    secondary: Color(0xFF1E3A5F),
    surface: Color(0xFF1A2F47),
    background: Color(0xFF132440),
  ),
)
```

## 🔍 Kullanım Örnekleri

### Widget'larda Tema Kullanımı
```dart
// Arka plan rengi
Container(
  color: Theme.of(context).scaffoldBackgroundColor,
)

// Kart rengi
Card(
  color: Theme.of(context).cardTheme.color,
)

// Metin rengi
Text(
  'Merhaba',
  style: TextStyle(
    color: Theme.of(context).textTheme.bodyLarge?.color,
  ),
)

// Dark mode kontrolü
if (Get.isDarkMode) {
  // Dark mode özel kod
}
```

## ⚡ Performans

### Optimizasyonlar
- ✅ Obx ile sadece gerekli widget'lar yeniden build edilir
- ✅ Local storage ile hızlı yükleme
- ✅ Firestore async yükleme (UI bloklamaz)
- ✅ Tema değişimi smooth (animasyonlu)

## 🐛 Hata Yönetimi

### Try-Catch Blokları
```dart
try {
  await _storage.write(_themeKey, isDarkMode.value);
  await _saveThemeToFirestore();
} catch (e) {
  print('Tema kaydetme hatası: $e');
  // Kullanıcıya bildirim gösterilebilir
}
```

### Fallback Değerler
```dart
// Local storage yoksa
final savedTheme = _storage.read(_themeKey) ?? false;

// Firestore yoksa
final isDark = profile['isDarkMode'] ?? false;
```

## 📝 Notlar

### Önemli
- Light mode varsayılan
- Dark mode #132440 lacivert ağırlıklı
- Butonlar her iki temada da kırmızı (#F4220B)
- Ayar kullanıcı bazında saklanır

### Dikkat Edilmesi Gerekenler
- ThemeController main.dart'ta initialize edilmeli
- GetStorage.init() çağrılmalı
- Firestore rules'da isDarkMode alanı izinli olmalı

## 🎯 Sonuç

Dark mode özelliği başarıyla eklendi. Kullanıcılar artık göz dostu karanlık temayı kullanabilir. Ayarlar hem local hem de cloud'da saklanır, cihazlar arası senkronize olur.

### Avantajlar:
1. **Göz Sağlığı**: Karanlıkta daha rahat okuma
2. **Batarya Tasarrufu**: OLED ekranlarda enerji tasarrufu
3. **Modern Görünüm**: Profesyonel dark mode tasarımı
4. **Kişiselleştirme**: Kullanıcı tercihi
5. **Senkronizasyon**: Cihazlar arası ayar paylaşımı

Dark mode ile uygulama daha modern ve kullanıcı dostu! 🌙
