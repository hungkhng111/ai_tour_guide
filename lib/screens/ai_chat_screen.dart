import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Thêm dòng này để dùng Supabase Stream
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/chat_stream.dart';
import '../services/voice_service.dart';
import '../services/auth_service.dart';
import '../widgets/chat_bubble.dart';
import 'dart:math' as math;
import 'package:get/get.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with SingleTickerProviderStateMixin
{
  late final StreamSubscription<AuthState> _authSubscription;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = Get.find<AIService>();

  // voice chat
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  
  // Kiem tra go chu
  bool _isTyping = false;

  late String _sessionId; 
  // Trang thai cho AI tra loi
  bool _isLoading = false;

  // Trang thai huy cau tra loi tu AI
  String _currentRequestId = "";
  // Them bien tao hieu ung micro rung
  late AnimationController _micAnimController;

  void _resetChat() {
    setState(() {
      _messages.clear();
      _sessionId = "user_${DateTime.now().millisecondsSinceEpoch}";
      _messages.add(ChatMessage.fromAI(
        'Dạ chào bạn! Mình là hướng dẫn viên ảo tại Vĩnh Long. '
        'Bạn đang muốn tìm địa điểm vui chơi hay thưởng thức món ngon nào ở quê mình thế?',
      ));
    });
  }
  @override
  void initState() {
    super.initState();
    _resetChat();
    // Lang nghe an toan
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if(!mounted) return;
      final event = data.event;
      if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.signedIn) {
        // Doi widget ve xong khung chat thi moi tha loi chao vao
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resetChat();
        });
      }
    });

    // micro rung 400ms/nhip
    _micAnimController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 400)
    );
  }



  void _sendMessage(String messageText) async {
    final text = messageText.trim();
    if (text.isEmpty || _isLoading) return;
    final String myRequestId = "req_${DateTime.now().millisecondsSinceEpoch}";

    // Bong bóng trả lời của AI, tạo rỗng trước rồi lấp dần từng chữ vào
    final ChatMessage aiMessage = ChatMessage.fromAI('');
    const searchingPlaceholder = 'Đang tra cứu thông tin...';

    setState(() {
      _currentRequestId = myRequestId;
      _messages.add(ChatMessage.fromUser(text));
      _messages.add(aiMessage);
      _isLoading = true;
      _isTyping = false;
    });

    _controller.clear();
    _scrollToBottom();

    // Helper: chỉ áp dụng cập nhật nếu đây vẫn là request đang được theo dõi
    // (tránh trường hợp người dùng đã gửi câu hỏi khác hoặc widget đã dispose)
    bool isStale() => !mounted || _currentRequestId != myRequestId;

    final stream = _aiService.sendMessageStream(
      userMessage: text,
      sessionId: _sessionId,
      requestId: myRequestId,
    );

    await for (final event in stream) {
      switch (event) {
        case ChatSearching():
          if (isStale() || aiMessage.content.isNotEmpty) break;
          setState(() => aiMessage.content = searchingPlaceholder);
        case ChatToken(text: final token):
          if (isStale()) break;
          setState(() {
            if (aiMessage.content == searchingPlaceholder) {
              aiMessage.content = ''; // xóa placeholder khi chữ thật bắt đầu về
            }
            aiMessage.content += token;
          });
          _scrollToBottom();

        case ChatDone():
          if (isStale()) break;
          if (aiMessage.content.isNotEmpty) {
            _voiceService.speak(aiMessage.content);
          }
          setState(() => _isLoading = false);

        case ChatCancelled():
          // Cố ý KHÔNG check isStale(): _stopGenerating() đã reset _currentRequestId
          // về "" trước khi gọi hủy, nên isStale() luôn true ở đây — cần xử lý riêng.
          if (!mounted) break;
          setState(() {
            if (aiMessage.content.isEmpty || aiMessage.content == searchingPlaceholder) {
              aiMessage.content = "[Bạn đã dừng câu trả lời này...]";
            }
            _isLoading = false;
          });

        case ChatError(message: final message):
          if (isStale()) break;
          setState(() {
            aiMessage.content = message;
            _isLoading = false;
          });
      }
    }
  }
  // void _startVoiceChat() async {
  //   if (_isListening) {

  //   }
  // }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stopGenerating() {
    final String cancelledReqId = _currentRequestId;
    setState(() {
      _currentRequestId = ""; // "Cắt cầu": token mới về sau thời điểm này bị bỏ qua
      _isLoading = false;     // phản hồi UI ngay, không đợi server xác nhận hủy
    });

    _voiceService.stopSpeaking();
    _aiService.cancelMessage(cancelledReqId);
    // Bong bóng AI sẽ tự cập nhật thành "[Bạn đã dừng câu trả lời này...]"
    // khi callback onCancelled trong _sendMessage() nhận được xác nhận từ server.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip AIssistant')),
      // 🛠️ DÙNG STREAMBUILDER ĐỂ TỰ ĐỘNG LẮNG NGHE SUPABASE
      body: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Kiểm tra xem đã đăng nhập chưa
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const Scaffold(
          //     body: Center (child: CircularProgressIndicator()),
          //   );
          // }
          final session = Supabase.instance.client.auth.currentSession;
          final isLoggedIn = session != null;

          return Column(
            children: [
              // Khu vực hiển thị tin nhắn (giữ nguyên)
              Expanded(child: _buildMessageList()), 
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bạn đợi xíu nhé...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // InkWell(
                      //   onTap: _stopGenerating,
                      //   borderRadius: BorderRadius.circular(15),
                      //   child: Container(
                      //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      //     decoration: BoxDecoration(
                      //       color: Colors.red.shade50,
                      //       borderRadius: BorderRadius.circular(15),
                      //       border: Border.all(color: Colors.red.shade200),
                      //     ),
                      //     // child: Row(
                      //     //   children: [
                      //     //     Icon(Icons.stop_circle, color: Colors.red.shade400, size: 16),
                      //     //     const SizedBox(width: 4),
                      //     //     // Text('Dừng', style: TextStyle(color: Colors.red.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                      //     //   ],
                      //     // ),
                      //   ),
                      // )
                    ],
                  ),
                ),
              // Khu vực Input thay đổi tự động theo trạng thái
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ]
                ),
                child: isLoggedIn 
                    ? _buildChatInputArea() 
                    : _buildLoginPrompt(), // Trạng thái chưa login
              ),
            ],
          );
        }
      ),
    );
  }

  // HÀM VẼ DANH SÁCH TIN NHẮN
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final currentMessage = _messages[index];
        // ChatBubble của bạn sẽ lo việc vẽ UI tin nhắn
        return ChatBubble(
          message: currentMessage.content,
          isUser: currentMessage.isUser,
        ); 
      },
    );
  }

  // HÀM VẼ KHUNG CHAT KHI ĐÃ ĐĂNG NHẬP
  Widget _buildChatInputArea() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _controller,
              readOnly: _isLoading,
              decoration: const InputDecoration(
                hintText: 'Hỏi về địa điểm...',
                border: InputBorder.none,
              ),
              onChanged: (text) {
                // 🛠️ Kích hoạt trạng thái Gõ chữ để đổi icon
                setState(() {
                  _isTyping = text.isNotEmpty;
                });
              },
              // Nhan Enter tren ban phim ao dien thoai
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  _sendMessage(text);
                }
              },
            ),
          ),
        ),
        // const SizedBox(width: 8),
        // CircleAvatar(
        //   radius: 22,
        //   backgroundColor: Colors.teal,
        //   // 🔄 LỚP HOÁN ĐỔI 2: NÚT GỬI HOẶC NÚT MICRO
        //   child: _isTyping 
        //       ? IconButton(
        //           icon: const Icon(Icons.send, color: Colors.white, size: 20),
        //           onPressed: _sendMessage,
        //         )
        //       : IconButton(
        //           icon: const Icon(Icons.mic, color: Colors.white, size: 20),
        //           onPressed: _startVoiceChat,
        //         ),
        // ),
            // 🔄 LỚP HOÁN ĐỔI 3 TRẠNG THÁI (DỪNG - GỬI - MICRO)
        Container(
          margin: const EdgeInsets.only(left: 12),
          child: _isLoading 
            // TRẠNG THÁI 1: ĐANG LOAD -> HIỆN NÚT DỪNG
            ? IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 40),
              onPressed: _stopGenerating, // Gọi hàm hủy request
              )
            // NẾU KHÔNG LOAD, KIỂM TRA XEM CÓ CHỮ HAY KHÔNG
            : (_controller.text.isNotEmpty
                // TRẠNG THÁI 2: CÓ CHỮ -> HIỆN NÚT GỬI
                ? IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      _sendMessage(_controller.text);
                    },
                  )
                // TRẠNG THÁI 3: TRỐNG -> HIỆN NÚT MICRO
            : AnimatedBuilder(
                    animation: _micAnimController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, // Tạo nút tròn
                          // 🎨 Chuyển đỏ khi nghe, bình thường màu xám/teal nhạt
                          color: _isListening ? Colors.redAccent : Colors.grey.shade100, 
                        ),
                        child: IconButton(
                          // 🎬 HIỆU ỨNG RUNG VÀ PHẬP PHỒNG NHẸ
                          icon: Transform.rotate(
                            angle: _isListening ? (math.sin(_micAnimController.value * math.pi * 2) * 0.1) : 0.0,
                            child: Transform.scale(
                              scale: _isListening ? 1.0 + (_micAnimController.value * 0.15) : 1.0,
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? Colors.white : Colors.teal,
                              ),
                            ),
                          ),
                          onPressed: () {
                            if (_isListening) {
                              // 🔴 Dừng thu âm -> Tắt hiệu ứng
                              _micAnimController.stop();
                              _micAnimController.reset();
                              _voiceService.stopListening((status) {
                                setState(() => _isListening = status);
                              });
                            } else {
                              // 🟢 Bắt đầu thu âm -> Bật hiệu ứng rung liên tục
                              _micAnimController.repeat(); 
                              _voiceService.startListening(
                                (recognizedWords) {
                                  // Khi có text trả về thì tắt rung và gửi đi
                                  _micAnimController.stop();
                                  _micAnimController.reset();
                                  _sendMessage(recognizedWords);
                                },
                                (status) {
                                  setState(() {
                                    _isListening = status;
                                    if (!status) {
                                      // Tắt hiệu ứng nếu mic tự ngắt
                                      _micAnimController.stop();
                                      _micAnimController.reset();
                                    }
                                  });
                                },
                                (errorMessage) {
                                  _micAnimController.stop();
                                  _micAnimController.reset();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMessage)),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      );
                    }
                  )
              )
        )
        

      ],
    );
  }

  // HÀM VẼ YÊU CẦU ĐĂNG NHẬP
  Widget _buildLoginPrompt() {
    return InkWell(
      onTap: () => AuthService().signInWithGoogle(), // Gọi Service
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, color: Colors.teal), // Thay bằng logo Google nếu muốn
            SizedBox(width: 10),
            Text(
              'Đăng nhập để bắt đầu trò chuyện',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600, 
                color: Colors.black87
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _micAnimController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _voiceService.stopSpeaking();

    super.dispose();
  }




}