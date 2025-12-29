import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_view/photo_view.dart';
import '../models/chat_message.dart';
import '../../task/utils/user_helper.dart';
import 'dart:io';
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

  /// Helper: Forces long strings to wrap by inserting zero-width spaces
  String _breakLongLines(String text, int limit) {
    final words = text.split(' ');
    final List<String> processedWords = [];

    for (var word in words) {
      if (word.length > limit) {
        final StringBuffer buffer = StringBuffer();
        for (int i = 0; i < word.length; i++) {
          buffer.write(word[i]);
          if ((i + 1) % limit == 0 && i != word.length - 1) {
            buffer.write('\u{200B}'); // Zero-width space
          }
        }
        processedWords.add(buffer.toString());
      } else {
        processedWords.add(word);
      }
    }
    return processedWords.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 🔥 FIXED: Exactly 60% of the screen width
    final maxBubbleWidth = screenWidth * 0.6; 

    final processedText = widget.message.text != null 
        ? _breakLongLines(widget.message.text!, 51) 
        : "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        // Align Right for Me, Left for Others
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (left for others)
          if (!widget.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.cyan.withOpacity(0.2),
              child: Text(
                UserHelper.getUserInitials(senderName ?? 'U'),
                style: const TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 🔥 FIXED: Flexible prevents crash, ConstrainedBox limits to 60%
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Column(
                crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name (only received messages)
                  if (!widget.isMe) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 2),
                      child: isLoadingName
                          ? const SizedBox(
                              height: 10, width: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1, valueColor: AlwaysStoppedAnimation(Colors.white38),
                              ),
                            )
                          : Text(
                              senderName ?? 'Loading...',
                              style: const TextStyle(
                                color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],

                  // MAIN BUBBLE CONTAINER
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                      color: widget.isMe ? Colors.cyan.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
                        bottomRight: Radius.circular(widget.isMe ? 4 : 18),
                      ),
                      border: Border.all(
                        color: widget.isMe ? Colors.cyan.withOpacity(0.4) : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. TEXT CONTENT
                        if (processedText.isNotEmpty)
                          Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4), 
                                child: RichText(
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: processedText,
                                        style: TextStyle(
                                          color: widget.isMe ? Colors.white : Colors.white70,
                                          fontSize: 14,
                                          height: 1.3,
                                        ),
                                      ),
                                      // Invisible padding for timestamp
                                      const TextSpan(
                                        text: "      \u200B\u200B\u200B\u200B\u200B\u200B   ",
                                        style: TextStyle(fontSize: 12, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(widget.message.createdAt),
                                      style: TextStyle(
                                        color: widget.isMe ? Colors.white60 : Colors.white38,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.isMe) ...[
                                      const SizedBox(width: 3),
                                      Icon(Icons.done_all, size: 13, color: Colors.cyanAccent.withOpacity(0.8)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                        // 2. ATTACHMENTS
                        if (widget.message.attachments.isNotEmpty) ...[
                          if (processedText.isNotEmpty) const SizedBox(height: 8),
                          ...List.generate(
                            widget.message.attachments.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _AttachmentTile(
                                tenantId: widget.tenantId,
                                messageId: widget.message.id,
                                conversationId: '',
                                attachment: widget.message.attachments[index],
                                attachmentIndex: index,
                              ),
                            ),
                          ),
                          if (processedText.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(widget.message.createdAt),
                                      style: TextStyle(
                                        color: widget.isMe ? Colors.white60 : Colors.white38,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.isMe) ...[
                                      const SizedBox(width: 3),
                                      Icon(Icons.done_all, size: 13, color: Colors.cyanAccent.withOpacity(0.8)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Avatar (right for sent)
          if (widget.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.cyan.withOpacity(0.3),
              child: const Icon(Icons.person, size: 16, color: Colors.cyan),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _AttachmentTile extends StatefulWidget {
  final String tenantId, conversationId, messageId;
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
    setState(() => _downloading = true);
    try {
      final file = await ChatAttachmentService.downloadToLocal(
        tenantId: widget.tenantId,
        conversationId: widget.conversationId,
        messageId: widget.messageId,
        attachmentIndex: widget.attachmentIndex,
        attachment: widget.attachment,
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
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

    if (mime.startsWith('image/')) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PhotoView(imageProvider: FileImage(File(path))),
              Positioned(
                top: 16, right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (mime == 'application/pdf') {
      if (Platform.isAndroid || Platform.isIOS) {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                PDFView(filePath: path),
                Positioned(
                  top: 16, right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        await OpenFilex.open(path);
      }
    } else {
      await OpenFilex.open(path);
    }
  }

  String _breakLongFileName(String text, int limit) {
    final words = text.split(' ');
    final List<String> processedWords = [];

    for (var word in words) {
      if (word.length > limit) {
        final StringBuffer buffer = StringBuffer();
        for (int i = 0; i < word.length; i++) {
          buffer.write(word[i]);
          if ((i + 1) % limit == 0 && i != word.length - 1) {
            buffer.write('\u{200B}');
          }
        }
        processedWords.add(buffer.toString());
      } else {
        processedWords.add(word);
      }
    }
    return processedWords.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    final hasLocal = _localPath != null;
    final processedFileName = _breakLongFileName(a.name, 40);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                a.mimeType.startsWith('image/') ? Icons.image :
                a.mimeType == 'application/pdf' ? Icons.picture_as_pdf :
                Icons.insert_drive_file,
                color: Colors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              
              // 🔥 FIXED: Changed 'Expanded' to 'Flexible'
              // This ensures the bubble only grows as wide as the filename needs,
              // rather than forcing the bubble to take the full 60% width for small files.
              Flexible( 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      processedFileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(a.sizeBytes / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _downloading ? null : (hasLocal ? _open : _download),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _downloading ? 'Downloading...' : (hasLocal ? 'OPEN' : 'DOWNLOAD'),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_downloading)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 2,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Colors.cyanAccent),
              ),
            ),
        ],
      ),
    );
  }
}