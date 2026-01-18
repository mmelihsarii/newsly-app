import 'package:intl/intl.dart';

class DateHelper {
  /// Tarihi "X dakika önce", "X saat önce" formatına çevirir
  static String getTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }

    try {
      DateTime dateTime;

      // Farklı tarih formatlarını dene
      try {
        // RFC 822 formatı (RSS feeds): "Mon, 01 Jan 2024 10:00:00 GMT"
        dateTime = HttpDate.parse(dateString);
      } catch (_) {
        try {
          // ISO 8601 formatı: "2024-01-01T10:00:00Z"
          dateTime = DateTime.parse(dateString);
        } catch (_) {
          try {
            // Özel format: "dd MMM HH:mm"
            final now = DateTime.now();
            final format = DateFormat('dd MMM HH:mm');
            dateTime = format.parse(dateString);
            // Yıl bilgisi yoksa şimdiki yılı ekle
            dateTime = DateTime(
              now.year,
              dateTime.month,
              dateTime.day,
              dateTime.hour,
              dateTime.minute,
            );
          } catch (_) {
            // Parse edilemezse orijinal string'i döndür
            return dateString;
          }
        }
      }

      // Şimdiki zaman ile farkı hesapla
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      // Gelecek tarih kontrolü
      if (difference.isNegative) {
        return 'Şimdi';
      }

      // Zaman farkına göre formatla
      if (difference.inSeconds < 60) {
        return 'Az önce';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes dakika önce';
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
    } catch (e) {
      print('Tarih parse hatası: $e');
      return dateString;
    }
  }

  /// Tam tarih formatı (detay sayfası için)
  static String getFullDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }

    try {
      DateTime dateTime;

      try {
        dateTime = HttpDate.parse(dateString);
      } catch (_) {
        try {
          dateTime = DateTime.parse(dateString);
        } catch (_) {
          return dateString;
        }
      }

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

    try {
      DateTime dateTime;

      try {
        dateTime = HttpDate.parse(dateString);
      } catch (_) {
        try {
          dateTime = DateTime.parse(dateString);
        } catch (_) {
          return dateString;
        }
      }

      final format = DateFormat('dd MMM', 'tr_TR');
      return format.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  /// HTML tag'lerini temizle
  static String stripHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) {
      return '';
    }

    // HTML tag'lerini kaldır
    String result = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');

    // HTML entities'leri decode et
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&#8230;', '...')
        .replaceAll('&hellip;', '...')
        .replaceAll('&#8211;', '-')
        .replaceAll('&#8212;', '-')
        .replaceAll('&ndash;', '-')
        .replaceAll('&mdash;', '-');

    // Fazla boşlukları temizle
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}

// HttpDate için import
class HttpDate {
  static DateTime parse(String date) {
    // RFC 822 tarih formatını parse et
    // Örnek: "Mon, 01 Jan 2024 10:00:00 GMT"
    try {
      final parts = date.split(' ');
      if (parts.length < 5) throw FormatException('Invalid date format');

      final day = int.parse(parts[1]);
      final month = _monthToNumber(parts[2]);
      final year = int.parse(parts[3]);
      final timeParts = parts[4].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      return DateTime.utc(year, month, day, hour, minute, second);
    } catch (e) {
      throw FormatException('Could not parse date: $date');
    }
  }

  static int _monthToNumber(String month) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[month] ?? 1;
  }
}
