import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/chat_message.dart';

class ChatStorageUploader {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Ensure user is authenticated before upload
  static Future<void> _ensureAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔐 Signing in anonymously...');
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint('✅ Authenticated: ${FirebaseAuth.instance.currentUser?.uid}');
    }
  }

  static Future<ChatAttachment> uploadSingle({
    required String tenantId,
    required String conversationId,
    required String messageTempId,
    required ChatAttachment localAttachment,
  }) async {
    await _ensureAuth(); // ✅ Force auth

    try {
      final localPath = localAttachment.url;
      debugPrint('📁 Uploading: $localPath');

      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('❌ File missing: $localPath');
      }

      final fileName = localAttachment.name;
      final ext = p.extension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_'); // Sanitize
      final storagePath = 'tenants/$tenantId/chats/$conversationId/$messageTempId/$cleanName';

      debugPrint('☁️ Path: $storagePath');

      final ref = _storage.ref().child(storagePath);
      
      // ✅ Delete if exists (race condition fix)
      try {
        await ref.delete();
        debugPrint('🗑️ Cleared existing file');
      } catch (e) {
        debugPrint('ℹ️ No existing file to delete');
      }

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: localAttachment.mimeType),
      );

      // ✅ Simple await - NO listeners (fixes threading)
      final snapshot = await uploadTask;
      debugPrint('📈 Upload state: ${snapshot.state}');

      if (snapshot.state != TaskState.success) {
        throw Exception('❌ Upload failed: ${snapshot.state}');
      }

      // ✅ Wait + verify file exists before getting URL
      await Future.delayed(const Duration(seconds: 1));
      
      // ✅ List files to verify upload
      final listResult = await ref.parent!.listAll();
      debugPrint('📂 Files in parent: ${listResult.items.length}');
      
      if (!listResult.items.any((item) => item.fullPath == storagePath)) {
        throw Exception('❌ File not found in storage after upload');
      }

      // ✅ Get download URL with retry
      String? downloadUrl;
      for (int i = 0; i < 5; i++) {
        try {
          downloadUrl = await ref.getDownloadURL();
          debugPrint('✅ URL got: ${downloadUrl.substring(0, 50)}...');
          break;
        } catch (e) {
          debugPrint('⚠️ URL attempt ${i + 1}/5 failed: $e');
          await Future.delayed(Duration(milliseconds: 800 * (i + 1)));
        }
      }

      if (downloadUrl == null) {
        throw Exception('❌ Failed to get download URL after 5 attempts');
      }

      return ChatAttachment(
        url: downloadUrl,
        name: cleanName,
        mimeType: localAttachment.mimeType,
        sizeBytes: await file.length(),
        compressed: localAttachment.compressed,
      );
    } catch (e, st) {
      debugPrint('💥 FULL ERROR: $e');
      debugPrint('Stack: $st');
      rethrow;
    }
  }

  static Future<List<ChatAttachment>> uploadAll({
    required String tenantId,
    required String conversationId,
    required List<ChatAttachment> localAttachments,
  }) async {
    final tempMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final uploaded = <ChatAttachment>[];

    for (int i = 0; i < localAttachments.length; i++) {
      try {
        final up = await uploadSingle(
          tenantId: tenantId,
          conversationId: conversationId,
          messageTempId: tempMessageId,
          localAttachment: localAttachments[i],
        );
        uploaded.add(up);
      } catch (e) {
        debugPrint('❌ Upload ${i + 1} failed: $e');
        rethrow; // Stop on first failure
      }
    }

    return uploaded;
  }
}
