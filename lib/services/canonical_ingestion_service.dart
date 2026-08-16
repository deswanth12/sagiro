import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/transaction_draft.dart';
import '../models/canonical_transaction_identity.dart';
import 'database_helper.dart';

enum IngestionAction {
  insertNew,
  mergeExisting,
  needsReview,
  skipDuplicate,
}

enum IngestionUserChoice {
  autoMerge,
  forceNew,
  skip,
}

class IngestionItemPreview {
  final TransactionDraft draft;
  final IngestionAction suggestedAction;
  final DuplicateConfidenceLevel confidence;
  final TransactionItem? matchedExistingTransaction;
  final String reason;
  final bool isInvalid;
  final String? validationError;

  IngestionItemPreview({
    required this.draft,
    required this.suggestedAction,
    required this.confidence,
    this.matchedExistingTransaction,
    required this.reason,
    this.isInvalid = false,
    this.validationError,
  });

  bool get isReadyToImport =>
      !isInvalid &&
      (suggestedAction == IngestionAction.insertNew ||
          suggestedAction == IngestionAction.mergeExisting);

  bool get isDuplicate =>
      suggestedAction == IngestionAction.mergeExisting ||
      suggestedAction == IngestionAction.skipDuplicate;
}

class IngestionPreviewResult {
  final List<IngestionItemPreview> items;

  IngestionPreviewResult({required this.items});

  int get totalFound => items.length;
  int get newCount =>
      items.where((i) => i.suggestedAction == IngestionAction.insertNew).length;
  int get duplicateCount => items.where((i) => i.isDuplicate).length;
  int get reviewCount => items
      .where((i) => i.suggestedAction == IngestionAction.needsReview)
      .length;
  int get invalidCount => items.where((i) => i.isInvalid).length;

  List<IngestionItemPreview> get newItems => items
      .where((i) => i.suggestedAction == IngestionAction.insertNew)
      .toList();
  List<IngestionItemPreview> get duplicateItems =>
      items.where((i) => i.isDuplicate).toList();
  List<IngestionItemPreview> get reviewItems => items
      .where((i) => i.suggestedAction == IngestionAction.needsReview)
      .toList();
  List<IngestionItemPreview> get invalidItems =>
      items.where((i) => i.isInvalid).toList();
}

class IngestionItemDecision {
  final TransactionDraft draft;
  final IngestionUserChoice userChoice;
  final TransactionItem? targetExisting;

  IngestionItemDecision({
    required this.draft,
    this.userChoice = IngestionUserChoice.autoMerge,
    this.targetExisting,
  });
}

class IngestionCommitResult {
  final int insertedCount;
  final int mergedCount;
  final int skippedCount;
  final List<String> errors;
  final List<TransactionItem> committedTransactions;

  IngestionCommitResult({
    required this.insertedCount,
    required this.mergedCount,
    required this.skippedCount,
    this.errors = const [],
    this.committedTransactions = const [],
  });

  bool get isSuccess => errors.isEmpty;
}

class SingleIngestionResult {
  final bool isInserted;
  final bool isMerged;
  final bool isSkipped;
  final TransactionItem? finalTransaction;
  final String message;

  SingleIngestionResult({
    required this.isInserted,
    required this.isMerged,
    required this.isSkipped,
    this.finalTransaction,
    required this.message,
  });
}

/// CanonicalIngestionService — Central unified ingestion & cross-source deduplication layer.
/// All 8 sources (SMS, PDF, CSV, Excel, Camera/OCR, Manual, Voice, Backup) route exclusively through this service.
class CanonicalIngestionService {
  static final CanonicalIngestionService instance =
      CanonicalIngestionService._internal();

  CanonicalIngestionService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Analyzes an incoming batch of [TransactionDraft]s against existing database records.
  /// Categorizes every item into New, Duplicate/Merge, Needs Review, or Invalid.
  Future<IngestionPreviewResult> previewBatch({
    required List<TransactionDraft> incoming,
    String? profileId,
  }) async {
    final activeProfileId = profileId ?? 'default_profile';
    final existingTransactions =
        await _dbHelper.getAllTransactions(profileId: activeProfileId);

    final previewItems = <IngestionItemPreview>[];
    final runningBatchItems = <TransactionItem>[];

    for (final draft in incoming) {
      // 1. Validation check
      if (draft.amount <= 0 || draft.merchant.trim().isEmpty) {
        previewItems.add(IngestionItemPreview(
          draft: draft,
          suggestedAction: IngestionAction.skipDuplicate,
          confidence: DuplicateConfidenceLevel.distinct,
          reason: 'Invalid transaction: Non-positive amount or empty merchant.',
          isInvalid: true,
          validationError: 'Amount must be greater than zero.',
        ));
        continue;
      }

      final candidateItem = draft.toTransactionItem();

      // 2. Check against existing DB records
      final dbEvaluation =
          CanonicalTransactionIdentity.evaluateDuplicateAgainstList(
        candidate: candidateItem,
        existingList: existingTransactions,
      );

      if (dbEvaluation.isDuplicate) {
        previewItems.add(IngestionItemPreview(
          draft: draft,
          suggestedAction: IngestionAction.mergeExisting,
          confidence: dbEvaluation.confidence,
          matchedExistingTransaction: dbEvaluation.matchedExisting,
          reason: dbEvaluation.reason,
        ));
        continue;
      }

      if (dbEvaluation.needsUserReview) {
        previewItems.add(IngestionItemPreview(
          draft: draft,
          suggestedAction: IngestionAction.needsReview,
          confidence: dbEvaluation.confidence,
          matchedExistingTransaction: dbEvaluation.matchedExisting,
          reason: dbEvaluation.reason,
        ));
        continue;
      }

      // 3. Check against intra-batch duplicates
      final batchEvaluation =
          CanonicalTransactionIdentity.evaluateDuplicateAgainstList(
        candidate: candidateItem,
        existingList: runningBatchItems,
      );

      if (batchEvaluation.isDuplicate) {
        previewItems.add(IngestionItemPreview(
          draft: draft,
          suggestedAction: IngestionAction.skipDuplicate,
          confidence: batchEvaluation.confidence,
          matchedExistingTransaction: batchEvaluation.matchedExisting,
          reason: 'Intra-batch duplicate: ${batchEvaluation.reason}',
        ));
        continue;
      }

      // 4. Clean new transaction
      runningBatchItems.add(candidateItem);
      previewItems.add(IngestionItemPreview(
        draft: draft,
        suggestedAction: IngestionAction.insertNew,
        confidence: DuplicateConfidenceLevel.distinct,
        reason: 'New financial event',
      ));
    }

    return IngestionPreviewResult(items: previewItems);
  }

  /// Previews a single draft to detect possible/exact duplicates before manual save.
  Future<IngestionItemPreview> previewSingle({
    required TransactionDraft draft,
    String? profileId,
  }) async {
    final result = await previewBatch(
      incoming: [draft],
      profileId: profileId ?? draft.profileId,
    );
    if (result.items.isNotEmpty) {
      return result.items.first;
    }
    return IngestionItemPreview(
      draft: draft,
      suggestedAction: IngestionAction.insertNew,
      confidence: DuplicateConfidenceLevel.distinct,
      reason: 'New financial event',
    );
  }

  Future<void> _lock = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final prevLock = _lock;
    final completer = Completer<void>();
    _lock = completer.future;

    return prevLock.then((_) async {
      try {
        return await action();
      } finally {
        completer.complete();
      }
    });
  }

  /// Commits confirmed decisions atomically to SQLite.
  /// Handles new inserts and cross-source merging with provenance consolidation.
  Future<IngestionCommitResult> commitBatch({
    required List<IngestionItemDecision> decisions,
    String? profileId,
  }) {
    return _synchronized(() async {
      if (decisions.isEmpty) {
        return IngestionCommitResult(
          insertedCount: 0,
          mergedCount: 0,
          skippedCount: 0,
        );
      }

      int inserted = 0;
      int merged = 0;
      int skipped = 0;
      final errors = <String>[];
      final committed = <TransactionItem>[];

      final db = await _dbHelper.database;
      if (db == null) {
        return IngestionCommitResult(
          insertedCount: 0,
          mergedCount: 0,
          skippedCount: decisions.length,
          errors: ['Database connection unavailable.'],
        );
      }

      try {
        await db.transaction((txn) async {
          for (final decision in decisions) {
            final draft = decision.draft;

            if (decision.userChoice == IngestionUserChoice.skip) {
              skipped++;
              continue;
            }

            // Case A: Merge into existing transaction
            if (decision.userChoice == IngestionUserChoice.autoMerge &&
                decision.targetExisting != null) {
              final existing = decision.targetExisting!;
              final incomingItem = draft.toTransactionItem();
              final mergedItem = existing.mergeWith(incomingItem);

              final updateMap = mergedItem.toMap();
              updateMap.remove('id');

              if (existing.id != null) {
                await txn.update(
                  'transactions',
                  updateMap,
                  where: 'id = ?',
                  whereArgs: [existing.id],
                );
                merged++;
                committed.add(mergedItem);
              }
              continue;
            }

            // Case B: Insert as New Transaction (or Force New)
            var itemToInsert = draft.toTransactionItem();
            var fp =
                CanonicalTransactionIdentity.computeFingerprint(itemToInsert);

            if (decision.userChoice == IngestionUserChoice.forceNew) {
              // Disambiguate fingerprint to avoid SQLite unique constraint collision
              fp = '$fp|ALT|${DateTime.now().microsecondsSinceEpoch}';
            }

            itemToInsert = itemToInsert.copyWith(
              transactionFingerprint: fp,
              sourceTypes: [draft.source.name],
            );

            final id = await txn.insert(
              'transactions',
              itemToInsert.toMap(),
            );

            inserted++;
            committed.add(itemToInsert.copyWith(id: id));
          }
        });
      } catch (e) {
        debugPrint('CanonicalIngestionService.commitBatch error: $e');
        errors.add(e.toString());
      }

      return IngestionCommitResult(
        insertedCount: inserted,
        mergedCount: merged,
        skippedCount: skipped,
        errors: errors,
        committedTransactions: committed,
      );
    });
  }

  /// Ingests a single transaction draft through the canonical deduplication pipeline.
  Future<SingleIngestionResult> ingestSingle({
    required TransactionDraft draft,
    String? profileId,
    bool allowAutoMerge = true,
  }) {
    return _synchronized(() async {
      final preview = await previewSingle(
        draft: draft,
        profileId: profileId ?? draft.profileId,
      );

      if (preview.isInvalid) {
        return SingleIngestionResult(
          isInserted: false,
          isMerged: false,
          isSkipped: true,
          message: preview.validationError ?? 'Invalid transaction.',
        );
      }

      if (preview.isDuplicate &&
          allowAutoMerge &&
          preview.matchedExistingTransaction != null) {
        final commit = await _commitBatchInternal(
          decisions: [
            IngestionItemDecision(
              draft: draft,
              userChoice: IngestionUserChoice.autoMerge,
              targetExisting: preview.matchedExistingTransaction,
            )
          ],
          profileId: profileId ?? draft.profileId,
        );

        if (commit.isSuccess && commit.mergedCount > 0) {
          return SingleIngestionResult(
            isInserted: false,
            isMerged: true,
            isSkipped: false,
            finalTransaction: commit.committedTransactions.firstOrNull,
            message:
                'Merged with existing ${preview.matchedExistingTransaction?.displaySource} record.',
          );
        }
      }

      final commit = await _commitBatchInternal(
        decisions: [
          IngestionItemDecision(
            draft: draft,
            userChoice: IngestionUserChoice.forceNew,
          )
        ],
        profileId: profileId ?? draft.profileId,
      );

      return SingleIngestionResult(
        isInserted: commit.insertedCount > 0,
        isMerged: false,
        isSkipped: commit.insertedCount == 0,
        finalTransaction: commit.committedTransactions.firstOrNull,
        message: commit.insertedCount > 0
            ? 'Transaction recorded successfully.'
            : 'Failed to insert transaction.',
      );
    });
  }

  Future<IngestionCommitResult> _commitBatchInternal({
    required List<IngestionItemDecision> decisions,
    String? profileId,
  }) async {
    if (decisions.isEmpty) {
      return IngestionCommitResult(
        insertedCount: 0,
        mergedCount: 0,
        skippedCount: 0,
      );
    }

    int inserted = 0;
    int merged = 0;
    int skipped = 0;
    final errors = <String>[];
    final committed = <TransactionItem>[];

    final db = await _dbHelper.database;
    if (db == null) {
      return IngestionCommitResult(
        insertedCount: 0,
        mergedCount: 0,
        skippedCount: decisions.length,
        errors: ['Database connection unavailable.'],
      );
    }

    try {
      await db.transaction((txn) async {
        for (final decision in decisions) {
          final draft = decision.draft;

          if (decision.userChoice == IngestionUserChoice.skip) {
            skipped++;
            continue;
          }

          if (decision.userChoice == IngestionUserChoice.autoMerge &&
              decision.targetExisting != null) {
            final existing = decision.targetExisting!;
            final incomingItem = draft.toTransactionItem();
            final mergedItem = existing.mergeWith(incomingItem);

            final updateMap = mergedItem.toMap();
            updateMap.remove('id');

            if (existing.id != null) {
              await txn.update(
                'transactions',
                updateMap,
                where: 'id = ?',
                whereArgs: [existing.id],
              );
              merged++;
              committed.add(mergedItem);
            }
            continue;
          }

          var itemToInsert = draft.toTransactionItem();
          var fp =
              CanonicalTransactionIdentity.computeFingerprint(itemToInsert);

          if (decision.userChoice == IngestionUserChoice.forceNew) {
            fp = '$fp|ALT|${DateTime.now().microsecondsSinceEpoch}';
          }

          itemToInsert = itemToInsert.copyWith(
            transactionFingerprint: fp,
            sourceTypes: [draft.source.name],
          );

          final id = await txn.insert(
            'transactions',
            itemToInsert.toMap(),
          );

          inserted++;
          committed.add(itemToInsert.copyWith(id: id));
        }
      });
    } catch (e) {
      debugPrint('CanonicalIngestionService.commitBatch error: $e');
      errors.add(e.toString());
    }

    return IngestionCommitResult(
      insertedCount: inserted,
      mergedCount: merged,
      skippedCount: skipped,
      errors: errors,
      committedTransactions: committed,
    );
  }
}
