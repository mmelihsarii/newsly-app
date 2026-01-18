class CategoryModel {
  String? id;
  String? name;
  String? image;
  bool isFollowing; // Takip ediliyor mu? (eGündem mantığı için şart)

  CategoryModel({
    this.id,
    this.name,
    this.image,
    this.isFollowing = false, // Varsayılan: Takip edilmiyor
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['category_name'],
      image: json['image'],
    );
  }
}
