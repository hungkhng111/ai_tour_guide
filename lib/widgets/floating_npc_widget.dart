import 'package:flutter/material.dart';

// 🟢 CLASS QUẢN LÝ OVERLAY TOÀN CỤC
class FloatingNPCManager {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context) {
    if (_overlayEntry != null) return; // Đã hiển thị rồi thì không tạo thêm
    
    _overlayEntry = OverlayEntry(
      builder: (context) => const FloatingNPCWidget(),
    );
    
    // Chèn NPC lên lớp cao nhất của màn hình
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// 🟢 GIAO DIỆN VÀ LOGIC CỦA NPC
class FloatingNPCWidget extends StatefulWidget {
  const FloatingNPCWidget({super.key});

  @override
  State<FloatingNPCWidget> createState() => _FloatingNPCWidgetState();
}

class _FloatingNPCWidgetState extends State<FloatingNPCWidget> with SingleTickerProviderStateMixin {
  // Tọa độ ban đầu (Góc dưới bên phải)
  double _left = 300;
  double _top = 600;

  // Animation cho hiệu ứng "Trôi nổi" (Lên xuống nhẹ nhàng)
  late AnimationController _animationController;
  late Animation<double> _floatingAnimation;

  // Trạng thái hội thoại
  String _message = "Chào bạn! Cần hướng dẫn gì cứ bấm mic nhé!";
  bool _showMessage = true;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    // Thiết lập hiệu ứng trôi nổi liên tục
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Lặp lại liên tục (Lên -> Xuống -> Lên)

    _floatingAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Tự động ẩn lời chào sau 5 giây
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showMessage = false);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Cập nhật vị trí khi người dùng vuốt kéo NPC
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _left += details.delta.dx;
      _top += details.delta.dy;
      _showMessage = false; // Vuốt thì ẩn khung chat đi cho gọn
    });
  }

  // Giới hạn NPC không bị kéo văng ra khỏi màn hình
  void _onPanEnd(DragEndDetails details) {
    final size = MediaQuery.of(context).size;
    setState(() {
      if (_left < 0) _left = 10;
      if (_left > size.width - 80) _left = size.width - 80;
      if (_top < 50) _top = 50;
      if (_top > size.height - 100) _top = size.height - 100;
    });
  }

  // Xử lý khi bấm nút Micro
  void _toggleVoiceChat() {
    setState(() {
      _isRecording = !_isRecording;
      _showMessage = true;
      _message = _isRecording ? "Đang nghe..." : "Bạn vừa nói gì cơ?";
    });

    // 🟢 Ở ĐÂY SAU NÀY BẠN GỌI VOICE SERVICE ĐỂ GHI ÂM VÀ CHUYỂN SANG TEXT
    if (!_isRecording) {
      // Giả lập NPC trả lời sau khi ghi âm xong
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _message = "Mở danh sách yêu thích cho bạn nhé!";
            // Tự động ẩn sau 3s
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) setState(() => _showMessage = false);
            });
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phải bọc trong Material vì nó nằm ngoài Scaffold (ở lớp Overlay)
    return Positioned(
      left: _left,
      top: _top,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTap: () {
            setState(() {
              _showMessage = !_showMessage;
              _message = "Xin chào, tôi là Hướng dẫn viên ảo!";
            });
          },
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: child,
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🟢 1. KHUNG CHAT (Bong bóng thoại)
                if (_showMessage)
                  Container(
                    width: 140,
                    margin: const EdgeInsets.only(bottom: 50, right: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15).copyWith(bottomRight: const Radius.circular(0)),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: Text(
                      _message,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),

                // 🟢 2. KHỐI NPC VÀ MICRO
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Hình đại diện NPC (Bạn có thể thay bằng file GIF 3D hoặc Icon)
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.shade50,
                        border: Border.all(color: Colors.teal, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _isRecording ? Colors.redAccent.withValues(alpha: 0.5) : Colors.black26,
                            blurRadius: _isRecording ? 15 : 8,
                            spreadRadius: _isRecording ? 5 : 0,
                          )
                        ],
                        image: const DecorationImage(
                          // Đổi thành link avatar xịn xò của trợ lý ảo của bạn
                          image: NetworkImage('https://api.dicebear.com/7.x/bottts/png?seed=guide'), 
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Nút Micro thu nhỏ đính kèm
                    Positioned(
                      bottom: -5,
                      right: -5,
                      child: GestureDetector(
                        onTap: _toggleVoiceChat,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.redAccent : Colors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            _isRecording ? Icons.mic : Icons.mic_none,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}