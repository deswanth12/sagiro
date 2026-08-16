import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../services/sms_inbox_service.dart';
import '../services/sms_parser.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sagiro — Production Bank SMS Scanner Modal Sheet
//
// End-to-End Flow:
//   1. Request READ_SMS permission if needed
//   2. Read entire accessible SMS inbox on-device (non-blocking, progress updates)
//   3. Filter financial SMS & parse transactions
//   4. O(1) in-memory deduplication against existing DB refs & fingerprints
//   5. Review & Selection UI (Select All / Clear All, confidence badges, edit/skip)
//   6. "Add Selected" → Atomic batch SQLite insert via BudgetProvider
//   7. Timeline, Dashboard, Safe Today & Money Brain immediately updated
// ─────────────────────────────────────────────────────────────────────────────
class SmsScanResultSheet extends StatefulWidget {
  const SmsScanResultSheet({super.key});

  @override
  State<SmsScanResultSheet> createState() => _SmsScanResultSheetState();
}

class _SmsScanResultSheetState extends State<SmsScanResultSheet> {
  // ── State ──────────────────────────────────────────────────────────────────
  _SheetState _stage = _SheetState.scanning;
  SmsReadResult? _result;
  String? _errorMessage;
  String _scanProgressMessage = 'Reading SMS inbox…';
  int _scannedCount = 0;
  int _totalToScan = 0;

  // Selected state aligned with _result.transactions
  List<bool> _selected = [];
  bool _saving = false;
  int _savedCount = 0;

  // Editable transaction cache for user review
  List<TransactionItem> _editableTxList = [];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _startScan();
  }

  // ── Scan Logic ────────────────────────────────────────────────────────────
  Future<void> _startScan() async {
    if (!mounted) return;
    setState(() {
      _stage = _SheetState.scanning;
      _result = null;
      _selected = [];
      _editableTxList = [];
      _errorMessage = null;
      _scannedCount = 0;
      _totalToScan = 0;
      _scanProgressMessage = 'Checking SMS permission…';
    });

    // 1. Permission check
    final granted = await SmsInboxService.instance.requestPermission();
    if (!mounted) return;
    if (!granted) {
      final isPerm =
          await SmsInboxService.instance.isPermissionPermanentlyDenied();
      setState(() => _stage = isPerm
          ? _SheetState.permanentlyDenied
          : _SheetState.permissionDenied);
      return;
    }

    // 2. Fetch existing DB references & fingerprints for O(1) duplicate protection
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    final existingRefs = <String>[];
    final existingFingerprints = <String>[];

    for (final tx in provider.transactions) {
      if (tx.transactionReference != null &&
          tx.transactionReference!.isNotEmpty) {
        existingRefs.add(tx.transactionReference!);
      }
      final fp = SmsParser.generateFingerprint(
        profileId: tx.profileId,
        date: tx.date,
        amount: tx.amount,
        type: tx.type,
        merchant: tx.merchant,
      );
      existingFingerprints.add(fp);
    }

    // 3. Scan inbox with live progress updates
    SmsReadResult result;
    try {
      result = await SmsInboxService.instance.readAndParseBankSms(
        existingReferences: existingRefs,
        existingFingerprints: existingFingerprints,
        profileId: provider.activeProfileId,
        maxMessages: 1000,
        onProgress: (current, total, status) {
          if (!mounted) return;
          setState(() {
            _scannedCount = current;
            _totalToScan = total;
            _scanProgressMessage = status;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _stage = _SheetState.error;
      });
      return;
    }

    if (!mounted) return;

    if (result.hasError) {
      setState(() {
        _errorMessage = result.error;
        _stage = _SheetState.error;
      });
      return;
    }

    if (result.webUnsupported) {
      setState(() => _stage = _SheetState.webUnsupported);
      return;
    }

    if (result.permissionDenied) {
      setState(() => _stage = result.permanentlyDenied
          ? _SheetState.permanentlyDenied
          : _SheetState.permissionDenied);
      return;
    }

    // Initialize selection (default all selected except low confidence)
    final txList = List<TransactionItem>.from(result.transactions);
    final selectedList = List<bool>.generate(
      txList.length,
      (i) {
        if (i < result.parsedItems.length) {
          return !result.parsedItems[i].result.needsReview;
        }
        return true;
      },
    );

    setState(() {
      _result = result;
      _editableTxList = txList;
      _selected = selectedList;
      _stage = txList.isEmpty ? _SheetState.empty : _SheetState.results;
    });
  }

  // ── Selection Helpers ──────────────────────────────────────────────────────
  int get _selectedCount => _selected.where((v) => v).length;
  bool get _allSelected => _selected.isNotEmpty && _selected.every((v) => v);

  void _selectAll() =>
      setState(() => _selected = List.filled(_selected.length, true));
  void _clearAll() =>
      setState(() => _selected = List.filled(_selected.length, false));

  // ── Edit Transaction Dialog ────────────────────────────────────────────────
  void _editTransaction(int index) {
    final tx = _editableTxList[index];
    final merchantCtrl = TextEditingController(text: tx.merchant);
    final amountCtrl =
        TextEditingController(text: tx.amount.toStringAsFixed(2));
    String selectedCat = tx.category;
    TransactionType selectedType = tx.type;

    final categories = [
      'Food',
      'Shopping',
      'Fuel',
      'Travel',
      'Entertainment',
      'Bills',
      'Salary',
      'Investments',
      'Medical',
      'General'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Transaction',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: merchantCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Merchant / Description',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Debit'),
                      selected: selectedType == TransactionType.debit,
                      selectedColor: AppTheme.dangerCoral.withOpacity(0.3),
                      onSelected: (v) {
                        if (v) {
                          setDialogState(
                              () => selectedType = TransactionType.debit);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Credit'),
                      selected: selectedType == TransactionType.credit,
                      selectedColor: AppTheme.successGreen.withOpacity(0.3),
                      onSelected: (v) {
                        if (v) {
                          setDialogState(
                              () => selectedType = TransactionType.credit);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categories.contains(selectedCat)
                      ? selectedCat
                      : 'General',
                  dropdownColor: AppTheme.cardColor(context),
                  style: TextStyle(color: AppTheme.textPrimaryColor(context)),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: TextStyle(color: AppTheme.textPrimaryColor(context))),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedCat = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final amt =
                    double.tryParse(amountCtrl.text.trim()) ?? tx.amount;
                final mer = merchantCtrl.text.trim().isEmpty
                    ? tx.merchant
                    : merchantCtrl.text.trim();

                setState(() {
                  _editableTxList[index] = tx.copyWith(
                    merchant: mer,
                    amount: amt,
                    category: selectedCat,
                    type: selectedType,
                  );
                  _selected[index] = true; // Auto-select when edited
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save & Select',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save Selected to Database ─────────────────────────────────────────────
  Future<void> _addSelected() async {
    final toAdd = <TransactionItem>[];
    for (var i = 0; i < _editableTxList.length; i++) {
      if (_selected[i]) toAdd.add(_editableTxList[i]);
    }
    if (toAdd.isEmpty) return;

    setState(() => _saving = true);
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    final batchResult = await provider.addTransactionsBatch(toAdd);
    if (!mounted) return;

    if (kDebugMode) {
      debugPrint(
          '[SMS Scan] Saved: ${batchResult.insertedCount} | Failed: ${batchResult.failedCount}');
    }

    setState(() {
      _saving = false;
      _savedCount = batchResult.insertedCount;
      _stage = _SheetState.success;
    });
  }

  // ── Build UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Divider(color: AppTheme.borderColor(context), height: 1),
          Flexible(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHandle() => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.borderColor(context),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.electricCyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.document_scanner_rounded,
                color: AppTheme.electricCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bank SMS Scanner',
                    style: TextStyle(
                        color: AppTheme.textPrimaryColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('100% on-device  •  No data leaves your phone',
                    style: TextStyle(
                        color: AppTheme.textMutedColor(context), fontSize: 11, height: 1.3)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppTheme.textMutedColor(context), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _SheetState.initial:
        return _buildInitialState();
      case _SheetState.scanning:
        return _buildScanningState();
      case _SheetState.permissionDenied:
        return _buildPermissionDenied();
      case _SheetState.permanentlyDenied:
        return _buildPermanentlyDenied();
      case _SheetState.webUnsupported:
        return _buildStatusCard(
          icon: Icons.phone_android_rounded,
          color: AppTheme.warningAmber,
          title: 'Android Only Feature',
          message:
              'SMS reading works only on real Android devices. Use Manual Entry, CSV Import, or PDF Statement Import on other platforms.',
        );
      case _SheetState.error:
        return _buildStatusCard(
          icon: Icons.error_outline_rounded,
          color: AppTheme.dangerCoral,
          title: 'Scan Failed',
          message:
              _errorMessage ?? 'An unknown error occurred while reading SMS.',
          trailing: Center(
              child: _buildActionButton(
                  label: 'Retry Scan', onTap: _startScan, outlined: true)),
        );
      case _SheetState.empty:
        return _buildEmptyState();
      case _SheetState.results:
        return _buildResultsState();
      case _SheetState.success:
        return _buildSuccessState();
    }
  }

  // ── States ─────────────────────────────────────────────────────────────────

  Widget _buildInitialState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_rounded,
              color: AppTheme.electricCyan, size: 48),
          const SizedBox(height: 16),
          Text('Scan Bank SMS',
              style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Find financial transactions from your SMS inbox. Your messages are processed locally on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Scan SMS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _startScan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState() {
    final progress = _totalToScan > 0 ? (_scannedCount / _totalToScan) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              color: AppTheme.electricCyan,
              strokeWidth: 3.5,
            ),
          ),
          const SizedBox(height: 24),
          Text('Scanning your SMS…',
              style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            _scanProgressMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.electricCyan,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.isDark(context) ? Colors.white12 : Colors.black12,
                color: AppTheme.electricCyan,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scanning $_scannedCount / $_totalToScan messages',
              style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 11),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Checking financial messages…\nFiltering bank & UPI transactions • SBI · HDFC · ICICI · Axis · Kotak · PayTM · PhonePe',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppTheme.textMutedColor(context), fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return _buildStatusCard(
      icon: Icons.lock_outline_rounded,
      color: AppTheme.warningAmber,
      title: 'SMS Permission Required',
      message:
          'SMS permission is required to scan bank transactions. Your SMS data remains 100% on your device and is never uploaded anywhere.',
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
              label: 'Allow Permission', onTap: _startScan, outlined: false),
        ],
      ),
    );
  }

  Widget _buildPermanentlyDenied() {
    return _buildStatusCard(
      icon: Icons.block_rounded,
      color: AppTheme.dangerCoral,
      title: 'SMS Permission Disabled',
      message:
          'SMS permission is disabled for Sagiro. Please enable SMS permission in Android Settings to allow auto-importing your bank transactions.',
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
              label: 'Open Settings', onTap: openAppSettings, outlined: false),
          const SizedBox(width: 10),
          _buildActionButton(label: 'Retry', onTap: _startScan, outlined: true),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final r = _result;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.electricCyan.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                color: AppTheme.electricCyan, size: 36),
          ),
          const SizedBox(height: 16),
          Text('No financial transactions found',
              style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Your inbox was scanned, but no new bank or payment transactions were detected.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4),
          ),
          if (r != null && r.skippedDuplicates > 0) ...[
            const SizedBox(height: 12),
            Text(
              '(${r.skippedDuplicates} transactions already imported)',
              style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                  label: 'Scan Again', onTap: _startScan, outlined: true),
              const SizedBox(width: 12),
              _buildActionButton(
                  label: 'Done',
                  onTap: () => Navigator.pop(context),
                  outlined: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsState() {
    final r = _result!;
    final txList = _editableTxList;

    return Column(
      children: [
        const SizedBox(height: 12),
        // ── Stats Summary Bar ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('${r.totalInboxMessages}', 'Messages\nScanned',
                    AppTheme.textSecondaryColor(context)),
                _buildStatDivider(context),
                _buildStat('${r.passedToParser}', 'Financial\nDetected',
                    AppTheme.electricCyan),
                _buildStatDivider(context),
                _buildStat('${txList.length}', 'Parsed', AppTheme.successGreen),
                _buildStatDivider(context),
                _buildStat('${r.skippedDuplicates}', 'Duplicates\nSkipped',
                    AppTheme.textMutedColor(context)),
                _buildStatDivider(context),
                _buildStat(
                    '${r.needsReviewCount}',
                    'Needs\nReview',
                    r.needsReviewCount > 0
                        ? AppTheme.warningAmber
                        : AppTheme.textMutedColor(context)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Selection Header Controls ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('$_selectedCount of ${txList.length} selected',
                  style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppTheme.electricCyan,
                ),
                onPressed: _allSelected ? _clearAll : _selectAll,
                child: Text(
                  _allSelected ? 'Clear All' : 'Select All',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ── Transaction Scroll List ─────────────────────────────────────────
        Flexible(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            itemCount: txList.length,
            itemBuilder: (ctx, i) => _buildTransactionCard(txList[i], i),
          ),
        ),

        // ── Bottom Action Bar ───────────────────────────────────────────────
        _buildActionBar(),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionItem tx, int index) {
    final isDebit = tx.type == TransactionType.debit;
    final isSelected = _selected[index];
    final parsedItem =
        (_result?.parsedItems != null && index < _result!.parsedItems.length)
            ? _result!.parsedItems[index]
            : null;

    final confidenceTier = parsedItem?.result.confidenceTier ??
        (tx.transactionReference != null
            ? ConfidenceTier.high
            : ConfidenceTier.medium);

    final isLowConfidence = confidenceTier == ConfidenceTier.low;
    final paymentMethod = parsedItem?.result.paymentMethod ?? 'Bank';
    final bankName = parsedItem?.result.bankName ?? tx.account ?? 'Account';
    final fmt = NumberFormat('#,##,###.##', 'en_IN');
    final dateFmt = DateFormat('d MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.electricCyan.withOpacity(0.06)
            : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.electricCyan.withOpacity(0.4)
              : (isLowConfidence
                  ? AppTheme.warningAmber.withOpacity(0.3)
                  : AppTheme.borderColor(context)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selected[index] = !isSelected),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Custom checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.electricCyan
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.electricCyan
                            : AppTheme.borderColor(context),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Merchant & Amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                tx.merchant,
                                style: TextStyle(
                                  color: AppTheme.textPrimaryColor(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${isDebit ? '−' : '+'}₹${fmt.format(tx.amount)}',
                              style: TextStyle(
                                color: isDebit
                                    ? AppTheme.dangerCoral
                                    : AppTheme.successGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              dateFmt.format(tx.date),
                              style: TextStyle(
                                  color: AppTheme.textMutedColor(context), fontSize: 11),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• $paymentMethod',
                              style: TextStyle(
                                  color: AppTheme.textSecondaryColor(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '• $bankName',
                                style: TextStyle(
                                    color: AppTheme.textMutedColor(context), fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildConfidenceBadge(confidenceTier),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Reference or Low Confidence Warning Row
              if (tx.transactionReference != null || isLowConfidence) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (tx.transactionReference != null) ...[
                      Expanded(
                        child: Text(
                          'Ref: ${tx.transactionReference}',
                          style: TextStyle(
                              color: AppTheme.textMutedColor(context),
                              fontSize: 10,
                              fontFamily: 'monospace'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (isLowConfidence) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _editTransaction(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.warningAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.warningAmber.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 11, color: AppTheme.warningAmber),
                              SizedBox(width: 4),
                              Text('Edit',
                                  style: TextStyle(
                                      color: AppTheme.warningAmber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(ConfidenceTier tier) {
    Color badgeColor;
    String label;
    switch (tier) {
      case ConfidenceTier.high:
        badgeColor = AppTheme.successGreen;
        label = 'HIGH';
        break;
      case ConfidenceTier.medium:
        badgeColor = AppTheme.warningAmber;
        label = 'MED';
        break;
      case ConfidenceTier.low:
        badgeColor = AppTheme.dangerCoral;
        label = '⚠ Review';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: badgeColor.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: badgeColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildActionBar() {
    final count = _selectedCount;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.semanticSuccess.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppTheme.semanticSuccess.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined,
                    color: AppTheme.semanticSuccess, size: 13),
                SizedBox(width: 6),
                Text(
                  'Processed on-device  •  No data uploaded',
                  style: TextStyle(
                      color: AppTheme.semanticSuccess,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: count == 0
                    ? (AppTheme.isDark(context) ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))
                    : AppTheme.electricCyan,
                foregroundColor: count == 0 ? AppTheme.textDisabledColor(context) : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: (count == 0 || _saving) ? null : _addSelected,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white))
                  : Text(
                      count == 0
                          ? 'Select at least one transaction'
                          : 'Add $count Selected to Timeline',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.successGreen, size: 44),
          ),
          const SizedBox(height: 16),
          Text(
            '$_savedCount Transaction${_savedCount != 1 ? 's' : ''} Added!',
            style: TextStyle(
                color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Timeline, Dashboard, and Money Brain are now up to date.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                  label: 'Scan Again', onTap: _startScan, outlined: true),
              const SizedBox(width: 12),
              _buildActionButton(
                  label: 'Done',
                  onTap: () => Navigator.pop(context),
                  outlined: false),
            ],
          ),
        ],
      ),
    );
  }

  // ── Reusable Helpers ───────────────────────────────────────────────────────

  Widget _buildStatusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                    color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4)),
            if (trailing != null) ...[
              const SizedBox(height: 14),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required bool outlined,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : AppTheme.electricCyan,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: outlined ? AppTheme.electricCyan : AppTheme.electricCyan),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: outlined ? AppTheme.electricCyan : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 9.5)),
      ],
    );
  }

  Widget _buildStatDivider(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: AppTheme.borderColor(context),
      );
}

// ── Sheet State Enum ─────────────────────────────────────────────────────────

enum _SheetState {
  initial,
  scanning,
  permissionDenied,
  permanentlyDenied,
  webUnsupported,
  error,
  empty,
  results,
  success,
}
