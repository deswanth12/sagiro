import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../services/database_helper.dart';

class ImportHistoryPage extends StatefulWidget {
  const ImportHistoryPage({super.key});

  @override
  State<ImportHistoryPage> createState() => _ImportHistoryPageState();
}

class _ImportHistoryPageState extends State<ImportHistoryPage> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await DatabaseHelper.instance.getImportHistory();
    setState(() {
      _history = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import History'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.electricCyan))
          : _history.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final item = _history[idx];
                    final date = DateTime.tryParse(item['date'] as String) ??
                        DateTime.now();

                    return GlassCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.electricCyan.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history_toggle_off,
                                color: AppTheme.electricCyan, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['fileName'] as String,
                                    style: TextStyle(
                                        color: AppTheme.textPrimaryColor(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '${item['format']} • ${DateFormat('dd MMM yyyy, hh:mm a').format(date)}',
                                  style: TextStyle(
                                      color: AppTheme.textMutedColor(context), fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${item['transactions']} Imported • ${item['duplicates']} Duplicates Skipped',
                                  style: const TextStyle(
                                      color: AppTheme.successGreen,
                                      fontSize: 12,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.electricMint.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item['healthScore'] as String? ?? 'Imported',
                              style: const TextStyle(
                                  color: AppTheme.electricMint,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  fontFeatures: [FontFeature.tabularFigures()]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.electricCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history,
                  color: AppTheme.electricCyan, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'No Statements Imported Yet',
              style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your imported PDF, Excel, and CSV statement sessions will be recorded here for full audit trails and replay support.',
              style: TextStyle(
                  color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
