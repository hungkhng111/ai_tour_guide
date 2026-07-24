import 'package:flutter/foundation.dart';

/// Logger tối giản, thay thế toàn bộ print()/debugPrint() rải rác trong code
/// (xem 12_Coding_Convention.md / Review Checklist: "Không còn print() trong code").
/// Chỉ in ra khi chạy debug (kDebugMode) — không log gì ở bản release.
class AppLogger {
  static void info(String message) {
    if (kDebugMode) debugPrint('ℹ️ [INFO] $message');
  }

  static void warn(String message) {
    if (kDebugMode) debugPrint('⚠️ [WARN] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR] $message${error != null ? ' | $error' : ''}');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
    // TODO (Phase sau, không thuộc scope Phase 1): gửi lỗi lên Crashlytics/Sentry
    // nếu team quyết định thêm crash reporting.
  }
}