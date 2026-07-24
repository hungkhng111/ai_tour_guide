sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

/// AI đang gọi tool tìm kiếm (Tavily), chưa có chữ để hiện.
class ChatSearching extends ChatStreamEvent {
  const ChatSearching();
}
 
/// Một mẩu chữ mới, nối dần vào bong bóng đang hiển thị.
class ChatToken extends ChatStreamEvent {
  final String text;
  const ChatToken(this.text);
}
 
/// Stream kết thúc bình thường, không có lỗi.
class ChatDone extends ChatStreamEvent {
  const ChatDone();
}
 
/// Đã bị dừng theo yêu cầu người dùng (server xác nhận qua /cancel_chat).
class ChatCancelled extends ChatStreamEvent {
  const ChatCancelled();
}
 
/// Có lỗi xảy ra, message là câu thân thiện có thể hiện thẳng cho khách.
class ChatError extends ChatStreamEvent {
  final String message;
  const ChatError(this.message);
}