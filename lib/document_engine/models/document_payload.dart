import 'dart:typed_data';

enum DocumentFormat { pdf, excel, csv, ocrImage, unknown }

class DocumentPayload {
  final Uint8List bytes;
  final String fileName;
  final DocumentFormat format;
  final String? password; // Kept strictly in RAM during session
  final DateTime createdDate;

  DocumentPayload({
    required this.bytes,
    required this.fileName,
    required this.format,
    this.password,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  static DocumentFormat detectFormat(String fileName) {
    final cleanName = fileName.trim();
    final lastDot = cleanName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == cleanName.length - 1) {
      return DocumentFormat.unknown;
    }
    final ext = cleanName
        .substring(lastDot + 1)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (ext == 'pdf') return DocumentFormat.pdf;
    if (ext == 'xlsx' || ext == 'xls') return DocumentFormat.excel;
    if (ext == 'csv' || ext == 'txt') return DocumentFormat.csv;
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'heic') {
      return DocumentFormat.ocrImage;
    }
    return DocumentFormat.unknown;
  }
}
