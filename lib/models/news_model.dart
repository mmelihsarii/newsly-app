class NewsModel {
  String? id;
  String? title;
  String? image;
  String? date;
  String? categoryName;
  String? description;
  String? type; // video, standard_post vs.
  String? contentValue; // HTML içerik veya video linki
  String? sourceUrl; // RSS'ten gelen orjinal link
  String? sourceName; // RSS Kaynak Adı (Örn: BBC, CNN)
  DateTime? publishedAt; // Sıralama için raw DateTime

  NewsModel({
    this.id,
    String? title,
    this.image,
    this.date,
    this.categoryName,
    String? description,
    this.type,
    String? contentValue,
    this.sourceUrl,
    this.sourceName,
    this.publishedAt,
  }) : title = _fixTurkishText(title),
       description = _fixTurkishText(description),
       contentValue = _fixTurkishText(contentValue);

  /// Türkçe metin düzeltme - TÜM encoding sorunlarını çöz
  static String? _fixTurkishText(String? text) {
    if (text == null || text.isEmpty) return text;
    
    String fixed = text;
    
    // UTF-8 double encoding düzeltmeleri
    final fixes = {
      'Ä±': 'ı', 'Ä°': 'İ', 'ÄŸ': 'ğ', 'Ä': 'Ğ',
      'Ã¼': 'ü', 'Ãœ': 'Ü', 'ÅŸ': 'ş', 'Å': 'Ş',
      'Ã¶': 'ö', 'Ã–': 'Ö', 'Ã§': 'ç', 'Ã‡': 'Ç',
      'Ã¢': 'â', 'Ã®': 'î', 'Ã»': 'û',
      'â€™': "'", 'â€œ': '"', 'â€': '"',
      'â€"': '–', 'â€"': '—', 'â€¦': '...',
      'Â°': '°', 'Â»': '»', 'Â«': '«', 'Â': '',
      // Windows-1254 fixes
      'Ý': 'İ', 'ý': 'ı', 'Þ': 'Ş', 'þ': 'ş', 'Ð': 'Ğ', 'ð': 'ğ',
      // HTML entities
      '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"',
      '&apos;': "'", '&#39;': "'", '&nbsp;': ' ',
      '&#305;': 'ı', '&#304;': 'İ', '&#287;': 'ğ', '&#286;': 'Ğ',
      '&#252;': 'ü', '&#220;': 'Ü', '&#351;': 'ş', '&#350;': 'Ş',
      '&#246;': 'ö', '&#214;': 'Ö', '&#231;': 'ç', '&#199;': 'Ç',
    };
    
    fixes.forEach((wrong, correct) {
      fixed = fixed.replaceAll(wrong, correct);
    });
    
    // Numeric HTML entities
    fixed = fixed.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        try {
          return String.fromCharCode(int.parse(match.group(1)!));
        } catch (_) {
          return match.group(0)!;
        }
      },
    );
    
    // CDATA temizle
    fixed = fixed.replaceAll(RegExp(r'<!\[CDATA\['), '');
    fixed = fixed.replaceAll(RegExp(r'\]\]>'), '');
    
    // Replacement character temizle
    fixed = fixed.replaceAll('�', '');
    fixed = fixed.replaceAll('\uFFFD', '');
    
    return fixed.trim();
  }

  // --- 1. DÜZELTME: fromMap GÜÇLENDİRİLDİ + Encoding Fix ---
  // Firebase veya veritabanından Map olarak gelirse tüm verileri almalı
  factory NewsModel.fromMap(Map<dynamic, dynamic> map) {
    DateTime? parsedDate;
    if (map['publishedAt'] != null) {
      parsedDate = DateTime.tryParse(map['publishedAt'].toString());
    } else if (map['date'] != null) {
      parsedDate = _tryParseDate(map['date'].toString());
    }
    
    return NewsModel(
      id: map['id'].toString(),
      title: _fixTurkishText(map['title']?.toString()),
      description: _fixTurkishText(map['description']?.toString()),
      image: map['image'] ?? '',
      date: map['date'] ?? '',
      // Eksik olanları ekledik:
      categoryName: map['category_name'] ?? map['categoryName'] ?? '',
      type: map['content_type'] ?? map['type'] ?? 'standard_post',
      contentValue: _fixTurkishText(map['content_value']?.toString() ?? map['video_url']?.toString()),
      sourceUrl: map['source_url'] ?? map['sourceUrl'] ?? '',
      sourceName: map['source_name'] ?? map['sourceName'] ?? '',
      publishedAt: parsedDate,
    );
  }

  // --- API / JSON DÖNÜŞÜMÜ (Mevcut mantık korundu) ---
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['image'];

    // Eğer ana resim yoksa ama kategori resmi varsa onu kullan
    if ((imageUrl == null || imageUrl.isEmpty) && json['category'] != null) {
      imageUrl = json['category']['image'];
    }

    // Eğer 'images' array'i varsa ve doluysa oradan al
    if ((imageUrl == null || imageUrl.isEmpty) &&
        json['images'] != null &&
        (json['images'] as List).isNotEmpty) {
      var firstImg = (json['images'] as List).first;
      if (firstImg is String) {
        imageUrl = firstImg;
      } else if (firstImg is Map) {
        imageUrl = firstImg['image'] ?? firstImg['file'];
      }
    }

    // Kaynak adını bulma mantığı
    String? sourceNameValue =
        json['sourceName'] ??
        json['source_name'] ??
        json['source'] ??
        json['rss_source'] ??
        json['rss_source_name'];

    // Eğer hala yoksa, URL'den host adını çıkar (örn: hurriyet.com.tr)
    if ((sourceNameValue == null || sourceNameValue.isEmpty) && json['other_url'] != null) {
      try {
        final uri = Uri.parse(json['other_url']);
        sourceNameValue = uri.host.replaceAll('www.', '');
      } catch (_) {}
    }
    if ((sourceNameValue == null || sourceNameValue.isEmpty) && json['sourceUrl'] != null) {
      try {
        final uri = Uri.parse(json['sourceUrl']);
        sourceNameValue = uri.host.replaceAll('www.', '');
      } catch (_) {}
    }

    // Eğer sourceName hala boşsa, categoryName'i kullan (filtreleme için önemli!)
    final String? categoryNameValue = json['categoryName'] ?? json['category_name'];
    if ((sourceNameValue == null || sourceNameValue.isEmpty) && categoryNameValue != null) {
      sourceNameValue = categoryNameValue;
    }

    // Tarih parse etme
    DateTime? parsedDate;
    if (json['published_at'] != null) {
      parsedDate = DateTime.tryParse(json['published_at'].toString());
    } else if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString());
    } else if (json['date'] != null) {
      parsedDate = _tryParseDate(json['date'].toString());
    }

    return NewsModel(
      id: json['id'].toString(),
      title: _fixTurkishText(json['title']?.toString()),
      image: imageUrl,
      date: json['date'],
      categoryName: categoryNameValue,
      description: _fixTurkishText(json['description']?.toString()),
      type: json['content_type'] ?? json['type'],
      contentValue: _fixTurkishText(json['content_value']?.toString() ?? json['contentValue']?.toString()),
      sourceUrl: json['sourceUrl'] ?? json['other_url'],
      sourceName: sourceNameValue,
      publishedAt: parsedDate,
    );
  }

  // --- 2. DÜZELTME: Storage YAZMA (sourceName Eklendi) ---
  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'date': date,
      'categoryName': categoryName,
      'description': description,
      'type': type,
      'contentValue': contentValue,
      'sourceUrl': sourceUrl,
      'sourceName': sourceName,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }

  // Cache için JSON dönüşümü (toStorageJson ile aynı)
  Map<String, dynamic> toJson() => toStorageJson();

  // --- 3. DÜZELTME: Storage OKUMA (sourceName Eklendi + Encoding Fix) ---
  factory NewsModel.fromStorageJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['publishedAt'] != null) {
      parsedDate = DateTime.tryParse(json['publishedAt'].toString());
    }
    
    return NewsModel(
      id: json['id'],
      title: _fixTurkishText(json['title']),
      image: json['image'],
      date: json['date'],
      categoryName: json['categoryName'],
      description: _fixTurkishText(json['description']),
      type: json['type'],
      contentValue: _fixTurkishText(json['contentValue']),
      sourceUrl: json['sourceUrl'],
      sourceName: json['sourceName'],
      publishedAt: parsedDate,
    );
  }

  // Tarih parse helper
  static DateTime? _tryParseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    // ISO 8601 formatı
    DateTime? result = DateTime.tryParse(dateStr);
    if (result != null) return result;
    
    // RFC 822 formatı: "Mon, 01 Jan 2024 10:00:00 GMT"
    try {
      final parts = dateStr.split(' ');
      if (parts.length >= 5) {
        final day = int.parse(parts[1]);
        final month = _monthToNumber(parts[2]);
        final year = int.parse(parts[3]);
        final timeParts = parts[4].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
        return DateTime.utc(year, month, day, hour, minute, second);
      }
    } catch (_) {}
    
    // "dd MMM HH:mm" formatı
    try {
      final parts = dateStr.split(' ');
      if (parts.length >= 3) {
        final now = DateTime.now();
        final day = int.parse(parts[0]);
        final month = _monthToNumber(parts[1]);
        final timeParts = parts[2].split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(now.year, month, day, hour, minute);
      }
    } catch (_) {}
    
    return null;
  }

  static int _monthToNumber(String month) {
    const months = {
      // İngilizce
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      // Türkçe
      'Oca': 1, 'Şub': 2, 'Mart': 3, 'Nis': 4, 'Mayıs': 5, 'Haz': 6,
      'Tem': 7, 'Ağu': 8, 'Eyl': 9, 'Eki': 10, 'Kas': 11, 'Ara': 12,
    };
    return months[month] ?? 1;
  }
}
