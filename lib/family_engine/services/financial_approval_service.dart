import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../services/database_helper.dart';
import '../models/spending_request_model.dart';

class FinancialApprovalService {
  static final FinancialApprovalService instance =
      FinancialApprovalService._init();
  FinancialApprovalService._init();

  final List<SpendingRequest> _inMemoryCache = [];

  /// Returns pending requests from memory cache synchronously.
  List<SpendingRequest> getPendingRequests({String? requesterId}) {
    if (requesterId != null && requesterId.isNotEmpty) {
      return _inMemoryCache
          .where((r) =>
              r.status == SpendingRequestStatus.pending &&
              (r.requesterId == requesterId || r.familyId == 'fam_main'))
          .toList();
    }
    return _inMemoryCache
        .where((r) => r.status == SpendingRequestStatus.pending)
        .toList();
  }

  /// Asynchronously fetches pending requests from SQLite and updates memory cache.
  Future<List<SpendingRequest>> fetchPendingRequests(
      {String? requesterId}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      if (db == null) return getPendingRequests(requesterId: requesterId);

      final List<Map<String, dynamic>> maps;
      if (requesterId != null && requesterId.isNotEmpty) {
        maps = await db.query(
          'family_approval_requests',
          where: 'status = ? AND (requesterId = ? OR familyId = ?)',
          whereArgs: ['pending', requesterId, 'fam_main'],
          orderBy: 'createdAt DESC',
        );
      } else {
        maps = await db.query(
          'family_approval_requests',
          where: 'status = ?',
          whereArgs: ['pending'],
          orderBy: 'createdAt DESC',
        );
      }

      final dbRequests = maps.map((m) => SpendingRequest.fromMap(m)).toList();
      _syncCache(dbRequests);
      return dbRequests;
    } catch (e) {
      debugPrint('FinancialApprovalService.fetchPendingRequests error: $e');
      return getPendingRequests(requesterId: requesterId);
    }
  }

  /// Adds a new spending request and persists it to SQLite.
  Future<void> addRequest(SpendingRequest request) async {
    _inMemoryCache.add(request);
    try {
      final db = await DatabaseHelper.instance.database;
      if (db == null) return;
      await db.insert(
        'family_approval_requests',
        request.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('FinancialApprovalService.addRequest error: $e');
    }
  }

  /// Approves a spending request and persists status to SQLite.
  Future<void> approveRequest(String requestId) async {
    _updateStatusInMemory(requestId, SpendingRequestStatus.approved);
    try {
      final db = await DatabaseHelper.instance.database;
      if (db == null) return;
      await db.update(
        'family_approval_requests',
        {'status': SpendingRequestStatus.approved.name},
        where: 'id = ?',
        whereArgs: [requestId],
      );
    } catch (e) {
      debugPrint('FinancialApprovalService.approveRequest error: $e');
    }
  }

  /// Declines a spending request and persists status to SQLite.
  Future<void> declineRequest(String requestId) async {
    _updateStatusInMemory(requestId, SpendingRequestStatus.declined);
    try {
      final db = await DatabaseHelper.instance.database;
      if (db == null) return;
      await db.update(
        'family_approval_requests',
        {'status': SpendingRequestStatus.declined.name},
        where: 'id = ?',
        whereArgs: [requestId],
      );
    } catch (e) {
      debugPrint('FinancialApprovalService.declineRequest error: $e');
    }
  }

  /// Deletes a request from SQLite and memory cache.
  Future<void> deleteRequest(String requestId) async {
    _inMemoryCache.removeWhere((r) => r.id == requestId);
    try {
      final db = await DatabaseHelper.instance.database;
      if (db == null) return;
      await db.delete(
        'family_approval_requests',
        where: 'id = ?',
        whereArgs: [requestId],
      );
    } catch (e) {
      debugPrint('FinancialApprovalService.deleteRequest error: $e');
    }
  }

  /// Resets in-memory cache and SQLite table for test setup.
  Future<void> clearForTest() async {
    _inMemoryCache.clear();
    try {
      final db = await DatabaseHelper.instance.database;
      if (db == null) return;
      await db.delete('family_approval_requests');
    } catch (_) {}
  }

  void _updateStatusInMemory(
      String requestId, SpendingRequestStatus newStatus) {
    final idx = _inMemoryCache.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final req = _inMemoryCache[idx];
      _inMemoryCache[idx] = SpendingRequest(
        id: req.id,
        familyId: req.familyId,
        requesterId: req.requesterId,
        requesterName: req.requesterName,
        title: req.title,
        amount: req.amount,
        reason: req.reason,
        status: newStatus,
        createdAt: req.createdAt,
      );
    }
  }

  void _syncCache(List<SpendingRequest> dbRequests) {
    for (final r in dbRequests) {
      final idx = _inMemoryCache.indexWhere((c) => c.id == r.id);
      if (idx == -1) {
        _inMemoryCache.add(r);
      } else {
        _inMemoryCache[idx] = r;
      }
    }
  }
}
