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
    this.title,
    this.image,
    this.date,
    this.categoryName,
    this.description,
    this.type,
    this.contentValue,
    this.sourceUrl,
    this.sourceName,
    this.publishedAt,
  });

  // --- 1. DÜZELTME: fromMap GÜÇLENDİRİLDİ ---
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
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      date: map['date'] ?? '',
      // Eksik olanları ekledik:
      categoryName: map['category_name'] ?? map['categoryName'] ?? '',
      type: map['content_type'] ?? map['type'] ?? 'standard_post',
      contentValue: map['content_value'] ?? map['video_url'] ?? '',
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
      title: json['title'],
      image: imageUrl,
      date: json['date'],
      categoryName: categoryNameValue,
      description: json['description'],
      type: json['content_type'] ?? json['type'],
      contentValue: json['content_value'] ?? json['contentValue'],
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

  // --- 3. DÜZELTME: Storage OKUMA (sourceName Eklendi) ---
  factory NewsModel.fromStorageJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['publishedAt'] != null) {
      parsedDate = DateTime.tryParse(json['publishedAt'].toString());
    }
    
    return NewsModel(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      date: json['date'],
      categoryName: json['categoryName'],
      description: json['description'],
      type: json['type'],
      contentValue: json['contentValue'],
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
