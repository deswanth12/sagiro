import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class SafReadResult {
  final bool isSuccess;
  final Uint8List bytes;
  final String text;
  final String? errorMessage;
  final String fileName;

  SafReadResult({
    required this.isSuccess,
    required this.bytes,
    required this.text,
    this.errorMessage,
    required this.fileName,
  });
}

/// SafDocumentReader — Storage Access Framework (SAF) & Content Stream Reader.
/// Zero MANAGE_EXTERNAL_STORAGE permission required.
/// Fully compatible with Android Files app, Downloads/SBIYono/, Documents, Google Drive SAF URIs.
class SafDocumentReader {
  /// Extract raw document Uint8List bytes from a PlatformFile.
  static Future<Uint8List> readBytes(PlatformFile file) async {
    try {
      // Tier 1: Direct in-memory bytes (provided by FilePicker on web/in-memory)
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        return file.bytes!;
      }

      // Tier 2: Cached or direct file path on filesystem
      if (file.path != null && file.path!.isNotEmpty) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          final bytes = await ioFile.readAsBytes();
          if (bytes.isNotEmpty) return bytes;
        }
      }

      // Tier 3: Stream fallback for content:// URIs
      if (file.readStream != null) {
        final BytesBuilder builder = BytesBuilder(copy: false);
        await for (final chunk in file.readStream!) {
          builder.add(chunk);
        }
        final bytes = builder.takeBytes();
        if (bytes.isNotEmpty) return bytes;
      }
    } catch (e) {
      debugPrint('SafDocumentReader.readBytes error for ${file.name}: $e');
    }

    return Uint8List(0);
  }

  /// Decode byte buffer into a clean String, removing UTF-8 BOM if present.
  static String decodeText(Uint8List bytes) {
    if (bytes.isEmpty) return '';

    // Strip UTF-8 BOM (0xEF, 0xBB, 0xBF) if present
    Uint8List effectiveBytes = bytes;
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      effectiveBytes = bytes.sublist(3);
    }

    try {
      final decoded = utf8.decode(effectiveBytes);
      // Remove any leading BOM character \uFEFF if string decoding retained it
      if (decoded.startsWith('\uFEFF')) {
        return decoded.substring(1);
      }
      return decoded;
    } catch (_) {
      try {
        return latin1.decode(effectiveBytes);
      } catch (_) {
        return String.fromCharCodes(effectiveBytes);
      }
    }
  }

  /// Read file bytes, decode content, and validate accessibility.
  static Future<SafReadResult> validateAndRead(PlatformFile file) async {
    final fileName = file.name;
    final bytes = await readBytes(file);

    if (bytes.isEmpty) {
      return SafReadResult(
        isSuccess: false,
        bytes: Uint8List(0),
        text: '',
        errorMessage:
            'Couldn\'t read $fileName. The file might be unavailable or empty.',
        fileName: fileName,
      );
    }

    final text = decodeText(bytes);
    return SafReadResult(
      isSuccess: true,
      bytes: bytes,
      text: text,
      fileName: fileName,
    );
  }
}
