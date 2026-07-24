import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place_model.dart';

class PlaceRepository {
  // Kết nối với kho dữ liệu Firestore
  final _supabase = Supabase.instance.client;

  Future<List<PlaceModel>> getPlaces() async {
    try {
      // 1. Chạy lên mây, tìm thư mục tên là 'places' và lấy hết tài liệu về
      final List<dynamic> response = await _supabase.from('places').select().order('display_order', ascending: true);
      
      // 2. Chuyển đổi từng tài liệu lấy được thành PlaceModel
      return response.map((data) => PlaceModel.fromMap(data)).toList();
      
    } catch (e) {
      // print("Error when map data from supabase: $e");
      return []; // Trả về mảng rỗng nếu có lỗi (tránh crash app)
    }
  }
}