import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'saf_document_reader.dart';

/// SafStorageService — Storage Access Framework (SAF) file manager for Sagiro.
///
/// RULES:
///   - 0 MANAGE_EXTERNAL_STORAGE, 0 READ_EXTERNAL_STORAGE, 0 WRITE_EXTERNAL_STORAGE.
///   - Uses Android SAF via platform picker & FilePicker.
///   - Saves backups outside app sandbox (survives app uninstall).
///   - Persists selected folder URI in SharedPreferences.
class SafStorageService {
  static const String _kPersistedUriKey = 'saf_backup_folder_uri';
  static const String _kLastBackupDateKey = 'saf_last_backup_date';

  /// Generates the standard Sagiro backup filename:
  /// Sagiro_Backup_YYYY_MM_DD_HH_MM.ppbackup
  static String generateFilename() {
    final fmt = DateFormat('yyyy_MM_dd_HH_mm');
    return 'Sagiro_Backup_${fmt.format(DateTime.now())}.ppbackup';
  }

  /// Gets the persisted backup folder URI string, or null if not set.
  static Future<String?> getPersistedFolderUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPersistedUriKey);
  }

  /// Gets the timestamp of the last successful backup.
  static Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kLastBackupDateKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Saves backup content to user-selected location via SAF Create Document picker.
  static Future<String?> saveBackupFile(String content) async {
    final filename = generateFilename();

    try {
      final bytes = utf8.encode(content);
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Select Backup Save Location',
        fileName: filename,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['ppbackup', 'json'],
      );

      if (outputPath != null) {
        // Record last backup timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _kLastBackupDateKey, DateTime.now().toIso8601String());

        // On desktop/mobile file path return: ensure written
        final file = File(outputPath);
        if (!await file.exists()) {
          await file.writeAsString(content);
        }
        return outputPath;
      }
      return null; // User cancelled
    } catch (e) {
      debugPrint('SafStorageService.saveBackupFile error: $e');
      rethrow;
    }
  }

  /// Launches SAF Open Document picker to select and read a .ppbackup file.
  static Future<Map<String, String>?> pickAndReadBackupFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ppbackup', 'json'],
        withData: true,
        withReadStream: true,
      );

      if (picked == null || picked.files.isEmpty) return null;

      final file = picked.files.single;
      final bytes = await SafDocumentReader.readBytes(file);
      if (bytes.isEmpty) return null;

      String content = '';
      try {
        content = utf8.decode(bytes);
      } catch (_) {
        content = String.fromCharCodes(bytes);
      }

      if (content.isEmpty) return null;

      return {
        'filename': file.name,
        'content': content,
      };
    } catch (e) {
      debugPrint('SafStorageService.pickAndReadBackupFile error: $e');
      rethrow;
    }
  }
}
