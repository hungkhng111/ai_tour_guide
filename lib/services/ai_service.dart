import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // ⚠️ LƯU Ý QUAN TRỌNG VỀ ĐỊA CHỈ IP:
  // - Nếu bạn chạy trên Máy ảo Android (Emulator), localhost của máy tính được đại diện bằng IP: 10.0.2.2
  // - Nếu bạn chạy trên Máy ảo iOS (Simulator) hoặc Web, hãy dùng: 127.0.0.1 hoặc localhost
  // - Nếu bạn cắm cáp chạy điện thoại thật, hãy dùng IP LAN của máy tính (VD: 192.168.1.x)
  static const String _baseUrl = 'http://10.0.2.2:8000'; 

  Future<String> sendMessage(String userMessage, String sessionId) async {
    try {
      // 1. Gửi cục JSON { "message": "..." } sang máy chủ Python
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'session_id': sessionId,
          'message': userMessage,
        }),
      );

      // 2. Nhận kết quả và bóc tách
      if (response.statusCode == 200) {
        // Cần utf8.decode để tránh lỗi font tiếng Việt
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Trả về đúng trường "reply" mà Python đã gửi sang
        return data['reply'];
      } else {
        throw Exception('Lỗi từ Server Python. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến AI. Vui lòng kiểm tra lại mạng: $e');
    }
  }
}