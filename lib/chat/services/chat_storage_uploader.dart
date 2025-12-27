import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import '../models/chat_message.dart';

class ChatStorageUploader {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<ChatAttachment> uploadSingle({
    required String tenantId,
    required String conversationId,
    required String messageTempId,
    required ChatAttachment localAttachment,
  }) async {
    // localAttachment.url currently holds the local file path from picker
    final file = File(localAttachment.url);

    final fileName = localAttachment.name;
    final ext = p.extension(fileName);
    final cleanName = fileName.isEmpty
        ? 'file${DateTime.now().millisecondsSinceEpoch}$ext'
        : fileName;

    final path =
        'tenants/$tenantId/chats/$conversationId/$messageTempId/$cleanName';

    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(contentType: localAttachment.mimeType);

    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask.whenComplete(() => null);

    final downloadUrl = await snapshot.ref.getDownloadURL();

    final size = await file.length();

    return ChatAttachment(
      url: downloadUrl,
      name: cleanName,
      mimeType: localAttachment.mimeType,
      sizeBytes: size,
      compressed: localAttachment.compressed,
    );
  }

  static Future<List<ChatAttachment>> uploadAll({
    required String tenantId,
    required String conversationId,
    required List<ChatAttachment> localAttachments,
  }) async {
    final tempMessageId =
        'temp_${DateTime.now().millisecondsSinceEpoch.toString()}';

    final uploaded = <ChatAttachment>[];

    for (final a in localAttachments) {
      final up = await uploadSingle(
        tenantId: tenantId,
        conversationId: conversationId,
        messageTempId: tempMessageId,
        localAttachment: a,
      );
      uploaded.add(up);
    }

    return uploaded;
  }
}
