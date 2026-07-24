import 'dart:convert';
import 'dart:async';
import 'package:ai_tour_guide/services/chat_stream.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/app_http_client.dart';
import '../core/exceptions/app_exception.dart';
import '../core/utils/app_logger.dart';
import 'chat_stream.dart';

class AIService {
  static const String _baseUrl = 'https://project-on-cloud-1.onrender.com';

  final AppHttpClient _http;

  static const Duration _chatTimeout = Duration(seconds: 70);


  // Inject được AppHttpClient (và qua đó là http.Client) để unit test dễ mock.
  AIService({AppHttpClient? httpClient}) : _http = httpClient ?? AppHttpClient();

  // New
  Map<String, String> _authHeader() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return {};
    return {'Authorization': 'Bearer ${session.accessToken}'};
  }

  Future<String> _extractErrorMessage(http.StreamedResponse response) async {
    try {
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      if (data is Map) {
        final msg = data['detail'] ?? data['content'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {
      // Body không phải JSON hợp lệ (vd lỗi 5xx từ hạ tầng, không phải từ app) -> bỏ qua
    }
    if (response.statusCode == 401) {
      return 'Bạn cần đăng nhập để dùng tính năng chat.';
    }
    return 'Server lỗi khi gửi tin nhắn.';
  }

  Future<void> wakeUp() async {
    try {
      await _http.get(Uri.parse(_baseUrl), timeout: _chatTimeout);
      AppLogger.info('Server AI đã sẵn sàng (hoặc vừa được đánh thức).');

    } catch(e) {
      AppLogger.warn('Không thể đánh thức trước server AI: $e');
    }
  }

  Stream<ChatStreamEvent> sendMessageStream(
    {
      required String userMessage,
      required String sessionId,
      required String requestId,
    }
  ) async* {
    final url = Uri.parse('$_baseUrl/chat');
    final client = http.Client();

    try {
      final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json; charset=UTF-8'
      ..headers.addAll(_authHeader())
      ..body = jsonEncode({
        'session_id': sessionId,
        'message': userMessage,
        'request_id': requestId,
      });

      final streamedResponse = await client.send(request).timeout(_chatTimeout);

      if(streamedResponse.statusCode != 200) {
        yield ChatError(await _extractErrorMessage(streamedResponse));
        return;
      }

      final lines = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.trim().isEmpty) continue;

        Map<String, dynamic> data;
        try {
          data = jsonDecode(line) as Map<String, dynamic>;
        } catch (e) {
          AppLogger.warn('Bỏ qua dòng không hợp lệ: $line');
          continue;
        }

        switch (data['type']) {
          case 'status':
            yield const ChatSearching();
          case 'token':
            yield ChatToken(data['content'] as String? ?? '');
          case 'done':
            yield const ChatDone();
          case 'cancelled':
            yield const ChatCancelled();
          case 'error':
            yield ChatError(data['content'] as String? ?? 'Đã có lỗi xảy ra.');
        }
      }
    } on TimeoutException {
      yield const ChatError('Kết nối quá thời gian chờ, bạn thử lại nhé');
    } catch (e, stack) {
      AppLogger.error('Lỗi không xác định khi stream chat', e, stack);
    } finally {
      client.close();
    }
  }


  /// Best-effort: hủy request đang chạy. Không throw ra ngoài vì đây là
  /// hành động "cố gắng dọn dẹp", lỗi ở đây không nên chặn UI của user.
  Future<void> cancelMessage(String requestId) async {
    final url = Uri.parse('$_baseUrl/cancel_chat');
    try {
      await _http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'request_id': requestId}),
        retryable: false,
        timeout: _chatTimeout,
      );
      AppLogger.info('Đã gửi lệnh hủy cho request: $requestId');
    } catch (e) {
      AppLogger.warn('Không thể gửi lệnh hủy cho request $requestId: $e');
    }
  }
}