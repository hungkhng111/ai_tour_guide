import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../widgets/vertical_place_card.dart';
import '../repositories/place_repository.dart';
import '../services/weather_service.dart';
import 'package:ai_tour_guide/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🛠️ 1. Chuyển thành StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Khởi tạo Nhà kho
  final PlaceRepository repository = PlaceRepository();
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  // 🛠️ 2. Tạo một biến để lưu trữ kết quả tải dữ liệu (Chỉ tải 1 lần)
  // late Future<List<PlaceModel>> _placesFuture;
  // Bien quan ly thoi tiet
  late Future<Map<String, dynamic>> _weatherFuture;
  
  bool _isLoadingPlaces = true;
  List<PlaceModel> _allPlaces = []; // Danh sách gốc (Chứa toàn bộ data)
  List<PlaceModel> _filteredPlaces = []; // Danh sách hiển thị trên UI
  String _currentFilter = 'Mặc định';


  @override
  void initState() {
    super.initState();
    // 🛠️ 3. Gọi dữ liệu ngay khi vừa mở màn hình (Chỉ chạy 1 lần duy nhất)
    // _placesFuture = repository.getPlaces();
    _weatherFuture = WeatherService().getCurrentWeather();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await repository.getPlaces();
      if (mounted) {
        setState(() {
          _allPlaces = places;
          _filteredPlaces = List.from(_allPlaces); // Khởi tạo ban đầu: copy nguyên gốc
          _isLoadingPlaces = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu: $e');
      if (mounted) setState(() => _isLoadingPlaces = false);
    }
  }

  Future<void> _applyFilter() async {
    if (_currentFilter == 'Mặc định') {
      // TRẢ VỀ BAN ĐẦU: Xóa hết bộ lọc, copy lại toàn bộ từ danh sách gốc
      setState(() {
        _filteredPlaces = List.from(_allPlaces);
      });
    } 
    else if (_currentFilter == 'Theo tên') {
      // SẮP XẾP A-Z: Copy từ danh sách gốc và dùng hàm sort
      setState(() {
        _filteredPlaces = List.from(_allPlaces)
          ..sort((a, b) => a.name.compareTo(b.name));
      });
    } 
    else if (_currentFilter == 'Yêu thích') {
      // YÊU THÍCH: Kiểm tra đăng nhập trước
      if (!_authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để xem danh sách yêu thích!')),
        );
        // Trả Dropdown về lại Mặc định nếu chưa đăng nhập
        setState(() {
          _currentFilter = 'Mặc định';
          _filteredPlaces = List.from(_allPlaces);
        });
        return;
      }

      final userId = _authService.currentUserId;
      if (userId == null) return;

      try {
        // 1. Gọi lên Supabase lấy danh sách các place_id mà user này đã thả tim
        final response = await _supabase
            .from('user_favorites')
            .select('place_id')
            .eq('user_id', userId);

        // 2. Chuyển đổi data JSON thành 1 mảng các String (List<String>)
        final favoriteIds = response.map((e) => e['place_id'] as String).toList();

        // 3. Lọc danh sách gốc: Chỉ giữ lại những địa điểm có ID nằm trong mảng favoriteIds
        setState(() {
          _filteredPlaces = _allPlaces.where((place) => favoriteIds.contains(place.id)).toList();
        });
      } catch (e) {
        debugPrint('Lỗi tải danh sách yêu thích: $e');
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(content: Text('Lỗi: $e')),
        //   );
        // }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Khám phá Vĩnh Long', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. PHẦN THỜI TIẾT (Giữ nguyên FutureBuilder vì nó độc lập, không cần lọc)
            FutureBuilder<Map<String, dynamic>>(
              future: _weatherFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: double.infinity, height: 200, margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20)),
                    child: const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text('Lỗi thời tiết: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                final data = snapshot.data!;
                final String cityName = data['name'];
                final int temp = data['main']['temp'].round();
                final String description = data['weather'][0]['description'];
                final int tempMax = data['main']['temp_max'].round();
                final int tempMin = data['main']['temp_min'].round();
                final String capitalizedDesc = "${description[0].toUpperCase()}${description.substring(1)}";

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1534088568595-a066f410bcda?q=80&w=600&auto=format&fit=crop'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('CHÀO MỪNG BẠN ĐẾN VỚI', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(cityName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      Text('$temp°', style: const TextStyle(color: Colors.white, fontSize: 76, fontWeight: FontWeight.w200, height: 1.1)),
                      const SizedBox(height: 2),
                      Text(capitalizedDesc, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('C:$tempMax°  T:$tempMin°', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              },
            ),
            
            // ==========================================
            // 2. KHU VỰC BỘ LỌC (Đã mở comment và làm đẹp UI)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Danh sách địa điểm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentFilter,
                        icon: const Icon(Icons.sort, color: Colors.redAccent, size: 20),
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                        items: ['Mặc định', 'Theo tên', 'Yêu thích'].map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _currentFilter = newValue;
                              _applyFilter();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ==========================================
            // 3. DANH SÁCH ĐỊA ĐIỂM (Đã loại bỏ FutureBuilder)
            _isLoadingPlaces 
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                )
              : _filteredPlaces.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('Không có địa điểm nào phù hợp.')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredPlaces.length, // SỬ DỤNG DANH SÁCH ĐÃ LỌC
                    itemBuilder: (context, index) {
                      return VerticalPlaceCard(place: _filteredPlaces[index]);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}