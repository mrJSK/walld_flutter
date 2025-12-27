import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import '../models/chat_message.dart';

typedef SendTextCallback = Future<void> Function(String text);
typedef SendAttachmentsCallback = Future<void> Function({
  required List<ChatAttachment> attachments,
  String? text,
});

class ChatInputBar extends StatefulWidget {
  final SendTextCallback onSendText;
  final SendAttachmentsCallback onSendAttachments;
  final bool enabled;
  final String hintText;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendAttachments,
    this.enabled = true,
    this.hintText = 'Type a message',
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController controller = TextEditingController();
  bool sending = false;

  static const int _maxBytesPerMessage = 10 * 1024 * 1024; // 10 MB

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    if (!widget.enabled || sending) return;

    setState(() => sending = true);
    try {
      await widget.onSendText(text);
      controller.clear();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _pickDocuments() async {
    if (!widget.enabled || sending) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    int totalBytes = 0;
    final attachments = <ChatAttachment>[];

    for (final f in result.files) {
      final path = f.path;
      if (path == null) continue;
      final file = File(path);
      final size = await file.length();
      totalBytes += size;
      if (totalBytes > _maxBytesPerMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max 10 MB per message exceeded.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final mime = lookupMimeType(path) ?? 'application/octet-stream';

      attachments.add(
        ChatAttachment(
          url: path, // temporary local path, will be replaced after upload
          name: f.name,
          mimeType: mime,
          sizeBytes: size,
          compressed: false,
        ),
      );
    }

    if (attachments.isEmpty) return;

    await widget.onSendAttachments(
      attachments: attachments,
      text: controller.text.trim().isEmpty ? null : controller.text.trim(),
    );
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: widget.enabled && !sending ? _pickDocuments : null,
          icon: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Attach',
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: widget.enabled && !sending,
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
          onPressed: widget.enabled && !sending ? _handleSend : null,
          icon: sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.cyanAccent),
          tooltip: 'Send',
        ),
      ],
    );
  }
}
