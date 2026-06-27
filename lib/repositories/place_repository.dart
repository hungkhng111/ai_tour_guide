import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';

class PlaceRepository {
  /// Lấy danh sách Place từ Firestore theo tên collection
  static Future<List<PlaceModel>> getPlaces(String collectionName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .get();

      return querySnapshot.docs
          .map((doc) => PlaceModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Bạn có thể log lỗi hoặc throw lại tùy theo nhu cầu
      rethrow;
    }
  }
}