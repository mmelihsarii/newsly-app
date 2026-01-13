class NewsModel {
  String? id;
  String? title;
  String? image;
  String? date;
  String? categoryName;
  String? description;
  String? type; // video, standard vs.
  String? contentValue; // HTML içerik veya video linki
  String? sourceUrl; // RSS'ten gelen orjinal link (Ekletmiştik ya hani)

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
  });

  // JSON'dan gelen veriyi Dart objesine çevir
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

    return NewsModel(
      id: json['id'].toString(),
      title: json['title'],
      image: imageUrl,
      date: json['date'],
      categoryName: json['category_name'],
      description: json['description'],
      type: json['content_type'],
      contentValue: json['content_value'],
      sourceUrl: json['other_url'],
    );
  }

  // Storage için JSON'a çevir
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
    };
  }

  // Storage'dan JSON okuma
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
    );
  }
}
