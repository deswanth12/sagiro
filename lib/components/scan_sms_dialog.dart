import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/sms_parser.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class ScanSmsDialog extends StatefulWidget {
  const ScanSmsDialog({super.key});

  @override
  State<ScanSmsDialog> createState() => _ScanSmsDialogState();
}

class _ScanSmsDialogState extends State<ScanSmsDialog> {
  final _smsTextController = TextEditingController();
  TransactionItem? _parsedResult;
  bool _hasSearched = false;

  @override
  void dispose() {
    _smsTextController.dispose();
    super.dispose();
  }

  void _parseInput() {
    final text = _smsTextController.text.trim();
    if (text.isEmpty) return;

    final result = SmsParser.parseSms(text, 'BANK_SMS');
    setState(() {
      _parsedResult = result;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            borderRadius: const BorderRadius.all(Radius.circular(28)),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sms_outlined,
                            color: AppTheme.electricCyan, size: 22),
                        const SizedBox(width: 8),
                        Text('Bank SMS Inbox Scanner',
                            style: TextStyle(
                                color: AppTheme.textPrimaryColor(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textMutedColor(context)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Paste any Bank / UPI SMS text below to test 100% local on-device parsing.',
                  style: TextStyle(
                      color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),

                // SMS Input Area
                TextFormField(
                  controller: _smsTextController,
                  maxLines: 3,
                  style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Debited Rs 350 to Zomato via UPI on AC XX4921. Ref 492103',
                    hintStyle: TextStyle(
                        color: AppTheme.textMutedColor(context), fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.cardColor(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderColor(context))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.borderColor(context))),
                  ),
                  onChanged: (_) => _parseInput(),
                ),
                const SizedBox(height: 14),

                // Parse Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCyan,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.bolt),
                    label: const Text('Parse Bank SMS',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _parseInput,
                  ),
                ),
                const SizedBox(height: 20),

                // Parsed Result Card
                if (_hasSearched) ...[
                  if (_parsedResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppTheme.electricCyan.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppTheme.electricCyan, size: 18),
                              SizedBox(width: 6),
                              Text('Parsed Transaction Found!',
                                  style: TextStyle(
                                      color: AppTheme.electricCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Merchant: ${_parsedResult!.merchant}',
                                  style: TextStyle(
                                      color: AppTheme.textPrimaryColor(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text(
                                  '₹${_parsedResult!.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: AppTheme.electricCyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                              'Type: ${_parsedResult!.type.name.toUpperCase()} • Source: SMS',
                              style: TextStyle(
                                  color: AppTheme.textSecondaryColor(context), fontSize: 12)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Provider.of<BudgetProvider>(context,
                                        listen: false)
                                    .addTransaction(_parsedResult!);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Transaction saved to Dashboard!')),
                                );
                              },
                              child: const Text('Save Parsed Transaction',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerCoral.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.dangerCoral.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: AppTheme.dangerCoral, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No financial transaction pattern detected in this SMS text. Try pasting a valid bank debit/credit message.',
                              style: TextStyle(
                                  color: AppTheme.dangerCoral, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
