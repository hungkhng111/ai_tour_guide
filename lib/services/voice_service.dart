import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
//import 'dart:io';
class VoiceService {
    final SpeechToText _speechToText = SpeechToText();
    final FlutterTts _flutterTts = FlutterTts();

    bool _isSpeechInitialized = false;

    Future<void> initVoice() async {
        try {
        _isSpeechInitialized = await _speechToText.initialize();
        
        // Cấu hình ngôn ngữ tiếng Việt cho Text-to-Speech
        await _flutterTts.setLanguage("vi-VN");
        await _flutterTts.setSpeechRate(0.5); // Tốc độ đọc vừa phải
        await _flutterTts.setPitch(0.5);
        await _flutterTts.setVolume(1);
        } catch (e) {
        // print("Lỗi khởi tạo âm thanh phần cứng: $e");
        _isSpeechInitialized = false;
        }
    }


    Future<void> startListening(Function(String) onResult, Function(bool) onStatusChanged, Function(String) onError) async {
        if (!_isSpeechInitialized) 
        {
            await initVoice(); // Gọi lại hàm khởi tạo nếu chưa có
        }   

        if (_isSpeechInitialized) 
        {
            // Chuan hoa cho android "_", ios "-"
            final String targetLocale = (defaultTargetPlatform == TargetPlatform.iOS) ? "vi-VN" : "vi_VN";

            // Dừng bot đọc nếu người dùng bắt đầu nói
            await stopSpeaking(); 
            onStatusChanged(true);

            await _speechToText.listen
            (
                onResult: (result) 
                {
                    if (result.finalResult) 
                    {
                        onResult(result.recognizedWords);
                        onStatusChanged(false); // Cập nhật UI ngưng trạng thái nghe
                    }
                },
                listenOptions: SpeechListenOptions(
                    localeId: targetLocale,
                    cancelOnError: true, // Tự động ngắt trạng thái nghe nếu có lỗi mạng/micro
                    listenMode: ListenMode.dictation, // Tối ưu cho việc đọc chính tả/câu dài
                )
            );
        } else 
        {
            onStatusChanged(false);
            onError("Chưa cấp quyền Micro hoặc thiết bị không hỗ trợ.");
            
        }
    }

    // ĐÃ SỬA: Đổi 'void' thành 'Future<void>'
    Future<void> stopListening(Function(bool) onStatusChanged) async {
        await _speechToText.stop();
        onStatusChanged(false);
    }

    // Luồng 3: Bot phát ra tiếng (TTS)
    Future<void> speak(String text) async {
        if (text.isNotEmpty) {
        await _flutterTts.speak(text);
        }
    }

    // Luồng 4: Dừng bot phát tiếng
    Future<void> stopSpeaking() async {
        await _flutterTts.stop();
    }

}