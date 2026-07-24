/// Base exception cho toàn bộ app.
/// Dùng để tầng Controller (Phase 4) phân biệt được loại lỗi
/// và hiển thị đúng Error State cho UI (theo 20_Review_Checklist.md).
abstract class AppException implements Exception {
  final String message;
  final Object? cause;

  AppException(this.message, {this.cause});

  @override
  String toString() => message;
}

/// Lỗi mạng: mất kết nối, DNS fail, timeout sau khi đã retry hết số lần cho phép.
class NetworkException extends AppException {
  NetworkException(super.message, {super.cause});
}

/// Lỗi từ server trả về (status code không phải 2xx).
class ServerException extends AppException {
  final int? statusCode;
  ServerException(super.message, {this.statusCode, super.cause});
}

/// Lỗi do thiếu cấu hình (API key rỗng, .env thiếu key, v.v).
class ConfigException extends AppException {
  ConfigException(super.message, {super.cause});
}