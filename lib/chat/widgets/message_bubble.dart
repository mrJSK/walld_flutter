// lib/chat/widgets/message_bubble.dart

import 'package:flutter/material.dart';

import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isMine
        ? Colors.cyanAccent.withOpacity(0.18)
        : Colors.white.withOpacity(0.06);
    final borderColor =
        isMine ? Colors.cyanAccent.withOpacity(0.7) : Colors.white12;
    final align =
        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: align,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.progress)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'Progress update',
                  style: TextStyle(
                    color: Colors.greenAccent.shade200,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (message.fileUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_file,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      message.fileType ?? 'file',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            if (message.text != null && message.text!.isNotEmpty)
              Text(
                message.text!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
