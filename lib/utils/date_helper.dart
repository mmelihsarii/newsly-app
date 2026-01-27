import 'package:intl/intl.dart';

class DateHelper {
  /// Tarihi "X dakika önce", "X saat önce" formatına çevirir
  /// DateTime veya String kabul eder
  /// publishedAt (yayınlanma tarihi) öncelikli kullanılmalı
  static String getTimeAgo(dynamic dateInput) {
    if (dateInput == null) {
      return '';
    }

    DateTime? dateTime;
    String? originalString;

    // DateTime ise direkt kullan
    if (dateInput is DateTime) {
      dateTime = dateInput;
    } else if (dateInput is String) {
      if (dateInput.isEmpty) {
        return '';
      }
      originalString = dateInput;
      dateTime = _parseDate(dateInput);
      
      // Parse edilemezse orijinal string'i döndür (boş yerine)
      if (dateTime == null) {
        return originalString;
      }
    }

    if (dateTime == null) {
      return originalString ?? '';
    }

    // Mantıksız tarih kontrolü (2015'ten önce)
    final now = DateTime.now();
    if (dateTime.year < 2015) {
      return '';
    }
    
    // Çok eski tarih (5 yıldan fazla) - sadece yılı göster
    if (dateTime.year < now.year - 5) {
      return '${dateTime.year}';
    }

    final difference = now.difference(dateTime);

    // Gelecek tarih kontrolü (1 günden fazla ileride)
    if (difference.inDays < -1) {
      return 'Yakında';
    }
    
    // Gelecek tarih (1 gün içinde) - "Şimdi" yerine tarih göster
    if (difference.isNegative) {
      // Birkaç dakika ileride olabilir (saat farkı vs)
      if (difference.inMinutes > -60) {
        return 'Az önce';
      }
      // Daha ilerideyse tarih göster
      try {
        return '${dateTime.day} ${_getMonthName(dateTime.month)}';
      } catch (_) {
        return 'Az önce';
      }
    }

    // Zaman farkına göre formatla
    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes dk önce';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours saat önce';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta önce';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ay önce';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years yıl önce';
    }
  }
  
  /// Ay numarasından Türkçe ay adı
  static String _getMonthName(int month) {
    const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  /// Tarih string'ini parse et - birden fazla format dene
  static DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;

    // 1. ISO 8601 formatı: "2024-01-01T10:00:00Z" veya "2024-01-01T10:00:00+03:00"
    try {
      final result = DateTime.parse(dateString);
      if (result.year >= 2015) return result;
    } catch (_) {}

    // 2. RFC 822 formatı: "Mon, 01 Jan 2024 10:00:00 GMT" veya "+0300"
    try {
      final result = _parseRfc822(dateString);
      if (result != null && result.year >= 2015) return result;
    } catch (_) {}

    // 3. Özel format: "dd MMM HH:mm" (örn: "25 Oca 14:30")
    try {
      final result = _parseShortFormat(dateString);
      if (result != null && result.year >= 2015) return result;
    } catch (_) {}

    // 4. Türkçe format: "25 Ocak 2026 14:30"
    try {
      final result = _parseTurkishFormat(dateString);
      if (result != null && result.year >= 2015) return result;
    } catch (_) {}
    
    // 5. Sadece tarih: "26 Ocak" veya "26 Oca"
    try {
      final result = _parseDateOnly(dateString);
      if (result != null && result.year >= 2015) return result;
    } catch (_) {}

    return null;
  }

  /// RFC 822 formatını parse et
  static DateTime? _parseRfc822(String date) {
    try {
      // "Mon, 01 Jan 2024 10:00:00 GMT" veya "Mon, 01 Jan 2024 10:00:00 +0300"
      // Türkçe karakterler için genişletilmiş
      final regex = RegExp(
        r'([a-zA-ZğüşöçıİĞÜŞÖÇ]+),?\s+(\d{1,2})\s+([a-zA-ZğüşöçıİĞÜŞÖÇ]+)\s+(\d{4})\s+(\d{2}):(\d{2}):?(\d{2})?\s*([\+\-]?\d{4}|GMT|UTC)?',
        caseSensitive: false,
      );
      final match = regex.firstMatch(date);
      if (match != null) {
        final day = int.parse(match.group(2)!);
        final monthStr = match.group(3)!;
        final year = int.parse(match.group(4)!);
        final hour = int.parse(match.group(5)!);
        final minute = int.parse(match.group(6)!);
        final second = match.group(7) != null ? int.parse(match.group(7)!) : 0;

        final month = _monthToNumber(monthStr);
        if (month == 0) return null;

        return DateTime.utc(year, month, day, hour, minute, second);
      }
    } catch (_) {}
    return null;
  }

  /// Kısa format: "25 Oca 14:30"
  static DateTime? _parseShortFormat(String date) {
    try {
      // \w yerine [a-zA-ZğüşöçıİĞÜŞÖÇ] kullanıyoruz - Türkçe karakterler için
      final regex = RegExp(r'(\d{1,2})\s+([a-zA-ZğüşöçıİĞÜŞÖÇ]+)\s+(\d{2}):(\d{2})');
      final match = regex.firstMatch(date);
      if (match != null) {
        final now = DateTime.now();
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;
        final hour = int.parse(match.group(3)!);
        final minute = int.parse(match.group(4)!);

        final month = _monthToNumber(monthStr);
        if (month == 0) return null;

        // Eğer tarih gelecekte ise geçen yılın tarihi olabilir
        var year = now.year;
        var result = DateTime(year, month, day, hour, minute);
        if (result.isAfter(now.add(const Duration(days: 1)))) {
          year = now.year - 1;
          result = DateTime(year, month, day, hour, minute);
        }

        return result;
      }
    } catch (_) {}
    return null;
  }

  /// Türkçe format: "25 Ocak 2026 14:30"
  static DateTime? _parseTurkishFormat(String date) {
    try {
      // Türkçe karakterler için genişletilmiş regex
      final regex = RegExp(r'(\d{1,2})\s+([a-zA-ZğüşöçıİĞÜŞÖÇ]+)\s+(\d{4})\s+(\d{2}):(\d{2})');
      final match = regex.firstMatch(date);
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);

        final month = _monthToNumber(monthStr);
        if (month == 0) return null;

        return DateTime(year, month, day, hour, minute);
      }
    } catch (_) {}
    return null;
  }
  
  /// Sadece tarih formatı: "26 Ocak" veya "26 Oca"
  static DateTime? _parseDateOnly(String date) {
    try {
      // "26 Ocak" veya "26 Oca" formatı - Türkçe karakterler için genişletilmiş
      final regex = RegExp(r'^(\d{1,2})\s+([a-zA-ZğüşöçıİĞÜŞÖÇ]+)$');
      final match = regex.firstMatch(date.trim());
      if (match != null) {
        final now = DateTime.now();
        final day = int.parse(match.group(1)!);
        final monthStr = match.group(2)!;

        final month = _monthToNumber(monthStr);
        if (month == 0) return null;

        // Eğer ay geçmişteyse bu yılın, değilse geçen yılın tarihi olabilir
        var year = now.year;
        if (month > now.month || (month == now.month && day > now.day)) {
          // Gelecek bir tarih gibi görünüyor, muhtemelen geçen yıldan
          year = now.year - 1;
        }

        return DateTime(year, month, day, 12, 0); // Öğlen 12:00 varsay
      }
    } catch (_) {}
    return null;
  }

  /// Ay adını sayıya çevir
  static int _monthToNumber(String month) {
    final monthLower = month.toLowerCase();
    const months = {
      // İngilizce - kısa
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      // İngilizce - uzun
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'june': 6,
      'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
      // Türkçe - kısa (3 harfli) - mar ve may İngilizce ile aynı, tekrar eklenmedi
      'oca': 1, 'şub': 2, 'nis': 4, 'haz': 6,
      'tem': 7, 'ağu': 8, 'eyl': 9, 'eki': 10, 'kas': 11, 'ara': 12,
      // Türkçe - uzun
      'ocak': 1, 'şubat': 2, 'mart': 3, 'nisan': 4, 'mayıs': 5, 'haziran': 6,
      'temmuz': 7, 'ağustos': 8, 'eylül': 9, 'ekim': 10, 'kasım': 11, 'aralık': 12,
    };
    return months[monthLower] ?? 0;
  }

  /// Tam tarih formatı (detay sayfası için)
  static String getFullDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }

    final dateTime = _parseDate(dateString);
    if (dateTime == null) return dateString;

    try {
      // Türkçe format: "17 Ocak 2026, 14:30"
      final format = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR');
      return format.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  /// Kısa tarih formatı: "17 Oca"
  static String getShortDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }

    final dateTime = _parseDate(dateString);
    if (dateTime == null) return dateString;

    try {
      final format = DateFormat('dd MMM', 'tr_TR');
      return format.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  /// HTML tag'lerini temizle + Encoding düzelt
  static String stripHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return '';
    }

    String result = htmlString;
    
    // === 1. UTF-8 DOUBLE ENCODING DÜZELTMELERİ ===
    final utf8Fixes = {
      'Ä±': 'ı', 'Ä°': 'İ', 'ÄŸ': 'ğ', 'Ä': 'Ğ',
      'Ã¼': 'ü', 'Ãœ': 'Ü', 'ÅŸ': 'ş', 'Å': 'Ş',
      'Ã¶': 'ö', 'Ã–': 'Ö', 'Ã§': 'ç', 'Ã‡': 'Ç',
      'Ã¢': 'â', 'Ã®': 'î', 'Ã»': 'û',
      'â€™': "'", 'â€œ': '"', 'â€': '"',
      'â€"': '–', 'â€"': '—', 'â€¦': '...',
      'Â°': '°', 'Â»': '»', 'Â«': '«', 'Â': '',
      // Windows-1254 fixes
      'Ý': 'İ', 'ý': 'ı', 'Þ': 'Ş', 'þ': 'ş', 'Ð': 'Ğ', 'ð': 'ğ',
    };
    
    utf8Fixes.forEach((wrong, correct) {
      result = result.replaceAll(wrong, correct);
    });

    // === 2. HTML TAG'LERİNİ KALDIR ===
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // === 3. CDATA TEMİZLE ===
    result = result.replaceAll(RegExp(r'<!\[CDATA\['), '');
    result = result.replaceAll(RegExp(r'\]\]>'), '');

    // === 4. HTML ENTITIES DECODE ===
    final htmlEntities = {
      '&nbsp;': ' ', '&amp;': '&', '&lt;': '<', '&gt;': '>',
      '&quot;': '"', '&#39;': "'", '&apos;': "'",
      '&#8230;': '...', '&hellip;': '...',
      '&#8211;': '-', '&#8212;': '-', '&ndash;': '-', '&mdash;': '-',
      '&lsquo;': ''', '&rsquo;': ''', '&ldquo;': '"', '&rdquo;': '"',
      '&bull;': '•', '&copy;': '©', '&reg;': '®', '&trade;': '™',
      '&deg;': '°', '&plusmn;': '±',
      // Türkçe HTML entities
      '&#305;': 'ı', '&#304;': 'İ', '&#287;': 'ğ', '&#286;': 'Ğ',
      '&#252;': 'ü', '&#220;': 'Ü', '&#351;': 'ş', '&#350;': 'Ş',
      '&#246;': 'ö', '&#214;': 'Ö', '&#231;': 'ç', '&#199;': 'Ç',
    };
    
    htmlEntities.forEach((entity, char) {
      result = result.replaceAll(entity, char);
    });
    
    // === 5. NUMERIC HTML ENTITIES ===
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        try {
          return String.fromCharCode(int.parse(match.group(1)!));
        } catch (_) {
          return match.group(0)!;
        }
      },
    );
    
    // === 6. HEX HTML ENTITIES ===
    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9A-Fa-f]+);'),
      (match) {
        try {
          return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
        } catch (_) {
          return match.group(0)!;
        }
      },
    );
    
    // === 7. REPLACEMENT CHARACTER TEMİZLE ===
    result = result.replaceAll('�', '');
    result = result.replaceAll('\uFFFD', '');

    // === 8. FAZLA BOŞLUKLARI TEMİZLE ===
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}
