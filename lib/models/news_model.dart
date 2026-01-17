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
  });

  // --- 1. DÜZELTME: fromMap GÜÇLENDİRİLDİ ---
  // Firebase veya veritabanından Map olarak gelirse tüm verileri almalı
  factory NewsModel.fromMap(Map<dynamic, dynamic> map) {
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
        json['source_name'] ??
        json['source'] ??
        json['rss_source'] ??
        json['rss_source_name'];

    // Eğer hala yoksa, URL'den host adını çıkar (örn: hurriyet.com.tr)
    if (sourceNameValue == null && json['other_url'] != null) {
      try {
        final uri = Uri.parse(json['other_url']);
        sourceNameValue = uri.host.replaceAll('www.', '');
      } catch (_) {}
    }

    return NewsModel(
      id: json['id'].toString(),
      title: json['title'],
      image: imageUrl,
      date: json['date'],
      categoryName: json['category_name'],
      description: json['description'],
      type: json['content_type'], // API genelde content_type döner
      contentValue: json['content_value'],
      sourceUrl: json['other_url'], // RSS linki genelde other_url alanındadır
      sourceName: sourceNameValue,
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
      'sourceName': sourceName, // <--- ARTIK KAYNAK ADI DA KAYDEDİLİYOR
    };
  }

  // --- 3. DÜZELTME: Storage OKUMA (sourceName Eklendi) ---
  factory NewsModel.fromStorageJson(Map<String, dynamic> json) {
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
      sourceName: json['sourceName'], // <--- ARTIK GERİ YÜKLENİYOR
    );
  }
}
