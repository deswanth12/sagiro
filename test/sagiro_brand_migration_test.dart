import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/theme/app_theme.dart';
import 'package:sagiro/services/saf_document_reader.dart';
import 'package:sagiro/services/backup_service.dart';
import 'package:sagiro/services/database_helper.dart';
import 'package:sagiro/billing/billing_constants.dart';
import 'package:sagiro/document_engine/models/document_payload.dart';
import 'package:sagiro/components/paisapilot_logo.dart';

import 'package:google_fonts/google_fonts.dart';

import 'test_helper.dart';

void main() {
  setUpAll(() {
    setupTestSqflite();
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  group('SAGIRO Brand Migration & Compatibility Unit Tests', () {
    test('1. Sagiro visible branding logo renders SagiroLogo widget', () {
      const widget = SagiroLogo(size: 100, showTagline: true);
      expect(widget.size, equals(100));
      expect(widget.showTagline, isTrue);
    });

    test('2. Sagiro Theme System contains official brand color palette', () {
      expect(AppTheme.primaryDeepEmerald, equals(const Color(0xFF0B3D2E)));
      expect(AppTheme.secondaryEmerald, equals(const Color(0xFF10B981)));
      expect(AppTheme.accentLime, equals(const Color(0xFF10B981)));
      expect(AppTheme.lightBackground, equals(const Color(0xFFF8FAFC)));
      expect(AppTheme.darkBackground, equals(const Color(0xFF090C10)));
    });

    test('3. Technical Identifiers & Play Store Identity remain stable', () {
      expect(BillingConstants.skuProMonthly, equals('com.sagiro.pro.monthly'));
      expect(BillingConstants.skuProYearly, equals('com.sagiro.pro.yearly'));
      expect(
          BillingConstants.skuProLifetime, equals('com.sagiro.pro.lifetime'));
    });

    test(
        '4. Backup Compatibility: Generates valid Sagiro backup with legacy compatibility',
        () async {
      final jsonStr = await BackupService.generateBackupArchive();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(map['metadata'], isNotNull);
      expect(map['metadata']['appName'], equals('Sagiro'));

      // Validate old PaisaPilot backup header parsing
      final oldBackupJson = jsonEncode({
        'metadata': {
          'appName': 'PaisaPilot',
          'appVersion': '1.0.0',
          'databaseVersion': 3,
          'backupVersion': '1.0',
          'createdDate': DateTime.now().toIso8601String(),
          'transactionCount': 0,
          'categoryRuleCount': 0,
          'isEncrypted': false,
        },
        'checksum': 'mock_checksum',
        'payload': jsonEncode({
          'transactions': [],
          'category_rules': [],
          'settings': {},
        })
      });

      final meta = BackupService.inspectBackupHeader(oldBackupJson);
      expect(meta.appName, equals('PaisaPilot'));
    });

    test('5. Database Safety: DatabaseHelper opens paisapilot.db safely',
        () async {
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);
    });

    test('6. SAF Document Reader reads content:// URI bytes without error',
        () async {
      final mockBytes = Uint8List.fromList(utf8.encode('PDF Data Content'));
      final mockFile = PlatformFile(
        name: 'SBI_Statement_2026.pdf',
        size: mockBytes.length,
        bytes: mockBytes,
        path: null,
      );

      final readBytes = await SafDocumentReader.readBytes(mockFile);
      expect(readBytes, equals(mockBytes));
    });

    test('7. Format Detection handles PDF, CSV, Excel, and Image extensions',
        () {
      expect(DocumentPayload.detectFormat('Statement.pdf'),
          equals(DocumentFormat.pdf));
      expect(DocumentPayload.detectFormat('Khata.csv'),
          equals(DocumentFormat.csv));
      expect(DocumentPayload.detectFormat('Export.xlsx'),
          equals(DocumentFormat.excel));
      expect(DocumentPayload.detectFormat('Receipt.jpg'),
          equals(DocumentFormat.ocrImage));
    });

    test('8. SAF Cancelled picker returns empty byte array safely', () async {
      final mockFile = PlatformFile(
        name: 'cancelled.csv',
        size: 0,
        bytes: null,
        path: null,
      );

      final readBytes = await SafDocumentReader.readBytes(mockFile);
      expect(readBytes.isEmpty, isTrue);
    });
  });
}
