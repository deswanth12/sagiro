import 'dart:typed_data';

class GoogleDriveSyncException implements Exception {
  final String message;
  const GoogleDriveSyncException(this.message);

  @override
  String toString() => message;
}

/// GoogleDriveSyncService — Remote Storage Bridge.
/// Reports unconfigured state explicitly when Google Cloud OAuth is not set up.
class GoogleDriveSyncService {
  static const bool isConfigured = false;
  static bool get isConnected => false;
  static String? get cachedDriveToken => null;

  /// Authenticates with Google Drive scope (Requires Google Cloud OAuth config)
  static Future<bool> connectGoogleDrive() async {
    return false;
  }

  /// Disconnects Google Drive
  static Future<void> disconnectGoogleDrive() async {}

  /// Uploads Encrypted `.ppbackup` Archive Bytes to appDataFolder
  static Future<String> uploadEncryptedBackup({
    required Uint8List archiveBytes,
    required String fileName,
  }) async {
    throw const GoogleDriveSyncException(
        'Cloud Sync Not Configured. Please export encrypted backup manually.');
  }

  /// Downloads Encrypted `.ppbackup` Archive Bytes from appDataFolder
  static Future<Uint8List> downloadEncryptedBackup(String fileId) async {
    throw const GoogleDriveSyncException(
        'Cloud Sync Not Configured. Please import local backup file.');
  }
}
