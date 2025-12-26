// lib/chat/widgets/chat_input_bar.dart

import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  final bool enabled;
  final String hintText;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.enabled = true,
    this.hintText = 'Type a message',
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || !widget.enabled) return;

    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: widget.enabled && !_sending,
            style: const TextStyle(color: Colors.white),
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: Colors.cyanAccent, width: 1.5),
              ),
            ),
            onSubmitted: (_) => _handleSend(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.enabled && !_sending ? _handleSend : null,
          icon: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.cyanAccent),
          tooltip: 'Send',
        ),
      ],
    );
  }
}
