import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';  // ADD THIS
import '../models/chat_message.dart';

class ChatStorageUploader {
  static final FirebaseStorage storage = FirebaseStorage.instance;

  static Future<void> ensureAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("Signing in anonymously...");
      await FirebaseAuth.instance.signInAnonymously();
    }
    debugPrint("Authenticated: ${FirebaseAuth.instance.currentUser?.uid}");
  }

  /// Detect if file is an image
  static bool isImage(String mimeType) {
    return mimeType.startsWith('image/') && 
           (mimeType.contains('jpeg') || 
            mimeType.contains('jpg') || 
            mimeType.contains('png') || 
            mimeType.contains('webp'));
  }

  /// Detect if file is already compressed (don't re-compress)
  static bool isAlreadyCompressed(String mimeType) {
    return mimeType.startsWith('video/') ||
           mimeType.startsWith('audio/') ||
           mimeType == 'application/zip' ||
           mimeType == 'application/x-rar-compressed' ||
           mimeType == 'application/x-7z-compressed';
  }

  /// Compress IMAGE files (reduce quality/resolution)
  static Future<File> compressImage(File sourceFile, String mimeType) async {
    debugPrint("🖼️ Compressing image: ${sourceFile.path}");
    
    final originalSize = await sourceFile.length();
    final ext = p.extension(sourceFile.path).toLowerCase();
    final compressedPath = '${sourceFile.path}_compressed$ext';
    
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourceFile.absolute.path,
        compressedPath,
        quality: 70,  // 70% quality (good balance)
        minWidth: 1920,  // Max width 1920px
        minHeight: 1920,  // Max height 1920px
        format: ext == '.png' ? CompressFormat.png : CompressFormat.jpeg,
      );
      
      if (result == null) {
        debugPrint("⚠️ Image compression returned null, using original");
        return sourceFile;
      }
      
      final compressedSize = await result.length();
      final originalKB = originalSize / 1024;
      final compressedKB = compressedSize / 1024;
      final ratio = ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1);
      
      debugPrint("✅ Image compressed: ${originalKB.toStringAsFixed(1)} KB → ${compressedKB.toStringAsFixed(1)} KB (${ratio}% saved)");
      
      return File(result.path);
    } catch (e) {
      debugPrint("❌ Image compression failed: $e, using original");
      return sourceFile;
    }
  }

  /// Compress TEXT/DOCUMENT files using GZip
  static Future<File> compressWithGZip(File sourceFile) async {
    debugPrint("🗜️ GZip compressing: ${sourceFile.path}");
    
    final bytes = await sourceFile.readAsBytes();
    final compressed = GZipEncoder().encode(bytes);
    
    if (compressed == null) {
      throw Exception("GZip compression failed");
    }
    
    final compressedPath = '${sourceFile.path}.gz';
    final compressedFile = File(compressedPath);
    await compressedFile.writeAsBytes(compressed);
    
    final originalSize = bytes.length / 1024;
    final compressedSize = compressed.length / 1024;
    final ratio = ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1);
    
    debugPrint("✅ GZip compressed: ${originalSize.toStringAsFixed(1)} KB → ${compressedSize.toStringAsFixed(1)} KB (${ratio}% saved)");
    
    return compressedFile;
  }

  /// Smart compression - chooses best method based on file type
  static Future<File> compressFile(File sourceFile, String mimeType) async {
    // Already compressed formats - skip compression
    if (isAlreadyCompressed(mimeType)) {
      debugPrint("⏭️ Skipping compression for already-compressed format: $mimeType");
      return sourceFile;
    }
    
    // Images - use image compression
    if (isImage(mimeType)) {
      return await compressImage(sourceFile, mimeType);
    }
    
    // Other files (PDF, documents, text) - use GZip
    return await compressWithGZip(sourceFile);
  }

  static Future<ChatAttachment> uploadSingle({
    required String tenantId,
    required String conversationId,
    required String messageTempId,
    required ChatAttachment localAttachment,
  }) async {
    await ensureAuth();

    try {
      final localPath = localAttachment.url;
      debugPrint("Uploading: $localPath");
      
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception("File missing: $localPath");
      }

      // SMART COMPRESSION based on file type
      final compressedFile = await compressFile(file, localAttachment.mimeType);
      final wasCompressed = compressedFile.path != file.path;
      
      // GET FILE SIZE
      final compressedFileSize = await compressedFile.length();
      
      final fileName = localAttachment.name;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = fileName.replaceAll(RegExp(r'[^\w\-\.]'), '_');
      
      // Add .gz extension only if GZip was used
      final needsGzExtension = wasCompressed && compressedFile.path.endsWith('.gz');
      final storagePath = needsGzExtension
          ? "tenants/$tenantId/chats/$conversationId/$messageTempId/$cleanName.gz"
          : "tenants/$tenantId/chats/$conversationId/$messageTempId/$cleanName";
      
      debugPrint("Path: $storagePath");

      final ref = storage.ref().child(storagePath);

      try {
        await ref.delete();
        debugPrint("Cleared existing file");
      } catch (e) {
        debugPrint("No existing file to delete");
      }

      final uploadTask = ref.putFile(
        compressedFile,
        SettableMetadata(
          contentType: localAttachment.mimeType,
          customMetadata: {
            'originalName': fileName,
            'compressed': wasCompressed ? 'true' : 'false',
            'compressionType': isImage(localAttachment.mimeType) ? 'image' : 'gzip',
          },
        ),
      );

      final snapshot = await uploadTask;
      debugPrint("Upload state: ${snapshot.state}");

      if (snapshot.state != TaskState.success) {
        throw Exception("Upload failed: ${snapshot.state}");
      }

      String? downloadUrl;
      for (int i = 0; i < 5; i++) {
        try {
          downloadUrl = await ref.getDownloadURL();
          debugPrint("URL got: ${downloadUrl.substring(0, 50)}...");
          break;
        } catch (e) {
          debugPrint("URL attempt ${i + 1}/5 failed: $e");
          await Future.delayed(Duration(milliseconds: 800 * (i + 1)));
        }
      }

      if (downloadUrl == null) {
        throw Exception("Failed to get download URL after 5 attempts");
      }

      // Delete compressed file if different from original
      if (wasCompressed) {
        try {
          await compressedFile.delete();
          debugPrint("🗑️ Deleted local compressed file");
        } catch (e) {
          debugPrint("⚠️ Could not delete compressed file: $e");
        }
      }

      return ChatAttachment(
        url: downloadUrl,
        name: cleanName,
        mimeType: localAttachment.mimeType,
        sizeBytes: compressedFileSize,
        compressed: wasCompressed,
      );
    } catch (e, st) {
      debugPrint("FULL ERROR: $e");
      debugPrint("Stack: $st");
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
        debugPrint("Upload ${i + 1} failed: $e");
        rethrow;
      }
    }
    
    return uploaded;
  }
}
