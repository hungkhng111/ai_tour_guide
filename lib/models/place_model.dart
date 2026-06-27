class PlaceModel {
  final String title;
  final String rating;
  final String tags;
  final String imageUrl;

  PlaceModel({
    required this.title,
    required this.rating,
    required this.tags,
    required this.imageUrl,
  });

  // Ham dac biet (factory) dung de bien doi du lieu nhan ve tu firebase (dang map) 
  // thanh mot Doi tuong Dart (Object) giup giao dien hien thi duoc ngay
  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      title: map['title'] ?? '',
      rating: map['rating'] ?? '0.0',
      tags: map['tags'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}