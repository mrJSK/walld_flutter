import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

class ChatAttachmentService {
  static const _prefsKey = 'chat_downloads_v1';

  /// Decompress GZip file
  static Future<File> decompressFile(File compressedFile, String originalFileName) async {
    debugPrint("📦 Decompressing: ${compressedFile.path}");
    
    // Read compressed bytes
    final compressedBytes = await compressedFile.readAsBytes();
    
    // Decompress using GZip
    final decompressed = GZipDecoder().decodeBytes(compressedBytes);
    
    // Save decompressed file (remove .gz extension)
    final decompressedPath = compressedFile.path.replaceAll('.gz', '');
    final decompressedFile = File(decompressedPath);
    await decompressedFile.writeAsBytes(decompressed);
    
    final compressedSize = compressedBytes.length / 1024; // KB
    final decompressedSize = decompressed.length / 1024; // KB
    
    debugPrint("✅ Decompressed: ${compressedSize.toStringAsFixed(1)} KB → ${decompressedSize.toStringAsFixed(1)} KB");
    
    return decompressedFile;
  }

  static Future<File> downloadToLocal({
    required String tenantId,
    required String conversationId,
    required String messageId,
    required int attachmentIndex,
    required ChatAttachment attachment,
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse(attachment.url);
    final response = await http.Client().send(http.Request('GET', uri));

    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(
      p.join(
        baseDir.path,
        'attachments',
        tenantId,
        conversationId,
        messageId,
      ),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Determine if file is compressed based on attachment metadata
    final isCompressed = attachment.compressed;
    
    // Download with appropriate filename
    final downloadFileName = isCompressed ? '${attachment.name}.gz' : attachment.name;
    final downloadPath = p.join(dir.path, downloadFileName);
    final downloadFile = File(downloadPath);
    final sink = downloadFile.openWrite();

    final contentLength = response.contentLength ?? 0;
    int received = 0;

    await for (final chunk in response.stream) {
      received += chunk.length;
      sink.add(chunk);
      if (contentLength > 0 && onProgress != null) {
        onProgress(received / contentLength);
      }
    }

    await sink.close();
    debugPrint("📥 Downloaded file: ${downloadFile.path}");

    // Handle decompression if needed
    File finalFile;
    if (isCompressed) {
      try {
        // Decompress the file
        finalFile = await decompressFile(downloadFile, attachment.name);
        
        // Delete compressed file to save storage
        try {
          await downloadFile.delete();
          debugPrint("🗑️ Deleted compressed file to save storage");
        } catch (e) {
          debugPrint("⚠️ Could not delete compressed file: $e");
        }
      } catch (e) {
        debugPrint("❌ Decompression failed: $e");
        // If decompression fails, use the downloaded file as-is
        finalFile = downloadFile;
      }
    } else {
      // Not compressed, use downloaded file directly
      finalFile = downloadFile;
    }

    await _persistDownload(
      tenantId: tenantId,
      conversationId: conversationId,
      messageId: messageId,
      attachmentIndex: attachmentIndex,
      localPath: finalFile.path,
      remoteUrl: attachment.url,
      mimeType: attachment.mimeType,
      fileName: attachment.name,
      sizeBytes: await finalFile.length(),
    );

    return finalFile;
  }

  static Future<Map<String, dynamic>> _loadMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {'downloads': []};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {'downloads': []};
    }
  }

  static Future<void> _saveMap(Map<String, dynamic> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  static Future<void> _persistDownload({
    required String tenantId,
    required String conversationId,
    required String messageId,
    required int attachmentIndex,
    required String localPath,
    required String remoteUrl,
    required String mimeType,
    required String fileName,
    required int sizeBytes,
  }) async {
    final map = await _loadMap();
    final list = (map['downloads'] as List?) ?? [];

    list.removeWhere((e) =>
        e['tenantId'] == tenantId &&
        e['conversationId'] == conversationId &&
        e['messageId'] == messageId &&
        e['attachmentIndex'] == attachmentIndex);

    list.add({
      'tenantId': tenantId,
      'conversationId': conversationId,
      'messageId': messageId,
      'attachmentIndex': attachmentIndex,
      'remoteUrl': remoteUrl,
      'fileName': fileName,
      'mimeType': mimeType,
      'localPath': localPath,
      'sizeBytes': sizeBytes,
      'downloadedAt': DateTime.now().toUtc().toIso8601String(),
    });

    map['downloads'] = list;
    await _saveMap(map);
  }

  static Future<String?> resolveLocalPath({
    required String tenantId,
    required String conversationId,
    required String messageId,
    required int attachmentIndex,
  }) async {
    final map = await _loadMap();
    final list = (map['downloads'] as List?) ?? [];
    final match = list.cast<Map<String, dynamic>?>().firstWhere(
          (e) =>
              e != null &&
              e['tenantId'] == tenantId &&
              e['conversationId'] == conversationId &&
              e['messageId'] == messageId &&
              e['attachmentIndex'] == attachmentIndex,
          orElse: () => null,
        );
    if (match == null) return null;
    final path = match['localPath'] as String?;
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return path;
  }
}
