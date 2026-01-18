# Carousel Otomatik Kaydırma Özelliği

## 📋 Özet
Anasayfadaki "Popüler Haberler" carousel'ine 2.5 saniye aralıklarla otomatik kaydırma özelliği eklendi.

## ✅ Yapılan Değişiklikler

### 1. `lib/controllers/home_controller.dart`
- **Timer import'u eklendi**: `dart:async` paketi eklendi
- **Timer değişkeni**: `Timer? _carouselTimer` eklendi
- **startAutoScroll() metodu**: 2.5 saniye aralıklarla carousel'i otomatik kaydıran metod
- **resetAutoScroll() metodu**: Manuel kaydırma yapıldığında timer'ı sıfırlayan metod
- **onClose() güncellendi**: Timer'ın düzgün şekilde iptal edilmesi için
- **fetchNews() güncellendi**: Haberler yüklendikten sonra otomatik kaydırmayı başlatıyor

### 2. `lib/views/home/home_view.dart`
- **onPageChanged callback güncellendi**: Manuel kaydırma yapıldığında `resetAutoScroll()` çağrılıyor

## 🎯 Özellikler

### Otomatik Kaydırma
- **Süre**: 2.5 saniye (2500 milisaniye)
- **Animasyon**: 400ms smooth geçiş (easeInOut curve)
- **Döngü**: Son habere ulaşınca başa döner

### Manuel Kontrol
- Kullanıcı carousel'i manuel kaydırdığında timer sıfırlanır
- Manuel kaydırmadan sonra otomatik kaydırma devam eder
- Kullanıcı deneyimi kesintisiz

### Güvenlik
- Carousel boşsa timer otomatik iptal edilir
- Controller dispose edildiğinde timer temizlenir
- `hasClients` kontrolü ile crash önlenir

## 🔧 Teknik Detaylar

### Timer Yönetimi
```dart
Timer? _carouselTimer;

void startAutoScroll() {
  _carouselTimer?.cancel(); // Önceki timer'ı iptal et
  _carouselTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
    // Her 2.5 saniyede bir çalışır
    if (carouselNewsList.isEmpty) {
      timer.cancel();
      return;
    }
    
    final nextIndex = (currentCarouselIndex.value + 1) % carouselNewsList.length;
    
    if (carouselController.hasClients) {
      carouselController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  });
}
```

### Manuel Kaydırma Yönetimi
```dart
onPageChanged: (index) {
  controller.currentCarouselIndex.value = index;
  controller.resetAutoScroll(); // Timer'ı sıfırla
}
```

## 📱 Kullanıcı Deneyimi

1. **Otomatik Geçiş**: Kullanıcı hiçbir şey yapmasa bile carousel otomatik ilerler
2. **Manuel Kontrol**: Kullanıcı istediği zaman manuel kaydırabilir
3. **Smooth Animasyon**: Geçişler yumuşak ve profesyonel
4. **Döngüsel**: Son habere ulaşınca başa döner

## 🎨 Animasyon Detayları

- **Süre**: 400ms
- **Curve**: `Curves.easeInOut` (başlangıç ve bitiş yavaş, ortası hızlı)
- **Interval**: 2500ms (2.5 saniye)

## ✨ Avantajlar

1. **Kullanıcı Etkileşimi**: Daha fazla haber görünürlüğü
2. **Modern UX**: Otomatik carousel modern uygulamalarda standart
3. **Performans**: Timer optimize edilmiş, gereksiz yük yok
4. **Güvenlik**: Crash ve memory leak önlemleri alınmış

## 🔄 Yaşam Döngüsü

1. **Başlangıç**: `fetchNews()` çağrıldığında `startAutoScroll()` başlar
2. **Çalışma**: Her 2.5 saniyede bir sonraki sayfaya geçer
3. **Manuel Müdahale**: Kullanıcı kaydırırsa timer sıfırlanır ve yeniden başlar
4. **Bitiş**: Controller dispose edildiğinde timer iptal edilir

## 📝 Notlar

- Timer her zaman temizlenir, memory leak riski yok
- Carousel boşsa timer otomatik durur
- Manuel kaydırma otomatik kaydırmayı engellemez, sadece sıfırlar
- Smooth animasyon kullanıcı deneyimini iyileştirir

## 🎯 Sonuç

Carousel artık 2.5 saniye aralıklarla otomatik olarak kaydırılıyor. Kullanıcı deneyimi modern ve profesyonel seviyede.
