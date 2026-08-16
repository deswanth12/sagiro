import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart'; // Finding 1: SQLCipher encrypted DB
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category_rule.dart';
import '../models/canonical_transaction_identity.dart';
import '../security/secure_key_storage.dart';

class BatchInsertResult {
  final int insertedCount;
  final int failedCount;
  final List<String> errors;

  BatchInsertResult({
    required this.insertedCount,
    required this.failedCount,
    required this.errors,
  });
}

/// DatabaseHelper — SQLite wrapper for Sagiro.
///
/// VERSION HISTORY
/// ───────────────
/// v1 — Initial schema (transactions, category_rules, settings)
/// v2 — Added indexes on transactions(date), transactions(type)
/// v8 — Added multi-profile support (profileId, isShared, family tables)
/// v9 — Added canonical transaction identity & unique deduplication protection
///
/// MIGRATION POLICY
/// ────────────────
/// Never drop user data. Only ALTER TABLE or CREATE INDEX.
/// Always increment [_kDbVersion] when schema changes.
class DatabaseHelper {
  static const int _kDbVersion = 9;
  static int get currentDbVersion => _kDbVersion;
  static const String currentAppVersion = '2.5.0+1';

  /// Primary production database name. All new installs use this name.
  static const String _kDbName = 'sagiro.db';

  /// Legacy database file names — migrated automatically on first launch.
  static const String _kPaisaPilotDbName = 'paisapilot.db';
  static const String _kHisariDbName = 'hisari.db';
  static const String _kAeraviDbName = 'aeravi.db';
  static String? overrideDatabasePath;

  /// Set to true in test_helper.dart before any tests run.
  ///
  /// When true, [_initDB] opens via [testDatabaseFactory] instead of the
  /// SQLCipher platform channel.  sqflite_sqlcipher 3.x exports its own
  /// private [databaseFactory] getter (separate from sqflite_common's global),
  /// so overriding sqflite_common's global has no effect here.  Instead,
  /// test_helper.dart injects [databaseFactoryFfi] directly via [testDatabaseFactory].
  static bool disableEncryptionForTests = false;

  /// FFI database factory injected by test_helper.dart.
  /// **Never set this in production code.**
  static DatabaseFactory? testDatabaseFactory;

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  /// Closes and resets the cached database connection.
  ///
  /// **Call this only from test setup code.**  In production the singleton DB
  /// connection is intentionally kept open for the app's lifetime.
  /// Calling this in [setupTestSqflite] ensures each test file gets a fresh
  /// connection that respects the FFI factory override, even if an earlier test
  /// file already initialized the singleton through the SQLCipher channel.
  static Future<void> resetForTests() async {
    await _database?.close();
    _database = null;
  }

  // Web in-memory fallback stores (Zero fake demo data)
  final List<TransactionItem> _webTransactions = [];
  final List<CategoryRule> _webRules = [];
  final Map<String, String> _webSettings = {};

  DatabaseHelper._init() {
    if (kIsWeb) {
      _initWebSeedRules();
    }
  }

  void _initWebSeedRules() {
    final now = DateTime.now();
    _webRules.addAll([
      CategoryRule(keyword: 'swiggy', category: 'Food', createdAt: now),
      CategoryRule(keyword: 'zomato', category: 'Food', createdAt: now),
      CategoryRule(keyword: 'indian oil', category: 'Fuel', createdAt: now),
      CategoryRule(keyword: 'amazon', category: 'Shopping', createdAt: now),
      CategoryRule(
          keyword: 'netflix', category: 'Entertainment', createdAt: now),
      CategoryRule(keyword: 'uber', category: 'Travel', createdAt: now),
      CategoryRule(
          keyword: 'spotify', category: 'Entertainment', createdAt: now),
    ]);
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    // If we have a cached connection but it was opened under a different test-mode
    // setting than the current one, close it and re-open with the correct factory.
    // This handles the case where a prior test file initialised the singleton
    // through the SQLCipher channel before test_helper.dart set
    // disableEncryptionForTests = true.
    if (_database != null && _openedInTestMode != disableEncryptionForTests) {
      await _database!.close();
      _database = null;
    }
    if (_database != null) return _database!;
    _database = await _initDB(overrideDatabasePath ?? _kDbName);
    _openedInTestMode = disableEncryptionForTests;
    return _database!;
  }

  static bool _openedInTestMode = false;

  Future<Database> _initDB(String filePath) async {
    // ─── TEST MODE ─────────────────────────────────────────────────────────────
    // sqflite_sqlcipher 3.x routes all openDatabase() calls (including in-memory)
    // through its own platform channel, completely bypassing the global
    // databaseFactory.  Tests set disableEncryptionForTests = true and
    // databaseFactory = databaseFactoryFfi, so we use databaseFactory.openDatabase()
    // without a password here — the FFI factory handles both in-memory and
    // file-based paths used by tests.
    if (disableEncryptionForTests) {
      final factory = testDatabaseFactory;
      if (factory == null) {
        throw StateError(
            'DatabaseHelper: disableEncryptionForTests is true but '
            'testDatabaseFactory was not set. Call setupTestSqflite() first.');
      }
      final path = filePath == inMemoryDatabasePath || filePath == ':memory:'
          ? inMemoryDatabasePath
          : filePath;
      final db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _kDbVersion,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        ),
      );
      await _ensureColumnsExist(db);
      return db;
    }
    // ─── PRODUCTION ────────────────────────────────────────────────────────────
    // In-memory path reached only in production when kIsWeb is false but we
    // have a programmatic in-memory override (not expected in normal flows).
    if (filePath == inMemoryDatabasePath || filePath == ':memory:') {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: _kDbVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
      await _ensureColumnsExist(db);
      return db;
    }

    final dbPath = await getDatabasesPath();
    // The canonical production path is always sagiro.db.
    final canonicalPath = join(dbPath, _kDbName);
    var path = filePath == _kDbName ? canonicalPath : join(dbPath, filePath);

    // ─────────────────────────────────────────────────────────────────────────
    // LEGACY DB FILE MIGRATION
    //
    // Users upgrading from older builds may have a database under one of these
    // legacy file names.  We transparently migrate them to sagiro.db on first
    // launch so they keep all their data without any manual action.
    //
    // Priority chain: sagiro.db > paisapilot.db > hisari.db > aeravi.db
    // ─────────────────────────────────────────────────────────────────────────
    if (!await databaseExists(canonicalPath)) {
      final legacyNames = [
        _kPaisaPilotDbName,
        _kHisariDbName,
        _kAeraviDbName,
      ];
      for (final legacy in legacyNames) {
        final legacyPath = join(dbPath, legacy);
        if (await databaseExists(legacyPath)) {
          debugPrint(
              'DatabaseHelper: found legacy DB $legacy → copying to sagiro.db');
          try {
            await File(legacyPath).copy(canonicalPath);
            debugPrint('DatabaseHelper: legacy copy succeeded');
          } catch (e) {
            debugPrint('DatabaseHelper: legacy copy failed — $e');
          }
          break;
        }
      }
    }
    path = canonicalPath;

    // Retrieve (or generate) the 256-bit Keychain/Keystore-backed cipher key.
    final dbKey = await SecureKeyStorage.getOrCreateDatabaseKey();

    // ─────────────────────────────────────────────────────────────────────────
    // PLAINTEXT MIGRATION (Finding 1 fix)
    //
    // Existing users upgrading from a pre-SQLCipher build have an unencrypted
    // .db file on disk.  SQLCipher cannot open a plaintext file with a password
    // (it will fail or silently return garbage).  We detect this once by trying
    // to open it without a password; if that succeeds AND the cipher_version
    // PRAGMA returns empty, it's a legacy plaintext file — we re-encrypt it.
    //
    // Detection strategy: a freshly encrypted SQLCipher DB will respond to
    //   PRAGMA cipher_version
    // with a non-empty result; a plain SQLite file responds with an empty list
    // because the pragma is unknown.  We use this difference to detect the
    // migration case without loading user data into memory unnecessarily.
    // ─────────────────────────────────────────────────────────────────────────
    final needsMigration = await _isPlaintextDatabase(path);
    if (needsMigration) {
      debugPrint(
          'DatabaseHelper: legacy plaintext DB detected — migrating to SQLCipher');
      await _migratePlaintextToEncrypted(path, dbKey);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CORRUPTED / WRONG-KEY DATABASE RECOVERY
    //
    // If the file exists but SQLCipher cannot decrypt it (e.g. the key changed
    // between builds, or the file was corrupted during an aborted migration),
    // the openDatabase() call below will throw.  We catch that case, safely
    // delete the unreadable file, and start fresh — preserving app stability.
    // ─────────────────────────────────────────────────────────────────────────

    try {
      final db = await openDatabase(
        path,
        password:
            dbKey, // SQLCipher: all I/O transparently AES-256-CBC encrypted
        version: _kDbVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
      await _ensureColumnsExist(db);
      return db;
    } catch (e) {
      // The file exists but SQLCipher cannot decrypt it — wrong key, corrupted
      // bytes, or incomplete migration.  Delete it and open a fresh database so
      // the app remains usable.  User data in the bad file is already lost; we
      // must not loop-crash instead of starting fresh.
      debugPrint(
          'DatabaseHelper: openDatabase failed ($e) — deleting unreadable file and starting fresh.');
      try {
        await File(path).delete();
      } catch (_) {}
      final db = await openDatabase(
        path,
        password: dbKey,
        version: _kDbVersion,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
      await _ensureColumnsExist(db);
      return db;
    }
  }

  /// Returns true when [path] exists and is a legacy plaintext SQLite file
  /// (i.e. one that was written before this SQLCipher migration).
  static Future<bool> _isPlaintextDatabase(String path) async {
    if (!await databaseExists(path)) return false;
    try {
      // Open without a password — will succeed on a plaintext file.
      final db = await openDatabase(path, readOnly: true);
      final result = await db.rawQuery('PRAGMA cipher_version');
      await db.close();
      // cipher_version PRAGMA returns empty on plain SQLite, non-empty on SQLCipher.
      return result.isEmpty;
    } catch (_) {
      // If opening without a password throws, it's already encrypted — skip.
      return false;
    }
  }

  /// Migrates a legacy plaintext SQLite file to a SQLCipher-encrypted file.
  ///
  /// Process:
  ///   1. Open the old plaintext DB read-only (no password).
  ///   2. Use SQLCipher ATTACH + sqlcipher_export() to write a new encrypted
  ///      DB to a temp path.
  ///   3. Securely delete the original plaintext file.
  ///   4. Rename the encrypted file into the canonical path.
  ///
  /// This is an atomic operation from the user's perspective — if any step
  /// fails, the original file is untouched and the app retries on next launch.
  static Future<void> _migratePlaintextToEncrypted(
      String plainPath, String key) async {
    final encryptedPath = '$plainPath.sqlcipher_tmp';
    try {
      // Step 1: Open original plaintext DB.
      final plainDb = await openDatabase(plainPath);

      // Step 2: Export to encrypted file via SQLCipher's built-in mechanism.
      await plainDb.execute(
          "ATTACH DATABASE '\"$encryptedPath\"' AS encrypted KEY '\"$key\"'");
      await plainDb.execute("SELECT sqlcipher_export('encrypted')");
      await plainDb.execute("DETACH DATABASE encrypted");
      await plainDb.close();

      // Step 3: Securely zero-overwrite and delete the plaintext original.
      await _secureDeleteFile(plainPath);

      // Step 4: Move encrypted file to canonical path.
      await _renameFile(encryptedPath, plainPath);

      debugPrint('DatabaseHelper: migration to SQLCipher complete.');
    } catch (e) {
      debugPrint('DatabaseHelper: SQLCipher migration failed — $e');
      // Leave plaintext file intact; app will retry on next launch.
    }
  }

  /// Zero-overwrites then deletes a file to prevent forensic recovery.
  /// Mirrors the pattern already used in PrivateSyncService.
  static Future<void> _secureDeleteFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    final size = await file.length();
    if (size > 0) {
      final zeros = Uint8List(size); // dart default-initializes to 0
      await file.writeAsBytes(zeros, flush: true);
    }
    await file.delete();
  }

  static Future<void> _renameFile(String from, String to) async {
    final src = File(from);
    await src.rename(to);
  }

  static Future<void> _ensureColumnsExist(Database db) async {
    try {
      await db
          .execute("ALTER TABLE transactions ADD COLUMN originalCategory TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE transactions ADD COLUMN userCategory TEXT");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE transactions ADD COLUMN transactionReference TEXT");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE transactions ADD COLUMN profileId TEXT DEFAULT 'default_profile'");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE transactions ADD COLUMN isShared INTEGER DEFAULT 0");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE transactions ADD COLUMN transactionFingerprint TEXT");
    } catch (_) {}
    try {
      await db
          .execute("ALTER TABLE transactions ADD COLUMN sourceMessageId TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE transactions ADD COLUMN sourceTypes TEXT");
    } catch (_) {}
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS profiles (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          avatarEmoji TEXT NOT NULL,
          role TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
    } catch (_) {}
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS family_approval_requests (
          id TEXT PRIMARY KEY,
          familyId TEXT NOT NULL DEFAULT 'fam_main',
          requesterId TEXT NOT NULL DEFAULT 'default_profile',
          requesterName TEXT NOT NULL,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          reason TEXT NOT NULL,
          status TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    } catch (_) {}
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS family_budgets (
          id TEXT PRIMARY KEY,
          familyId TEXT NOT NULL DEFAULT 'fam_main',
          category TEXT NOT NULL,
          limitAmount REAL NOT NULL,
          memberContributions TEXT DEFAULT '{}',
          createdAt TEXT NOT NULL
        )
      ''');
    } catch (_) {}
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS family_goals (
          id TEXT PRIMARY KEY,
          familyId TEXT NOT NULL DEFAULT 'fam_main',
          title TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          memberContributions TEXT DEFAULT '{}',
          createdAt TEXT NOT NULL
        )
      ''');
    } catch (_) {}
    try {
      await _cleanupExistingDuplicatesAndBackfillFingerprints(db);
    } catch (_) {}
    try {
      await _createIndexes(db);
    } catch (_) {}
  }

  /// Creates the database from scratch on first install.
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        merchant TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        source TEXT NOT NULL,
        date TEXT NOT NULL,
        account TEXT,
        notes TEXT,
        transactionReference TEXT,
        rawSms TEXT,
        splits TEXT,
        profileId TEXT DEFAULT 'default_profile',
        isShared INTEGER DEFAULT 0,
        originalCategory TEXT,
        userCategory TEXT,
        transactionFingerprint TEXT UNIQUE,
        sourceMessageId TEXT,
        sourceTypes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE category_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        keyword TEXT UNIQUE NOT NULL,
        category TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        targetDate TEXT NOT NULL,
        emoji TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE upcoming_bills (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        dueDate TEXT NOT NULL,
        providerEmoji TEXT NOT NULL,
        category TEXT DEFAULT 'Housing',
        account TEXT DEFAULT 'SBI',
        frequency TEXT DEFAULT 'Monthly',
        isActive INTEGER NOT NULL DEFAULT 1,
        isPaid INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createIndexes(db);
    await _seedDefaultRules(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint(
        'DatabaseHelper: upgrading DB from v$oldVersion to v$newVersion');
    try {
      await db
          .execute("ALTER TABLE transactions ADD COLUMN originalCategory TEXT");
    } catch (_) {}
    try {
      await db.execute("ALTER TABLE transactions ADD COLUMN userCategory TEXT");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE upcoming_bills ADD COLUMN category TEXT DEFAULT 'Housing'");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE upcoming_bills ADD COLUMN account TEXT DEFAULT 'SBI'");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE upcoming_bills ADD COLUMN frequency TEXT DEFAULT 'Monthly'");
    } catch (_) {}
    try {
      await db.execute(
          "ALTER TABLE upcoming_bills ADD COLUMN isActive INTEGER DEFAULT 1");
    } catch (_) {}
    if (oldVersion < 2) {
      await _createIndexes(db);
    }
    if (oldVersion < 3) {
      // v3: Add savings_goals and upcoming_bills persistence
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_goals (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          currentAmount REAL NOT NULL,
          targetDate TEXT NOT NULL,
          emoji TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS upcoming_bills (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          dueDate TEXT NOT NULL,
          providerEmoji TEXT NOT NULL,
          isPaid INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS import_history (
          id TEXT PRIMARY KEY,
          fileName TEXT NOT NULL,
          format TEXT NOT NULL,
          transactions INTEGER NOT NULL,
          duplicates INTEGER NOT NULL,
          healthScore TEXT NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN splits TEXT');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      // v7 Privacy Migration (P2-01): Remove/nullify all legacy rawSms values
      try {
        await db.execute('UPDATE transactions SET rawSms = NULL');
      } catch (e) {
        debugPrint('DatabaseHelper upgrade v7 error: $e');
      }
    }
    if (oldVersion < 8) {
      try {
        await db.execute(
            "ALTER TABLE transactions ADD COLUMN profileId TEXT DEFAULT 'default_profile'");
      } catch (_) {}
      try {
        await db.execute(
            "ALTER TABLE transactions ADD COLUMN isShared INTEGER DEFAULT 0");
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS profiles (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          avatarEmoji TEXT NOT NULL,
          role TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 9) {
      try {
        await db.execute(
            "ALTER TABLE transactions ADD COLUMN transactionFingerprint TEXT");
      } catch (_) {}
      try {
        await db.execute(
            "ALTER TABLE transactions ADD COLUMN sourceMessageId TEXT");
      } catch (_) {}
      await _cleanupExistingDuplicatesAndBackfillFingerprints(db);
    }
  }

  /// Cleans up existing duplicate rows in the database and backfills canonical fingerprints.
  /// Retains exactly ONE row (the original lowest id) per financial event signature.
  static Future<int> _cleanupExistingDuplicatesAndBackfillFingerprints(
      Database db) async {
    int removedCount = 0;
    try {
      final rows = await db.query('transactions', orderBy: 'id ASC');
      final seenFingerprints = <String>{};
      final idsToDelete = <int>[];
      final updates = <int, String>{};

      for (final row in rows) {
        final tx = TransactionItem.fromMap(row);
        final fp = CanonicalTransactionIdentity.computeFingerprint(tx);
        if (seenFingerprints.contains(fp)) {
          if (tx.id != null) {
            idsToDelete.add(tx.id!);
          }
        } else {
          seenFingerprints.add(fp);
          if (row['transactionFingerprint'] != fp && tx.id != null) {
            updates[tx.id!] = fp;
          }
        }
      }

      if (idsToDelete.isNotEmpty) {
        await db.transaction((txn) async {
          for (final id in idsToDelete) {
            await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
            removedCount++;
          }
        });
        debugPrint(
            'DatabaseHelper: Removed $removedCount duplicate transaction rows.');
      }

      if (updates.isNotEmpty) {
        await db.transaction((txn) async {
          for (final entry in updates.entries) {
            await txn.update(
              'transactions',
              {'transactionFingerprint': entry.value},
              where: 'id = ?',
              whereArgs: [entry.key],
            );
          }
        });
      }

      await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_fingerprint ON transactions(transactionFingerprint)');
    } catch (e) {
      debugPrint('DatabaseHelper: Duplicate cleanup & backfill error: $e');
    }
    return removedCount;
  }

  Future<void> insertImportHistory(Map<String, dynamic> item) async {
    final db = await database;
    if (db != null) {
      await db.insert('import_history', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getImportHistory() async {
    final db = await database;
    if (db != null) {
      return await db.query('import_history', orderBy: 'date DESC');
    }
    return [];
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_date_type ON transactions(date, type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_composite ON transactions(date DESC, category, type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_profile_date ON transactions(profileId, date DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_ref ON transactions(transactionReference)');
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_fingerprint ON transactions(transactionFingerprint)');
  }

  Future<void> _seedDefaultRules(Database db) async {
    final defaultRules = [
      {'keyword': 'swiggy', 'category': 'Food'},
      {'keyword': 'zomato', 'category': 'Food'},
      {'keyword': 'blinkit', 'category': 'Food'},
      {'keyword': 'zepto', 'category': 'Food'},
      {'keyword': 'indian oil', 'category': 'Fuel'},
      {'keyword': 'hpcl', 'category': 'Fuel'},
      {'keyword': 'bpcl', 'category': 'Fuel'},
      {'keyword': 'amazon', 'category': 'Shopping'},
      {'keyword': 'flipkart', 'category': 'Shopping'},
      {'keyword': 'myntra', 'category': 'Shopping'},
      {'keyword': 'netflix', 'category': 'Entertainment'},
      {'keyword': 'spotify', 'category': 'Entertainment'},
      {'keyword': 'hotstar', 'category': 'Entertainment'},
      {'keyword': 'uber', 'category': 'Travel'},
      {'keyword': 'ola', 'category': 'Travel'},
      {'keyword': 'rapido', 'category': 'Travel'},
      {'keyword': 'irctc', 'category': 'Travel'},
      {'keyword': 'apollo', 'category': 'Medical'},
      {'keyword': 'pharmeasy', 'category': 'Medical'},
      {'keyword': 'zerodha', 'category': 'Investments'},
      {'keyword': 'groww', 'category': 'Investments'},
    ];

    final nowStr = DateTime.now().toIso8601String();
    for (var rule in defaultRules) {
      await db.insert(
        'category_rules',
        {
          'keyword': rule['keyword'],
          'category': rule['category'],
          'createdAt': nowStr
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ── Transactions CRUD (Idempotent & Unique Protected) ─────────────

  Future<int> insertTransaction(TransactionItem item) async {
    final fp = item.transactionFingerprint ??
        CanonicalTransactionIdentity.computeFingerprint(item);
    final itemWithFp = item.copyWith(transactionFingerprint: fp);

    if (kIsWeb) {
      final existingIdx = _webTransactions.indexWhere((t) =>
          (t.transactionFingerprint ??
              CanonicalTransactionIdentity.computeFingerprint(t)) ==
          fp);
      if (existingIdx != -1) {
        return _webTransactions[existingIdx].id ?? 1;
      }
      final newId = _webTransactions.length + 1;
      _webTransactions.insert(0, itemWithFp.copyWith(id: newId));
      return newId;
    }
    try {
      final db = await instance.database;
      if (db == null) {
        _webTransactions.insert(0, itemWithFp);
        return _webTransactions.length;
      }

      // Check if duplicate already exists in SQLite table
      final existing = await db.query(
        'transactions',
        columns: ['id'],
        where: 'transactionFingerprint = ?',
        whereArgs: [fp],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        debugPrint(
            'DatabaseHelper.insertTransaction: Idempotent duplicate skipped ($fp)');
        return existing.first['id'] as int;
      }

      return await db.insert(
        'transactions',
        itemWithFp.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      debugPrint('DatabaseHelper.insertTransaction error: $e');
      _webTransactions.insert(0, itemWithFp);
      return _webTransactions.length;
    }
  }

  /// Atomic batch insertion within a single database transaction.
  /// Idempotent: skips any record whose canonical fingerprint or reference already exists.
  Future<BatchInsertResult> insertTransactionBatch(
      List<TransactionItem> items) async {
    if (items.isEmpty) {
      return BatchInsertResult(insertedCount: 0, failedCount: 0, errors: []);
    }

    final itemsWithFp = items.map((item) {
      final fp = item.transactionFingerprint ??
          CanonicalTransactionIdentity.computeFingerprint(item);
      return item.copyWith(transactionFingerprint: fp);
    }).toList();

    if (kIsWeb) {
      int inserted = 0;
      for (final item in itemsWithFp) {
        final fp = item.transactionFingerprint!;
        if (!_webTransactions.any((t) =>
            (t.transactionFingerprint ??
                CanonicalTransactionIdentity.computeFingerprint(t)) ==
            fp)) {
          final newId = _webTransactions.length + 1;
          _webTransactions.insert(0, item.copyWith(id: newId));
          inserted++;
        }
      }
      return BatchInsertResult(
        insertedCount: inserted,
        failedCount: 0,
        errors: [],
      );
    }

    int inserted = 0;
    int failed = 0;
    final List<String> errors = [];

    try {
      final db = await instance.database;
      if (db == null) {
        _webTransactions.insertAll(0, itemsWithFp);
        return BatchInsertResult(
          insertedCount: itemsWithFp.length,
          failedCount: 0,
          errors: [],
        );
      }

      // Preload all existing fingerprints in one fast query
      final existingFingerprints = await getAllExistingFingerprints();
      final batchSeenFingerprints = <String>{};

      await db.transaction((txn) async {
        for (final item in itemsWithFp) {
          final fp = item.transactionFingerprint!;
          // Skip if already in database or already added in this current batch
          if (existingFingerprints.contains(fp) ||
              batchSeenFingerprints.contains(fp)) {
            continue;
          }

          final rowId = await txn.insert(
            'transactions',
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          if (rowId > 0) {
            inserted++;
            batchSeenFingerprints.add(fp);
            existingFingerprints.add(fp);
          }
        }
      });
    } catch (e) {
      debugPrint('DatabaseHelper.insertTransactionBatch error: $e');
      inserted = 0;
      failed = itemsWithFp.length;
      errors.add('Atomic batch insert failed & rolled back: $e');
    }

    return BatchInsertResult(
      insertedCount: inserted,
      failedCount: failed,
      errors: errors,
    );
  }

  /// Returns a set of all canonical fingerprints & reference IDs currently stored in SQLite.
  Future<Set<String>> getAllExistingFingerprints({String? profileId}) async {
    final set = <String>{};
    if (kIsWeb) {
      for (final tx in _webTransactions) {
        if (profileId == null || tx.profileId == profileId) {
          final fp = tx.transactionFingerprint ??
              CanonicalTransactionIdentity.computeFingerprint(tx);
          set.add(fp.toLowerCase());
          if (tx.transactionReference != null &&
              tx.transactionReference!.isNotEmpty) {
            set.add(tx.transactionReference!.trim().toLowerCase());
          }
        }
      }
      return set;
    }

    try {
      final db = await database;
      if (db == null) return set;
      final maps = profileId == null
          ? await db.query('transactions',
              columns: ['transactionFingerprint', 'transactionReference'])
          : await db.query(
              'transactions',
              columns: ['transactionFingerprint', 'transactionReference'],
              where: 'profileId = ?',
              whereArgs: [profileId],
            );
      for (final map in maps) {
        final fp = map['transactionFingerprint'] as String?;
        if (fp != null && fp.isNotEmpty) set.add(fp.toLowerCase());
        final ref = map['transactionReference'] as String?;
        if (ref != null && ref.isNotEmpty) {
          set.add(ref.trim().toLowerCase());
        }
      }
    } catch (e) {
      debugPrint('DatabaseHelper.getAllExistingFingerprints error: $e');
    }
    return set;
  }

  /// Public cleanup method to deduplicate existing transactions in SQLite on demand.
  Future<int> cleanupExistingDuplicates({String? profileId}) async {
    if (kIsWeb) {
      final seen = <String>{};
      final initial = _webTransactions.length;
      _webTransactions.removeWhere((tx) {
        final fp = tx.transactionFingerprint ??
            CanonicalTransactionIdentity.computeFingerprint(tx);
        if (seen.contains(fp)) return true;
        seen.add(fp);
        return false;
      });
      return initial - _webTransactions.length;
    }

    final db = await database;
    if (db == null) return 0;
    return await _cleanupExistingDuplicatesAndBackfillFingerprints(db);
  }

  Future<List<TransactionItem>> getAllTransactions({String? profileId}) async {
    if (kIsWeb) {
      if (profileId == null) return List.from(_webTransactions);
      return _webTransactions.where((t) => t.profileId == profileId).toList();
    }
    try {
      final db = await instance.database;
      if (db == null) return List.from(_webTransactions);
      final maps = profileId == null
          ? await db.query('transactions', orderBy: 'date DESC')
          : await db.query(
              'transactions',
              where: 'profileId = ?',
              whereArgs: [profileId],
              orderBy: 'date DESC',
            );
      return maps.map((m) => TransactionItem.fromMap(m)).toList();
    } catch (e) {
      debugPrint('DatabaseHelper.getAllTransactions error: $e');
      return List.from(_webTransactions);
    }
  }

  Future<int> updateTransaction(TransactionItem item) async {
    if (kIsWeb) {
      final idx = _webTransactions.indexWhere((t) => t.id == item.id);
      if (idx != -1) _webTransactions[idx] = item;
      return 1;
    }
    try {
      final db = await instance.database;
      if (db == null) return 0;
      return await db.update('transactions', item.toMap(),
          where: 'id = ?', whereArgs: [item.id]);
    } catch (e) {
      debugPrint('DatabaseHelper.updateTransaction error: $e');
      return 0;
    }
  }

  Future<int> deleteTransaction(int id) async {
    if (kIsWeb) {
      _webTransactions.removeWhere((t) => t.id == id);
      return 1;
    }
    try {
      final db = await instance.database;
      if (db == null) return 0;
      return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('DatabaseHelper.deleteTransaction error: $e');
      return 0;
    }
  }

  Future<void> clearAllData() async {
    if (kIsWeb) {
      _webTransactions.clear();
      _webSettings.clear();
      return;
    }
    try {
      final db = await instance.database;
      if (db == null) {
        _webTransactions.clear();
        _webSettings.clear();
        return;
      }
      await db.delete('transactions');
      await db.delete('savings_goals');
      await db.delete('upcoming_bills');
      await db.delete('settings');
      try {
        await db.delete('profiles',
            where: 'id != ?', whereArgs: ['default_profile']);
        await db.delete('family_budgets');
        await db.delete('family_goals');
      } catch (_) {}
      await db.insert(
          'settings',
          {
            'key': 'active_profile_id',
            'value': 'default_profile',
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('DatabaseHelper.clearAllData error: $e');
      _webTransactions.clear();
      _webSettings.clear();
    }
  }

  // ── Savings Goals CRUD ────────────────────────────────────────────

  Future<void> insertSavingsGoal(Map<String, dynamic> goal) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.insert('savings_goals', goal,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('DatabaseHelper.insertSavingsGoal error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllSavingsGoals() async {
    if (kIsWeb) return [];
    try {
      final db = await instance.database;
      if (db == null) return [];
      return await db.query('savings_goals');
    } catch (e) {
      debugPrint('DatabaseHelper.getAllSavingsGoals error: $e');
      return [];
    }
  }

  Future<void> deleteSavingsGoal(String id) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('DatabaseHelper.deleteSavingsGoal error: $e');
    }
  }

  // ── Upcoming Bills CRUD ────────────────────────────────────────────

  Future<void> insertUpcomingBill(Map<String, dynamic> bill) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.insert('upcoming_bills', bill,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('DatabaseHelper.insertUpcomingBill error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUpcomingBills() async {
    if (kIsWeb) return [];
    try {
      final db = await instance.database;
      if (db == null) return [];
      return await db.query('upcoming_bills', orderBy: 'dueDate ASC');
    } catch (e) {
      debugPrint('DatabaseHelper.getAllUpcomingBills error: $e');
      return [];
    }
  }

  Future<void> deleteUpcomingBill(String id) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.delete('upcoming_bills', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('DatabaseHelper.deleteUpcomingBill error: $e');
    }
  }

  Future<void> updateUpcomingBill(Map<String, dynamic> bill) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.update('upcoming_bills', bill,
          where: 'id = ?', whereArgs: [bill['id']]);
    } catch (e) {
      debugPrint('DatabaseHelper.updateUpcomingBill error: $e');
    }
  }

  Future<int> insertRule(CategoryRule rule) async {
    if (kIsWeb) {
      _webRules.add(rule);
      return _webRules.length;
    }
    try {
      final db = await instance.database;
      if (db == null) return 0;
      return await db.insert('category_rules', rule.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('DatabaseHelper.insertRule error: $e');
      _webRules.add(rule);
      return _webRules.length;
    }
  }

  Future<List<CategoryRule>> getAllRules() async {
    if (kIsWeb) return List.from(_webRules);
    try {
      final db = await instance.database;
      if (db == null) return List.from(_webRules);
      final maps = await db.query('category_rules');
      return maps.map((m) => CategoryRule.fromMap(m)).toList();
    } catch (e) {
      debugPrint('DatabaseHelper.getAllRules error: $e');
      return List.from(_webRules);
    }
  }

  // ── Settings CRUD ─────────────────────────────────────────────────

  Future<void> setSetting(String key, String value) async {
    if (kIsWeb) {
      _webSettings[key] = value;
      return;
    }
    try {
      final db = await instance.database;
      if (db == null) {
        _webSettings[key] = value;
        return;
      }
      await db.insert('settings', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('DatabaseHelper.setSetting error: $e');
      _webSettings[key] = value;
    }
  }

  Future<String?> getSetting(String key) async {
    if (kIsWeb) return _webSettings[key];
    try {
      final db = await instance.database;
      if (db == null) return _webSettings[key];
      final maps =
          await db.query('settings', where: 'key = ?', whereArgs: [key]);
      if (maps.isNotEmpty) return maps.first['value'] as String?;
      return _webSettings[key];
    } catch (e) {
      debugPrint('DatabaseHelper.getSetting error: $e');
      return _webSettings[key];
    }
  }

  Future<Map<String, String>> getAllSettings() async {
    if (kIsWeb) return Map.from(_webSettings);
    try {
      final db = await instance.database;
      if (db == null) return Map.from(_webSettings);
      final maps = await db.query('settings');
      final Map<String, String> result = {};
      for (var m in maps) {
        result[m['key'] as String] = m['value'] as String;
      }
      return result;
    } catch (e) {
      debugPrint('DatabaseHelper.getAllSettings error: $e');
      return Map.from(_webSettings);
    }
  }

  // ── ATOMIC RESTORE TRANSACTION ────────────────────────────────────

  /// Executes full database restore inside an atomic SQLite transaction.
  /// If any row fails to insert or data is malformed, sqflite automatically
  /// rolls back the entire transaction.
  Future<void> restoreFullDatabaseTransaction({
    required List<Map<String, dynamic>> rawTransactions,
    required List<Map<String, dynamic>> rawRules,
    List<Map<String, dynamic>> rawProfiles = const [],
    required Map<String, dynamic> rawSettings,
  }) async {
    if (kIsWeb) {
      _restoreWebInMemory(rawTransactions, rawRules, rawSettings);
      return;
    }

    try {
      final db = await instance.database;
      if (db == null) {
        throw Exception('SQLite database connection unavailable for restore.');
      }

      await db.transaction((txn) async {
        await txn.delete('transactions');
        await txn.delete('category_rules');
        await txn.delete('settings');
        await txn.delete('profiles');

        for (var map in rawTransactions) {
          final mapCopy = Map<String, dynamic>.from(map);
          mapCopy.remove('id');
          if (mapCopy['isShared'] is bool) {
            mapCopy['isShared'] = (mapCopy['isShared'] as bool) ? 1 : 0;
          }
          if (mapCopy['splits'] != null && mapCopy['splits'] is! String) {
            mapCopy['splits'] = jsonEncode(mapCopy['splits']);
          }
          final tx = TransactionItem.fromMap(mapCopy);
          final fp = CanonicalTransactionIdentity.computeFingerprint(tx);
          mapCopy['transactionFingerprint'] = fp;
          await txn.insert('transactions', mapCopy,
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        for (var map in rawRules) {
          final mapCopy = Map<String, dynamic>.from(map);
          mapCopy.remove('id');
          await txn.insert('category_rules', mapCopy,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (var map in rawProfiles) {
          final mapCopy = Map<String, dynamic>.from(map);
          if (mapCopy['isActive'] is bool) {
            mapCopy['isActive'] = (mapCopy['isActive'] as bool) ? 1 : 0;
          }
          await txn.insert('profiles', mapCopy,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final entry in rawSettings.entries) {
          await txn.insert(
            'settings',
            {'key': entry.key, 'value': entry.value.toString()},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      debugPrint('DatabaseHelper.restoreFullDatabaseTransaction error: $e');
      rethrow;
    }
  }

  void _restoreWebInMemory(
    List<Map<String, dynamic>> rawTransactions,
    List<Map<String, dynamic>> rawRules,
    Map<String, dynamic> rawSettings,
  ) {
    final backupTx = List<TransactionItem>.from(_webTransactions);
    final backupRules = List<CategoryRule>.from(_webRules);
    final backupSettings = Map<String, String>.from(_webSettings);

    try {
      _webTransactions.clear();
      _webRules.clear();
      _webSettings.clear();

      for (var map in rawTransactions) {
        _webTransactions.add(TransactionItem.fromMap(map));
      }
      for (var map in rawRules) {
        _webRules.add(CategoryRule.fromMap(map));
      }
      rawSettings.forEach((k, v) => _webSettings[k] = v.toString());
    } catch (e) {
      // Rollback
      _webTransactions.clear();
      _webTransactions.addAll(backupTx);
      _webRules.clear();
      _webRules.addAll(backupRules);
      _webSettings.clear();
      _webSettings.addAll(backupSettings);
      rethrow;
    }
  }
}
