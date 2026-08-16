import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sagiro/services/database_helper.dart';
export 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialises sqflite_common_ffi for host-side unit tests.
///
/// Must be called inside [setUpAll] at the top of every test file that touches
/// [DatabaseHelper].  It:
///   1. Initialises the in-process FFI SQLite implementation.
///   2. Injects [databaseFactoryFfi] into [DatabaseHelper.testDatabaseFactory]
///      so [_initDB] uses it instead of the SQLCipher platform channel.
///      (sqflite_sqlcipher 3.x has its own private databaseFactory, separate
///      from sqflite_common's global, so the usual approach of setting the
///      global databaseFactory = databaseFactoryFfi has no effect.)
///   3. Sets [DatabaseHelper.disableEncryptionForTests] to true.
///   4. Points [DatabaseHelper.overrideDatabasePath] to in-memory storage.
void setupTestSqflite() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  // Inject the FFI factory directly — sqflite_sqlcipher ignores the global.
  DatabaseHelper.testDatabaseFactory = databaseFactoryFfi;
  DatabaseHelper.disableEncryptionForTests = true;
  DatabaseHelper.overrideDatabasePath = inMemoryDatabasePath;
}

/// Async reset — call this inside setUp() or setUpAll() when a test file
/// needs a fresh DB state (e.g. to clear rows left by a prior test group).
Future<void> resetTestDatabase() async {
  await DatabaseHelper.resetForTests();
}
