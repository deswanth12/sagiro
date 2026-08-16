import '../models/account_model.dart';
import '../models/account_type.dart';
import 'account_matching_service.dart';
import '../../models/transaction.dart';

class AccountDetectionService {
  /// Detects and registers accounts from SMS transactions
  static List<AccountModel> processSmsTransactions({
    required List<AccountModel> existingAccounts,
    required List<TransactionItem> smsTransactions,
  }) {
    final List<AccountModel> updatedAccounts = List.from(existingAccounts);

    for (final tx in smsTransactions) {
      final rawAccount = tx.account;
      if (rawAccount == null || rawAccount.isEmpty) {
        continue;
      }
      final match = AccountMatchingService.matchAccount(
        existingAccounts: updatedAccounts,
        rawSenderOrText: tx.source.name,
        rawAccountStr: rawAccount,
        rawNotesOrMerchant: '${tx.merchant} ${tx.notes ?? ""}',
      );

      if (match.isHighConfidenceMatch && match.matchedAccount != null) {
        final idx =
            updatedAccounts.indexWhere((a) => a.id == match.matchedAccount!.id);
        if (idx != -1) {
          final acc = updatedAccounts[idx];
          final newBal = tx.notes?.contains('Bal:') == true
              ? (double.tryParse(RegExp(r'Bal:\s*₹([\d,]+)')
                          .firstMatch(tx.notes!)
                          ?.group(1)
                          ?.replaceAll(',', '') ??
                      '') ??
                  acc.estimatedBalance)
              : (acc.accountType == AccountCategory.creditCard
                  ? acc.estimatedBalance - tx.amount
                  : (tx.type == TransactionType.credit
                      ? acc.estimatedBalance + tx.amount
                      : acc.estimatedBalance - tx.amount));

          updatedAccounts[idx] = acc.copyWith(
            estimatedBalance: newBal,
            lastKnownBalance: newBal,
            lastTransactionDate: tx.date,
          );
        }
      } else {
        // Create new account automatically
        final now = DateTime.now();
        final newAccount = AccountModel(
          id: '${match.candidateBank.toLowerCase().replaceAll(' ', '_')}_${match.candidateLast4}',
          bankName: match.candidateBank,
          accountType: match.candidateCategory,
          nickname:
              '${match.candidateBank} ${match.candidateCategory.displayName}',
          maskedAccountNumber: '••••${match.candidateLast4}',
          estimatedBalance:
              tx.type == TransactionType.credit ? tx.amount : -tx.amount,
          lastKnownBalance:
              tx.type == TransactionType.credit ? tx.amount : -tx.amount,
          iconEmoji: match.candidateCategory.defaultEmoji,
          isPrimary: updatedAccounts.isEmpty,
          lastTransactionDate: tx.date,
          createdAt: now,
          updatedAt: now,
        );

        updatedAccounts.add(newAccount);
      }
    }

    return updatedAccounts;
  }

  /// Detects accounts from PDF statement header text
  static AccountModel processPdfStatement({
    required String pdfText,
    required String filename,
  }) {
    final bank = AccountMatchingService.inferBankName(filename, pdfText);
    final category =
        AccountMatchingService.inferAccountCategory(filename, pdfText);
    final digitsMatch = RegExp(
            r'(?:a\/c|account|card)\s*(?:no\.?|number)?\s*:?\s*[x\*]*(\d{4})',
            caseSensitive: false)
        .firstMatch(pdfText);
    final last4 = digitsMatch?.group(1) ?? '4321';

    final now = DateTime.now();
    return AccountModel(
      id: 'pdf_${bank.toLowerCase().replaceAll(' ', '_')}_$last4',
      bankName: bank,
      accountType: category,
      nickname: '$bank Statement ($last4)',
      maskedAccountNumber: '••••$last4',
      estimatedBalance: 0.0,
      lastKnownBalance: 0.0,
      iconEmoji: category.defaultEmoji,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Detects accounts from CSV / Excel file header metadata
  static AccountModel processCsvExcelImport({
    required String filename,
    required int totalRows,
  }) {
    final bank = AccountMatchingService.inferBankName(filename, '');
    final category = AccountMatchingService.inferAccountCategory(filename, '');
    final now = DateTime.now();

    return AccountModel(
      id: 'csv_${bank.toLowerCase().replaceAll(' ', '_')}_import',
      bankName: bank,
      accountType: category,
      nickname: '$bank CSV Import',
      maskedAccountNumber: '••••CSV',
      estimatedBalance: 0.0,
      lastKnownBalance: 0.0,
      iconEmoji: '📄',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Detects accounts from Camera OCR scan
  static AccountModel processOcrScan({required String ocrRawText}) {
    final bank = AccountMatchingService.inferBankName('', ocrRawText);
    final category =
        AccountMatchingService.inferAccountCategory('', ocrRawText);
    final digitsMatch = RegExp(r'\d{4}').firstMatch(ocrRawText);
    final last4 = digitsMatch?.group(0) ?? '9900';
    final now = DateTime.now();

    return AccountModel(
      id: 'ocr_${bank.toLowerCase().replaceAll(' ', '_')}_$last4',
      bankName: bank,
      accountType: category,
      nickname: '$bank OCR Scan',
      maskedAccountNumber: '••••$last4',
      estimatedBalance: 0.0,
      lastKnownBalance: 0.0,
      iconEmoji: '📷',
      createdAt: now,
      updatedAt: now,
    );
  }
}
