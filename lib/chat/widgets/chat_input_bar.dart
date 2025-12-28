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
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  List<ChatAttachment> _selectedFiles = [];
  static const int _maxBytesPerMessage = 10 * 1024 * 1024; // 10 MB

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ FIXED: Main send handler
  // Add this at the TOP of handleSend, sendTextOnly, sendFilesWithMessage
Future<void> _handleSend() async {
  debugPrint('🔘 [ChatInputBar] SEND BUTTON CLICKED');
  debugPrint('🔘 [ChatInputBar] enabled: ${widget.enabled}, sending: $_sending');
  debugPrint('🔘 [ChatInputBar] selectedFiles: ${_selectedFiles.length}');
  debugPrint('🔘 [ChatInputBar] text: "${_controller.text.trim()}"');
  
  if (!widget.enabled || _sending) {
    debugPrint('🔘 [ChatInputBar] BLOCKED: disabled or sending');
    return;
  }

  if (_selectedFiles.isNotEmpty) {
    debugPrint('🔘 [ChatInputBar] → sendFilesWithMessage');
    await _sendFilesWithMessage();
    return;
  }

  final text = _controller.text.trim();
  if (text.isNotEmpty) {
    debugPrint('🔘 [ChatInputBar] → sendTextOnly: "$text"');
    await _sendTextOnly(text);
  } else {
    debugPrint('🔘 [ChatInputBar] BLOCKED: no text or files');
  }
}

Future<void> _sendTextOnly(String text) async {
  debugPrint('📝 [ChatInputBar.sendTextOnly] START');
  setState(() => _sending = true);
  try {
    debugPrint('📝 [ChatInputBar.sendTextOnly] CALLING onSendText');
    await widget.onSendText(text);
    debugPrint('📝 [ChatInputBar.sendTextOnly] onSendText SUCCESS');
    _controller.clear();
  } catch (e, st) {
    debugPrint('❌ [ChatInputBar.sendTextOnly] ERROR: $e');
    debugPrint('📍 [ChatInputBar.sendTextOnly] STACK: $st');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.redAccent),
      );
    }
  } finally {
    if (mounted) setState(() => _sending = false);
    debugPrint('📝 [ChatInputBar.sendTextOnly] END');
  }
}


  Future<void> _sendFilesWithMessage() async {
    setState(() => _sending = true);

    try {
      debugPrint('📤 Sending ${_selectedFiles.length} file(s)...');
      
      final text = _controller.text.trim();
      await widget.onSendAttachments(
        attachments: _selectedFiles,
        text: text.isEmpty ? null : text,
      );

      // Clear after successful send
      _controller.clear();
      setState(() => _selectedFiles.clear());
      
      debugPrint('✅ Files sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send files: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickDocuments() async {
    if (!widget.enabled || _sending) return;

    try {
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Max 10 MB per message exceeded.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        final mime = lookupMimeType(path) ?? 'application/octet-stream';
        attachments.add(ChatAttachment(
          url: path, // local path, will be replaced after upload
          name: f.name,
          mimeType: mime,
          sizeBytes: size,
          compressed: false,
        ));
      }

      if (attachments.isEmpty) return;

      setState(() => _selectedFiles = attachments);
    } catch (e) {
      debugPrint('❌ Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick files: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // File preview section
        if (_selectedFiles.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _selectedFiles.length,
              itemBuilder: (context, index) {
                return _FilePreviewTile(
                  attachment: _selectedFiles[index],
                  onRemove: () => _removeFile(index),
                );
              },
            ),
          ),

        // Input row
        Row(
          children: [
            // Attach button (only show if no files selected)
            if (_selectedFiles.isEmpty)
              IconButton(
                onPressed: widget.enabled && !_sending ? _pickDocuments : null,
                icon: const Icon(Icons.add),
                color: Colors.white,
                tooltip: 'Attach',
              ),

            // Text field
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled && !_sending,
                style: const TextStyle(color: Colors.white),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _selectedFiles.isEmpty
                      ? widget.hintText
                      : 'Add a message (optional)',
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

            // Send button - ALWAYS enabled if files or text present
            // FIXED: Send button - Enable whenever input is enabled, not content-based
            IconButton(
              onPressed: widget.enabled && !_sending
                  ? () {
                      debugPrint('🚀 [SendButton] CLICK DETECTED - onPressed ACTIVE');
                      _handleSend();
                    }
                  : () {
                      debugPrint('🚫 [SendButton] CLICK BLOCKED - enabled: ${widget.enabled}, sending: $_sending');
                    },
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.cyanAccent,
                    ),
              tooltip: 'Send',
            ),


          ],
        ),
      ],
    );
  }
}

class _FilePreviewTile extends StatelessWidget {
  final ChatAttachment attachment;
  final VoidCallback onRemove;

  const _FilePreviewTile({
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          // File icon
          Icon(
            _getFileIcon(attachment.mimeType),
            color: Colors.cyanAccent,
            size: 28,
          ),
          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${(attachment.sizeBytes / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
            onPressed: onRemove,
            tooltip: 'Remove',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String mime) {
    if (mime.startsWith('image/')) return Icons.image;
    if (mime == 'application/pdf') return Icons.picture_as_pdf;
    if (mime.startsWith('video/')) return Icons.videocam;
    if (mime.startsWith('audio/')) return Icons.audiotrack;
    return Icons.insert_drive_file;
  }
}
