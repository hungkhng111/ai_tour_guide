import 'package:flutter/material.dart';
import '../models/place_model.dart';
// import 'ai_chat_screen.dart';
import 'package:ai_tour_guide/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaceDetailScreen extends StatefulWidget {
  final PlaceModel place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  
  bool _isFavorite = false;
  bool _isAuthenticated = false;
  bool _isLoadingFavorite = false;
  final _authService = AuthService();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    int initialPage = widget.place.imgPaths.isNotEmpty 
        ? widget.place.imgPaths.length * 3000 
        : 0;
    _pageController = PageController(initialPage: initialPage);
    _checkAuthAndFavoriteStatus();
  }

  Future<void> _checkAuthAndFavoriteStatus() async {
    if (_authService.isAuthenticated) {
      setState(() => _isAuthenticated = true);
      final userId = _authService.currentUserId;
      if (userId == null) return;
      try {
        final data = await _supabase
            .from('user_favorites')
            .select()
            .eq('user_id', userId)
            .eq('place_id', widget.place.id) // Thay bằng ID hoặc Name của bạn
            .maybeSingle();
        if (data != null && mounted) {
          setState(() => _isFavorite = true);
        }
      } catch (e) {
        debugPrint('Lỗi tải trạng thái: $e');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;
    
    // Kiểm tra nhanh qua AuthService trước khi chạy các lệnh nặng
    if (!_authService.isAuthenticated) return;
    
    final userId = _authService.currentUserId;
    if (userId == null) return;

    setState(() => _isLoadingFavorite = true);

    try {
      if (_isFavorite) {
        // Hủy tim (Xóa khỏi DB)
        await _supabase
            .from('user_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('place_id', widget.place.id);
      } else {
        // Thả tim (Thêm vào DB)
        await _supabase.from('user_favorites').insert({
          'user_id': userId,
          'place_id': widget.place.id,
        });
      }
      
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), 
          onPressed: () => Navigator.pop(context)
        ),
        title: const Text('Quay lại', style: TextStyle(color: Colors.black, fontSize: 16)),
        titleSpacing: 0,
        actions: [
          if (_isAuthenticated) 
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.redAccent,
            ),
            onPressed: _toggleFavorite,  
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  child: widget.place.imgPaths.isEmpty 
                      ? const Center(child: Text('Chưa có hình ảnh'))
                      : PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index % widget.place.imgPaths.length;
                            });
                          },
                          itemBuilder: (context, index) {
                            final actualIndex = index % widget.place.imgPaths.length;
                            final imageUrl = widget.place.imgPaths[actualIndex];
                            
                            return GestureDetector(
                              onTap: () {
                                // 🟢 SỬ DỤNG PAGEROUTEBUILDER ĐỂ TẠO HIỆU ỨNG FADE (BỎ LƯỚT TỪ PHẢI SANG)
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    opaque: false, // Giúp nền trong suốt lúc đang phóng to
                                    transitionDuration: const Duration(milliseconds: 300),
                                    pageBuilder: (context, animation, secondaryAnimation) => FullScreenImageViewer(
                                      imgPaths: widget.place.imgPaths,
                                      initialIndex: actualIndex,
                                    ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                );
                              },
                              // 🟢 BỌC HERO ANIMATION CHO ẢNH Ở MÀN HÌNH CHI TIẾT
                              child: Hero(
                                tag: imageUrl, // Dùng chính link ảnh làm tag
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(color: Colors.redAccent),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // THANH CHẤM TRÒN (DOTS INDICATOR)
                if (widget.place.imgPaths.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.place.imgPaths.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index 
                                ? Colors.redAccent 
                                : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              )
                            ]
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.place.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 20, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text('Giờ mở cửa: ${widget.place.openHour}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(widget.place.description, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: Container(
      //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      //   decoration: BoxDecoration(
      //     color: Colors.white,
      //     boxShadow: [
      //       BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, -4)),
      //     ],
      //   ),
      //   child: SafeArea(
      //     child: ElevatedButton(
      //       onPressed: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //             builder: (context) => const AIChatScreen(), 
      //           ),
      //         );
      //       },
      //       style: ElevatedButton.styleFrom(
      //         backgroundColor: const Color(0xFFFF5C5C), 
      //         padding: const EdgeInsets.symmetric(vertical: 16),
      //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      //         elevation: 0,
      //       ),
      //       child: const Text(
      //         'Cần biết thêm? Trò chuyện ngay!',
      //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      //       ),
      //     ),
      //   ),
      // ),
    );
  }
}

// CLASS MÀN HÌNH XEM ẢNH TOÀN MÀN HÌNH
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imgPaths;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imgPaths,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    int initialPage = widget.imgPaths.isNotEmpty
        ? (widget.imgPaths.length * 3000) + widget.initialIndex
        : 0;
    _pageController = PageController(initialPage: initialPage);
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🟢 1. ĐỔI MÀU NỀN HƠI TRONG SUỐT ĐỂ KHI VUỐT SẼ NHÌN XUYÊN THẤU MÀN HÌNH DƯỚI
      backgroundColor: Colors.black.withValues(alpha: 0.9), 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imgPaths.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true, 
      
      // 🟢 2. BỌC TOÀN BỘ PAGEVIEW TRONG DISMISSIBLE
      body: Dismissible(
        key: const Key('image_viewer_dismiss'),
        // Cho phép vuốt theo chiều dọc (Cả lên và xuống đều được)
        direction: DismissDirection.vertical, 
        // 🟢 3. HÀNH ĐỘNG KHI VUỐT THÀNH CÔNG
        onDismissed: (direction) {
          Navigator.pop(context); 
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index % widget.imgPaths.length;
            });
          },
          itemBuilder: (context, index) {
            final actualIndex = index % widget.imgPaths.length;
            final imageUrl = widget.imgPaths[actualIndex];
            
            return InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Hero(
                tag: imageUrl,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}