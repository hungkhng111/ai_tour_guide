import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../exceptions/app_exception.dart';
import '../utils/app_logger.dart';

/// Bọc mọi HTTP call của app theo đúng Policy trong 10_API_Contract.md:
/// - Timeout: cứng 15s / request.
/// - Retry: tối đa 2 lần, CHỈ cho lỗi mạng (SocketException/TimeoutException),
///   KHÔNG retry theo status code (4xx/5xx coi là lỗi nghiệp vụ, không phải lỗi mạng).
///
/// Nhận `http.Client` qua constructor để dễ mock trong unit test
/// (xem 14_Testing.md: "Sử dụng mockito để giả lập Supabase và HTTP Client").
class AppHttpClient {
  /// Timeout mặc định cho các API "luôn online" (Weather, Supabase REST...).
  /// KHÔNG dùng hằng số này cho backend chạy trên Render free tier — server
  /// đó có thể "ngủ" sau ~15 phút không traffic, cold start mất tới ~60s.
  /// Với các endpoint kiểu đó, truyền `timeout` riêng dài hơn ở mỗi lời gọi
  /// (xem AIService._chatTimeout).
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const int maxRetries = 2;

  final http.Client _client;

  AppHttpClient({http.Client? client}) : _client = client ?? http.Client();

  /// GET — idempotent theo bản chất, luôn được retry tự động.
  Future<http.Response> get(Uri url, {Map<String, String>? headers, Duration? timeout}) {
    final effectiveTimeout = timeout ?? defaultTimeout;
    return _sendWithRetry(
      () => _client.get(url, headers: headers).timeout(effectiveTimeout),
      retryable: true,
      timeout: effectiveTimeout,
    );
  }

  /// POST — mặc định KHÔNG retry, vì phần lớn endpoint POST trong app này
  /// (vd /chat) không idempotent: gửi lại có thể tạo hành động trùng lặp
  /// ở phía server. Chỉ set retryable=true khi bạn CHẮC CHẮN endpoint đó
  /// an toàn để gọi lại (server có cơ chế dedup theo request_id chẳng hạn).
  ///
  /// Truyền `timeout` riêng cho các endpoint chạy trên hạ tầng có cold start
  /// (Render free tier) — đừng dùng defaultTimeout 15s cho chúng.
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool retryable = false,
    Duration? timeout,
  }) {
    final effectiveTimeout = timeout ?? defaultTimeout;
    return _sendWithRetry(
      () => _client.post(url, headers: headers, body: body).timeout(effectiveTimeout),
      retryable: retryable,
      timeout: effectiveTimeout,
    );
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() request, {
    required bool retryable,
    required Duration timeout,
  }) async {
    int attempt = 0;
    final int allowedRetries = retryable ? maxRetries : 0;

    while (true) {
      try {
        return await request();
      } on SocketException catch (e) {
        attempt++;
        AppLogger.warn('Lỗi mạng (lần $attempt/${allowedRetries + 1}): $e');
        if (attempt > allowedRetries) {
          throw NetworkException('Mất kết nối mạng.', cause: e);
        }
      } on TimeoutException catch (e) {
        attempt++;
        AppLogger.warn('Timeout sau ${timeout.inSeconds}s (lần $attempt/${allowedRetries + 1})');
        if (attempt > allowedRetries) {
          throw NetworkException('Yêu cầu quá thời gian chờ (${timeout.inSeconds}s).', cause: e);
        }
      }
      // Backoff tăng dần trước khi thử lại: 500ms, 1000ms...
      await Future.delayed(Duration(milliseconds: 500 * attempt));
    }
  }

  void close() => _client.close();
}