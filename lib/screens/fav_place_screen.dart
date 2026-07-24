import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place_model.dart';
import '../widgets/vertical_place_card.dart';
import '../repositories/place_repository.dart';
import '../services/auth_service.dart';

class FavoritePlacesScreen extends StatefulWidget {
  const FavoritePlacesScreen({super.key});

  @override
  State<FavoritePlacesScreen> createState() => _FavoritePlacesScreenState();
}

class _FavoritePlacesScreenState extends State<FavoritePlacesScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final PlaceRepository _repository = PlaceRepository(); // Lấy kho dữ liệu

  bool _isLoading = true;
  List<PlaceModel> _favoritePlaces = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    // 1. Kiểm tra đăng nhập
    if (!_authService.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      // 2. Lấy toàn bộ danh sách địa điểm từ Repository (Giống hệt cách HomeScreen làm)
      final allPlaces = await _repository.getPlaces();

      // 3. Gọi lên Supabase lấy danh sách ID đã thả tim
      final response = await _supabase
          .from('user_favorites')
          .select('place_id')
          .eq('user_id', userId);

      final favoriteIds = response.map((e) => e['place_id'] as String).toList();

      // 4. Lọc danh sách gốc, chỉ giữ lại những địa điểm có ID khớp với danh sách tim
      if (mounted) {
        setState(() {
          _favoritePlaces = allPlaces.where((place) => favoriteIds.contains(place.id)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách yêu thích: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Địa điểm yêu thích', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : _favoritePlaces.isEmpty
              // GIAO DIỆN KHI CHƯA CÓ ĐỊA ĐIỂM NÀO
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn chưa có địa điểm yêu thích nào.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hãy khám phá và lưu lại nhé!',
                        style: TextStyle(fontSize: 14, color: Colors.black38),
                      ),
                    ],
                  ),
                )
              // GIAO DIỆN HIỂN THỊ DANH SÁCH TỪ TRÊN XUỐNG DƯỚI
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _favoritePlaces.length,
                  itemBuilder: (context, index) {
                    return VerticalPlaceCard(place: _favoritePlaces[index]);
                  },
                ),
    );
  }
}