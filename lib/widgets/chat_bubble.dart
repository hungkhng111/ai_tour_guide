import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final Widget? childWidget;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.childWidget,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSystemMessage = message == "[Bạn đã dừng câu trả lời này...]";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal.withValues(alpha: 0.8) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 12),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : (isSystemMessage ? Colors.black38 : Colors.black87),
                fontSize: 15,
                fontStyle: isSystemMessage ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            ?childWidget,
          ],
        ),
        
      ),
    );
  }
}