import 'dart:convert';
import 'dart:typed_data';

class RawTextExtractor {
  static String extractText(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }
}
