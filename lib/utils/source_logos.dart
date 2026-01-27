/// Haber kaynaklarının logo URL'leri
/// Firebase Storage'dan çekilir
class SourceLogos {
  // Logo URL cache'i
  static final Map<String, String> _logoCache = {};
  
  /// Firebase Storage base URL
  static const String _storageBaseUrl = 'https://firebasestorage.googleapis.com/v0/b/newsly-70ef9.firebasestorage.app/o/source_logos%2F';
  
  /// Kaynak adına göre logo URL'si döndür
  /// Firebase Storage'da source_logos/kaynak_adi.png formatında olmalı
  static String getLogoUrl(String? sourceName) {
    if (sourceName == null || sourceName.isEmpty) {
      return '${_storageBaseUrl}default.png?alt=media';
    }
    
    final normalized = _normalizeForFilename(sourceName);
    
    // Cache'de varsa döndür
    if (_logoCache.containsKey(normalized)) {
      return _logoCache[normalized]!;
    }
    
    // Firebase Storage URL'i oluştur
    final logoUrl = '$_storageBaseUrl$normalized.png?alt=media';
    
    // Cache'e ekle
    _logoCache[normalized] = logoUrl;
    
    return logoUrl;
  }
  
  /// Birden fazla URL varyasyonu döndür (fallback için)
  /// Örn: "Halk TV" için ["halk_tv.png", "halktv.png", "halk-tv.png"] dener
  static List<String> getLogoUrlVariants(String? sourceName) {
    if (sourceName == null || sourceName.isEmpty) {
      return ['${_storageBaseUrl}default.png?alt=media'];
    }
    
    final variants = <String>[];
    final base = sourceName.toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll('.', '')
        .replaceAll('&', '')
        .replaceAll("'", '')
        .trim();
    
    // Varyasyon 1: alt çizgi ile (halk_tv)
    final withUnderscore = base.replaceAll(' ', '_').replaceAll('-', '_');
    variants.add('$_storageBaseUrl$withUnderscore.png?alt=media');
    
    // Varyasyon 2: boşluksuz (halktv)
    final noSpace = base.replaceAll(' ', '').replaceAll('-', '').replaceAll('_', '');
    if (noSpace != withUnderscore) {
      variants.add('$_storageBaseUrl$noSpace.png?alt=media');
    }
    
    // Varyasyon 3: tire ile (halk-tv)
    final withDash = base.replaceAll(' ', '-').replaceAll('_', '-');
    if (withDash != withUnderscore && withDash != noSpace) {
      variants.add('$_storageBaseUrl$withDash.png?alt=media');
    }
    
    return variants;
  }
  
  /// Kaynak adını dosya adına uygun hale getir
  /// Halk TV -> halk_tv
  static String _normalizeForFilename(String name) {
    return name
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('.', '')
        .replaceAll('&', '')
        .replaceAll("'", '')
        .trim();
  }
  
  /// Cache'i temizle
  static void clearCache() {
    _logoCache.clear();
  }
}
