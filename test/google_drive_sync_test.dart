import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagiro/services/google_drive_sync_service.dart';

void main() {
  group('Google Drive Sync Unconfigured State Tests', () {
    test('isConfigured returns false when Google Cloud OAuth is not set up',
        () {
      expect(GoogleDriveSyncService.isConfigured, isFalse);
      expect(GoogleDriveSyncService.isConnected, isFalse);
      expect(GoogleDriveSyncService.cachedDriveToken, isNull);
    });

    test('connectGoogleDrive returns false', () async {
      final result = await GoogleDriveSyncService.connectGoogleDrive();
      expect(result, isFalse);
    });

    test(
        'uploadEncryptedBackup throws GoogleDriveSyncException without fake file ID',
        () async {
      expect(
        () => GoogleDriveSyncService.uploadEncryptedBackup(
          archiveBytes: Uint8List(10),
          fileName: 'test.ppbackup',
        ),
        throwsA(isA<GoogleDriveSyncException>()),
      );
    });

    test('downloadEncryptedBackup throws GoogleDriveSyncException', () async {
      expect(
        () => GoogleDriveSyncService.downloadEncryptedBackup('test_file_id'),
        throwsA(isA<GoogleDriveSyncException>()),
      );
    });
  });
}
