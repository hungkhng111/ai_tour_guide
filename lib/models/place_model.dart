class PlaceModel {
  final String id;
  final String name;
  final String date;
  final String openHour; // Đổi từ openTime
  final String location;
  final String price; // Đã có sẵn, giữ nguyên
  final List<String> imgPaths; // Đổi từ imagePaths
  final String shortDes; // Mới thêm
  final String description;

  PlaceModel({
required this.id,
    required this.name,
    required this.date,
    required this.openHour,
    required this.location,
    required this.price,
    required this.imgPaths,
    required this.shortDes,
    required this.description,
  });



// Hàm này lấy dữ liệu từ Supabase (chuẩn Map) và biến nó thành Đối tượng PlaceModel
factory PlaceModel.fromMap(Map<String, dynamic> data) {
    return PlaceModel(
      id: data['id'].toString(),
      name: data['name'] ?? 'Chưa cập nhật tên',
      date: data['date'] ?? 'Chưa cập nhật ngày',
      openHour: data['openHour'] ?? 'Chưa cập nhật giờ',
      location: data['location'] ?? 'Chưa cập nhật địa điểm',
      price: data['price'] ?? '0đ',
      imgPaths: data['imgPaths'] != null 
          ? List<String>.from(data['imgPaths']) 
          : [],
      shortDes: data['shortDes'] ?? 'Chưa có mô tả ngắn',
      description: data['description'] ?? 'Chưa có mô tả chi tiết',
    );
  }

}