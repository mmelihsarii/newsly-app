import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Haber okuma ayarları controller'ı
/// - Font boyutu ayarlama
/// - Okuma modu (sadece metin)
/// - Görselleri gizleme
class ReadingSettingsController extends GetxController {
  final GetStorage _storage = GetStorage();
  
  // Font boyutu (14-24 arası)
  static const double minFontSize = 14.0;
  static const double maxFontSize = 24.0;
  static const double defaultFontSize = 16.0;
  
  var fontSize = defaultFontSize.obs;
  var isReadingMode = false.obs; // Sadece metin modu
  var hideImages = false.obs; // Görselleri gizle
  
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }
  
  void _loadSettings() {
    fontSize.value = _storage.read<double>('reading_font_size') ?? defaultFontSize;
    isReadingMode.value = _storage.read<bool>('reading_mode') ?? false;
    hideImages.value = _storage.read<bool>('hide_images') ?? false;
  }
  
  void _saveSettings() {
    _storage.write('reading_font_size', fontSize.value);
    _storage.write('reading_mode', isReadingMode.value);
    _storage.write('hide_images', hideImages.value);
  }
  
  /// Font boyutunu artır
  void increaseFontSize() {
    if (fontSize.value < maxFontSize) {
      fontSize.value += 2;
      _saveSettings();
    }
  }
  
  /// Font boyutunu azalt
  void decreaseFontSize() {
    if (fontSize.value > minFontSize) {
      fontSize.value -= 2;
      _saveSettings();
    }
  }
  
  /// Font boyutunu sıfırla
  void resetFontSize() {
    fontSize.value = defaultFontSize;
    _saveSettings();
  }
  
  /// Okuma modunu değiştir
  void toggleReadingMode() {
    isReadingMode.value = !isReadingMode.value;
    _saveSettings();
  }
  
  /// Görselleri gizle/göster
  void toggleHideImages() {
    hideImages.value = !hideImages.value;
    _saveSettings();
  }
  
  /// Font boyutu label'ı
  String get fontSizeLabel {
    if (fontSize.value <= 14) return 'Küçük';
    if (fontSize.value <= 16) return 'Normal';
    if (fontSize.value <= 20) return 'Büyük';
    return 'Çok Büyük';
  }
}
