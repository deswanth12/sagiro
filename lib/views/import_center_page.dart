import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';
import '../providers/budget_provider.dart';
import '../document_engine/models/document_payload.dart';
import '../document_engine/models/statement_result.dart';
import '../document_engine/pipeline/financial_document_engine.dart';
import '../document_engine/preview/import_preview_sheet.dart';
import 'import_history_page.dart';
import 'import_diagnostics_page.dart';
import '../services/database_helper.dart';

import '../document_engine/models/statement_health.dart';
import '../services/saf_document_reader.dart';

class ImportCenterPage extends StatefulWidget {
  const ImportCenterPage({super.key});

  @override
  State<ImportCenterPage> createState() => _ImportCenterPageState();
}

class _ImportCenterPageState extends State<ImportCenterPage> {
  bool _isProcessing = false;

  @override
  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.backgroundColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Import Center',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.history_rounded, color: AppTheme.electricMint),
            tooltip: 'Import History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ImportHistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.build_rounded, color: AppTheme.cyanPulse),
            tooltip: 'Parser Diagnostics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (ctx) => const ImportDiagnosticsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Bank Statement(s)',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Uses Android Storage Access Framework (SAF). Statement parsing is performed 100% on-device.',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Category cards
            _ImportSourceCard(
              title: 'PDF Bank Statement',
              subtitle: 'HDFC, SBI, ICICI, Axis, Kotak, Zerodha, etc.',
              icon: Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFFFF5252),
              onTap: () => _pickAndProcessFile(DocumentFormat.pdf),
            ),
            const SizedBox(height: 12),
            _ImportSourceCard(
              title: 'Excel Statement (.xlsx, .xls)',
              subtitle: 'Bank workbooks & multi-sheet exports',
              icon: Icons.table_chart_rounded,
              iconColor: const Color(0xFF4CAF50),
              onTap: () => _pickAndProcessFile(DocumentFormat.excel),
            ),
            const SizedBox(height: 12),
            _ImportSourceCard(
              title: 'CSV / Text Statement (.csv, .txt)',
              subtitle: 'Standard CSV transaction logs',
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF40C4FF),
              onTap: () => _pickAndProcessFile(DocumentFormat.csv),
            ),
            const SizedBox(height: 12),
            _ImportSourceCard(
              title: 'Camera / Paper Scan (OCR)',
              subtitle: 'Parse receipt & paper statement photos',
              icon: Icons.document_scanner_rounded,
              iconColor: const Color(0xFFFFAB40),
              onTap: () => _pickAndProcessFile(DocumentFormat.ocrImage),
            ),

            const SizedBox(height: 24),

            if (_isProcessing)
              GlassCard(
                child: Row(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.electricCyan),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text('Processing statement in background isolate...',
                          style: TextStyle(color: textPrimary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndProcessFile(DocumentFormat requestedFormat) async {
    try {
      FilePickerResult? fileResult;
      final provider = Provider.of<BudgetProvider>(context, listen: false);

      try {
        if (requestedFormat == DocumentFormat.ocrImage) {
          fileResult = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: true,
            withData: true,
            withReadStream: true,
          );
        } else if (requestedFormat == DocumentFormat.excel) {
          fileResult = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['xlsx', 'xls', 'csv', 'tsv', 'txt'],
            allowMultiple: true,
            withData: true,
            withReadStream: true,
          );
        } else if (requestedFormat == DocumentFormat.pdf) {
          fileResult = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: true,
            withData: true,
            withReadStream: true,
          );
        } else {
          fileResult = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: true,
            withData: true,
            withReadStream: true,
          );
        }
      } catch (e) {
        // Fallback for universal picking
        fileResult = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
          withData: true,
          withReadStream: true,
        );
      }

      if (fileResult == null || fileResult.files.isEmpty) return;

      setState(() => _isProcessing = true);

      final aggregatedItems = <StatementResultItem>[];
      StatementHealth? lastHealth;
      bool isPasswordProtected = false;
      bool isDecryptedSuccessfully = true;
      String? errorMessage;
      DocumentPayload? lastPayload;

      for (final pickedFile in fileResult.files) {
        final readResult = await SafDocumentReader.validateAndRead(pickedFile);
        if (!readResult.isSuccess || readResult.bytes.isEmpty) {
          errorMessage =
              '⚠ Couldn\'t read ${pickedFile.name}. The file might be unavailable, corrupted, or unsupported.';
          break;
        }

        final bytes = readResult.bytes;

        final detectedFormat = DocumentPayload.detectFormat(pickedFile.name);
        final effectiveFormat = detectedFormat != DocumentFormat.unknown
            ? detectedFormat
            : requestedFormat;

        final payload = DocumentPayload(
          bytes: bytes,
          fileName: pickedFile.name,
          format: effectiveFormat,
        );
        lastPayload = payload;

        final result = await FinancialDocumentEngine.instance.processDocument(
          document: payload,
          existingTransactions: provider.transactions,
        );

        if (result.requiresPassword ||
            (result.isPasswordProtected && !result.isDecryptedSuccessfully)) {
          isPasswordProtected = true;
          isDecryptedSuccessfully = false;
          break;
        }

        aggregatedItems.addAll(result.items);
        lastHealth = result.health;
        if (result.errorMessage != null) {
          errorMessage = result.errorMessage;
        }
      }

      setState(() => _isProcessing = false);

      if ((isPasswordProtected && !isDecryptedSuccessfully) &&
          lastPayload != null) {
        _promptPasswordAndRetry(lastPayload);
        return;
      }

      if (aggregatedItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(errorMessage ??
                    '0 valid transactions found in selected statement(s).')),
          );
        }
        return;
      }

      final combinedResult = StatementResult(
        items: aggregatedItems,
        health: lastHealth ??
            StatementHealth(
              healthScore: 90,
              pageCount: 1,
              totalTransactions: aggregatedItems.length,
              openingBalanceVerified: true,
              closingBalanceVerified: true,
              merchantAccuracyPercent: 95,
              duplicatesRemoved: 0,
              parserVersion: 'v2.5.0',
              parseTime: Duration.zero,
            ),
      );

      _showImportPreview(combinedResult);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: ${e.toString()}')),
        );
      }
    }
  }

  void _promptPasswordAndRetry(DocumentPayload initialPayload) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool showPassword = false;
        String? inlineError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor(context),
              title: Text('PDF Password Required',
                  style: TextStyle(
                      color: AppTheme.textPrimaryColor(context), fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This bank statement is password protected. Enter the PDF password to scan it.',
                    style:
                        TextStyle(color: AppTheme.textSecondaryColor(context), fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    style: TextStyle(color: AppTheme.textPrimaryColor(context)),
                    decoration: InputDecoration(
                      labelText: 'PDF Password',
                      labelStyle: const TextStyle(color: AppTheme.electricCyan),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  if (inlineError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      inlineError!,
                      style: const TextStyle(
                          color: AppTheme.semanticDanger, fontSize: 12),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    passwordController.clear();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCyan,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    final pwd = passwordController.text.trim();
                    if (pwd.isEmpty) {
                      setDialogState(() {
                        inlineError = 'Please enter the PDF password.';
                      });
                      return;
                    }

                    // Transient RAM payload
                    final updatedPayload = DocumentPayload(
                      bytes: initialPayload.bytes,
                      fileName: initialPayload.fileName,
                      format: initialPayload.format,
                      password: pwd,
                    );

                    final provider =
                        Provider.of<BudgetProvider>(context, listen: false);
                    final res =
                        await FinancialDocumentEngine.instance.processDocument(
                      document: updatedPayload,
                      existingTransactions: provider.transactions,
                    );

                    if (res.isPasswordProtected &&
                        !res.isDecryptedSuccessfully) {
                      setDialogState(() {
                        inlineError = res.errorMessage ??
                            'Incorrect PDF password. Please try again.';
                      });
                      passwordController.clear();
                      return;
                    }

                    // Security: Clear password controller before closing dialog
                    passwordController.clear();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }

                    if (res.items.isNotEmpty) {
                      _showImportPreview(res);
                    } else {
                      final currentContext = context;
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                              content: Text(res.errorMessage ??
                                  '0 transactions found in PDF.')),
                        );
                      }
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImportPreview(StatementResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ImportPreviewSheet(
        result: result,
        onConfirmImport: (confirmedTxs) async {
          Navigator.pop(ctx);
          final provider = Provider.of<BudgetProvider>(context, listen: false);

          if (confirmedTxs.isNotEmpty) {
            await provider.addTransactionsBatch(confirmedTxs);
          }

          // Persist Import Session Record to SQLite
          await DatabaseHelper.instance.insertImportHistory({
            'id': 'import_${DateTime.now().millisecondsSinceEpoch}',
            'fileName': 'Statement Import',
            'format': 'Document Ingestion',
            'transactions': confirmedTxs.length,
            'duplicates': result.duplicateCount,
            'healthScore': result.health.healthBadge,
            'date': DateTime.now().toIso8601String(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '🎉 Success! ${confirmedTxs.length} transactions imported. ${result.duplicateCount} duplicates skipped.'),
                backgroundColor: AppTheme.electricMint,
              ),
            );
          }
        },
      ),
    );
  }
}

class _ImportSourceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback onTap;

  const _ImportSourceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    // ignore: unused_element
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: AppTheme.textPrimaryColor(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5)),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badgeText!,
                              style: TextStyle(
                                  color: iconColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppTheme.textSecondaryColor(context), fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
