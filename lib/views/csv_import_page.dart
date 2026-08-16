import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/csv_importer.dart';
import '../services/saf_document_reader.dart';
import '../services/app_settings_service.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';

class CsvImportPage extends StatefulWidget {
  const CsvImportPage({super.key});

  @override
  State<CsvImportPage> createState() => _CsvImportPageState();
}

class _CsvImportPageState extends State<CsvImportPage> {
  bool _isImporting = false;
  CsvImportResult? _lastResult;
  String? _errorMessage;

  /// SAF System Picker — 0 storage permissions required!
  /// Uses Android Storage Access Framework (SAF) / iOS Document Picker

  Future<void> _pickAndImportCsv() async {
    setState(() {
      _isImporting = true;
      _lastResult = null;
      _errorMessage = null;
    });

    try {
      FilePickerResult? picked;
      try {
        picked = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: true,
          withReadStream: true,
        );
      } catch (_) {
        picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'txt'],
          withData: true,
          withReadStream: true,
        );
      }

      if (picked == null || picked.files.isEmpty) {
        setState(() => _isImporting = false);
        return; // User cancelled
      }

      final targetFile = picked.files.first;
      final readResult = await SafDocumentReader.validateAndRead(targetFile);

      if (!readResult.isSuccess || readResult.text.trim().isEmpty) {
        setState(() {
          _errorMessage =
              '⚠ Couldn\'t read ${targetFile.name}. The file might be unavailable, corrupted, or unsupported.';
          _isImporting = false;
        });
        return;
      }

      if (!mounted) return;
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      final result = CsvImporterService.parseCsv(
        readResult.text,
        fileName: targetFile.name,
        existingTransactions: provider.transactions,
      );

      if (result.transactions.isNotEmpty && mounted) {
        await provider.addTransactionsBatch(result.transactions);
        await AppSettingsService.instance
            .updateLastImportTimestamp(DateTime.now());
      }

      setState(() => _lastResult = result);
    } catch (e) {
      setState(() => _errorMessage =
          'Couldn\'t read this file. Error: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.backgroundColor(context);
    final surfaceColor = AppTheme.surfaceColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('CSV Statement Import',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 6-Step Linear Import Progress Tracker
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStepDot(context, '1. Select',
                      _isImporting || _lastResult != null),
                  _buildStepDot(context, '2. Preview', _lastResult != null),
                  _buildStepDot(context, '3. Validate', _lastResult != null),
                  _buildStepDot(context, '4. Review', _lastResult != null),
                  _buildStepDot(context, '5. Import', _lastResult != null),
                  _buildStepDot(context, '6. Result', _lastResult != null),
                ],
              ),
            ),

            GlassCard(
              child: Column(
                children: [
                  const Icon(Icons.upload_file,
                      size: 48, color: AppTheme.semanticInfo),
                  const SizedBox(height: 14),
                  Text('Import Bank Statements',
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'Supports HDFC, SBI, ICICI, Axis Bank, Kotak CSV exports.\n100% On-Device • Zero Storage Permissions Required.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  AnimatedScaleButton(
                    onTap: _isImporting ? null : _pickAndImportCsv,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.semanticInfo,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isImporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.black, strokeWidth: 2))
                            : const Icon(Icons.folder_open),
                        label: Text(
                            _isImporting ? 'Processing...' : 'Select CSV File',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isImporting ? null : _pickAndImportCsv,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.semanticDanger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.semanticDanger.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.semanticDanger),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                color: AppTheme.semanticDanger,
                                fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              _buildResultCard(_lastResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(BuildContext context, String label, bool isActive) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Column(
      children: [
        Icon(
          isActive
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isActive ? AppTheme.semanticInfo : textSecondary,
          size: 14,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isActive ? textPrimary : textSecondary,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(CsvImportResult result) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final isSuccess = result.transactions.isNotEmpty;
    final color =
        isSuccess ? AppTheme.semanticSuccess : AppTheme.semanticWarning;

    final nonImportedRows = result.rowStatuses
        .where((r) => r.status != CsvRowDisposition.imported)
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                      isSuccess
                          ? Icons.check_circle_outline
                          : Icons.warning_outlined,
                      color: color),
                  const SizedBox(width: 10),
                  Text(
                    isSuccess
                        ? 'Import & Reconciliation Complete'
                        : 'No Transactions Found',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildResultRow('Source Data Rows',
                  '${result.totalSourceDataRows}', textPrimary),
              _buildResultRow('Imported (Valid)',
                  '${result.validTransactionsCount}', AppTheme.semanticSuccess),
              _buildResultRow('Duplicates Skipped', '${result.duplicateCount}',
                  AppTheme.semanticWarning),
              _buildResultRow('Invalid / Unparseable', '${result.invalidCount}',
                  AppTheme.semanticDanger),
              if (result.needsReviewCount > 0)
                _buildResultRow('Needs Review', '${result.needsReviewCount}',
                    AppTheme.semanticInfo),
              const Divider(color: AppTheme.cardBorder, height: 20),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    result.reconciles ? Icons.shield : Icons.error,
                    size: 16,
                    color: result.reconciles
                        ? AppTheme.semanticSuccess
                        : AppTheme.semanticDanger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    result.reconciles
                        ? '100% Reconciled (Zero Silent Skips)'
                        : '⚠ Discrepancy detected in row count',
                    style: TextStyle(
                      color: result.reconciles
                          ? AppTheme.semanticSuccess
                          : AppTheme.semanticDanger,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (nonImportedRows.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: const BorderSide(color: AppTheme.cardBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: Text(
                      'Review ${nonImportedRows.length} Skipped / Invalid Rows',
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () => _showSkippedRowsSheet(nonImportedRows),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showSkippedRowsSheet(List<CsvRowStatus> skippedRows) {
    final bgColor = AppTheme.backgroundColor(context);
    final cardColor = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Skipped / Invalid Rows Review',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Every source row is accounted for with an explicit explanation.',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: skippedRows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = skippedRows[idx];
                    final Color statusColor =
                        item.status == CsvRowDisposition.duplicate
                            ? AppTheme.semanticWarning
                            : item.status == CsvRowDisposition.invalid
                                ? AppTheme.semanticDanger
                                : textSecondary;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Line ${item.rowNumber}',
                                style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.status.name.toUpperCase(),
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.reason,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          if (item.rawLine.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Raw: "${item.rawLine}"',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                  fontFamily: 'monospace'),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    final textSecondary = AppTheme.textSecondaryColor(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
