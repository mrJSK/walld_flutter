import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../../task/utils/user_helper.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final String tenantId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.tenantId,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String? senderName;
  bool isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadSenderName();
  }

  Future<void> _loadSenderName() async {
    final name = await UserHelper.getUserDisplayName(
      tenantId: widget.tenantId,
      userId: widget.message.senderId,
    );

    if (mounted) {
      setState(() {
        senderName = name;
        isLoadingName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar for other users (left side)
          if (!widget.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.cyan.withOpacity(0.2),
              child: Text(
                UserHelper.getUserInitials(senderName ?? 'U'),
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: widget.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Sender name (only for other users)
                if (!widget.isMe) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: isLoadingName
                        ? const SizedBox(
                            height: 10,
                            width: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation(Colors.white38),
                            ),
                          )
                        : Text(
                            senderName ?? 'Loading...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],

                // Message container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Colors.cyan.withOpacity(0.2)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                      bottomRight: Radius.circular(widget.isMe ? 4 : 16),
                    ),
                    border: Border.all(
                      color: widget.isMe
                          ? Colors.cyan.withOpacity(0.4)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      Text(
                        widget.message.text ?? '',
                        style: TextStyle(
                          color: widget.isMe ? Colors.white : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Timestamp
                      Text(
                        _formatTime(widget.message.createdAt),
                        style: TextStyle(
                          color: widget.isMe
                              ? Colors.white38
                              : Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Avatar for current user (right side)
          if (widget.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.cyan.withOpacity(0.3),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.cyan,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
