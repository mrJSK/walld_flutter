import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_view/photo_view.dart';
import '../models/chat_message.dart';
import '../../task/utils/user_helper.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_attachment_service.dart';

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
                      if (widget.message.text != null &&
                          widget.message.text!.trim().isNotEmpty)
                        Text(
                          widget.message.text!,
                          style: TextStyle(
                            color: widget.isMe ? Colors.white : Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      if (widget.message.attachments.isNotEmpty)
                        const SizedBox(height: 6),
                      if (widget.message.attachments.isNotEmpty)
                        ...List.generate(
                          widget.message.attachments.length,
                          (index) => _AttachmentTile(
                            tenantId: widget.tenantId,
                            messageId: widget.message.id,
                            conversationId: '', // fill from parent shell if needed
                            attachment: widget.message.attachments[index],
                            attachmentIndex: index,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(widget.message.createdAt),
                        style: TextStyle(
                          color: widget.isMe ? Colors.white38 : Colors.white24,
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
class _AttachmentTile extends StatefulWidget {
  final String tenantId;
  final String conversationId;
  final String messageId;
  final ChatAttachment attachment;
  final int attachmentIndex;

  const _AttachmentTile({
    required this.tenantId,
    required this.conversationId,
    required this.messageId,
    required this.attachment,
    required this.attachmentIndex,
  });

  @override
  State<_AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends State<_AttachmentTile> {
  bool _downloading = false;
  double _progress = 0;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final path = await ChatAttachmentService.resolveLocalPath(
      tenantId: widget.tenantId,
      conversationId: widget.conversationId,
      messageId: widget.messageId,
      attachmentIndex: widget.attachmentIndex,
    );
    if (mounted) setState(() => _localPath = path);
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0;
    });

    try {
      final file = await ChatAttachmentService.downloadToLocal(
        tenantId: widget.tenantId,
        conversationId: widget.conversationId,
        messageId: widget.messageId,
        attachmentIndex: widget.attachmentIndex,
        attachment: widget.attachment,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) setState(() => _localPath = file.path);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _open() async {
  final path = _localPath;
  if (path == null) return;
  final mime = widget.attachment.mimeType;
  
  if (mime.startsWith('image')) {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Image viewer
            PhotoView(
              imageProvider: FileImage(File(path)),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  } else if (mime == 'application/pdf') {
    // PLATFORM CHECK: Only use PDFView on mobile
    if (Platform.isAndroid || Platform.isIOS) {
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              // PDF viewer (mobile only)
              PDFView(
                filePath: path,
              ),
              // Close button
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // On Windows/macOS/Linux - use system default PDF viewer
      await OpenFilex.open(path);
    }
  } else {
    // For all other file types, use system default
    await OpenFilex.open(path);
  }
}


  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    final hasLocal = _localPath != null;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(
            a.mimeType.startsWith('image/')
                ? Icons.image
                : a.mimeType == 'application/pdf'
                    ? Icons.picture_as_pdf
                    : Icons.insert_drive_file,
            color: Colors.cyanAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(a.sizeBytes / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                if (_downloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 3,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.cyanAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _downloading
                ? null
                : hasLocal
                    ? _open
                    : _download,
            child: Text(
              hasLocal ? 'Open' : 'Download',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
