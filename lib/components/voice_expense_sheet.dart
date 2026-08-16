import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../providers/budget_provider.dart';
import '../services/voice_expense_service.dart';
import 'glass_card.dart';

class VoiceExpenseSheet extends StatefulWidget {
  const VoiceExpenseSheet({super.key});

  @override
  State<VoiceExpenseSheet> createState() => _VoiceExpenseSheetState();
}

class _VoiceExpenseSheetState extends State<VoiceExpenseSheet>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  final _transcriptCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  ParsedVoiceExpense? _parsedResult;
  bool _isSaving = false;
  late AnimationController _pulseController;
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  String _listeningStatus = 'Tap mic to start speaking or type entry details';

  final List<String> _quickVoiceChips = [
    '🍔 Spent ₹250 on Swiggy lunch',
    '🛒 Paid ₹1200 for groceries at Blinkit',
    '🚗 Uber cab fare ₹320',
    '☕ ₹150 for coffee at Starbucks',
    '⚡ ₹1850 electricity bill',
    '💰 Received ₹25,000 salary',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initSpeech();
    _processText(_transcriptCtrl.text);
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _listeningStatus =
                'Speech error: ${errorNotification.errorMsg}. You can also type below.';
          });
        },
      );
      if (mounted) {
        setState(() {
          _speechAvailable = available;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _speechAvailable = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    _transcriptCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _processText(String text) {
    if (!mounted) return;
    setState(() {
      _parsedResult = VoiceExpenseService.parseVoiceTranscript(text);
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _listeningStatus = 'Stopped listening. Review or edit details below.';
      });
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
    }

    if (_speechAvailable) {
      setState(() {
        _isListening = true;
        _listeningStatus =
            '🎤 Listening... Speak clearly (e.g. "Spent 450 on groceries")';
      });

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _transcriptCtrl.text = result.recognizedWords;
            _transcriptCtrl.selection = TextSelection.fromPosition(
              TextPosition(offset: _transcriptCtrl.text.length),
            );
          });
          _processText(result.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } else {
      _focusNode.requestFocus();
      setState(() {
        _listeningStatus = 'Keyboard active. Type or tap keyboard mic.';
      });
    }
  }

  void _applyQuickChip(String chipText) {
    final cleanText = chipText.substring(2).trim();
    _transcriptCtrl.text = cleanText;
    _transcriptCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _transcriptCtrl.text.length),
    );
    _processText(cleanText);
  }

  Future<void> _handleSaveExpense() async {
    final result = _parsedResult;
    if (result == null || result.amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enter or speak an expense amount (e.g., "Spent ₹250 on lunch")'),
          backgroundColor: AppTheme.warningAmber,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final transaction = TransactionItem(
        amount: result.amount,
        merchant: result.merchant,
        category: result.category,
        type: result.type,
        source: TransactionSource.voice,
        date: DateTime.now(),
        notes:
            'Voice Entry: ${result.rawTranscript.isEmpty ? "Quick Expense" : result.rawTranscript}',
      );

      final provider = Provider.of<BudgetProvider>(context, listen: false);
      await provider.addTransaction(transaction);

      if (mounted) {
        Navigator.pop(context);
        final typeLabel =
            result.type == TransactionType.credit ? 'income' : 'expense';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Saved ₹${result.amount.toStringAsFixed(0)} $typeLabel for ${result.merchant} (${result.category})'),
            backgroundColor: AppTheme.semanticSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry: $e'),
            backgroundColor: AppTheme.dangerCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValidAmount =
        _parsedResult != null && _parsedResult!.amount > 0;
    final isCredit = _parsedResult?.type == TransactionType.credit;
    final bgColor = AppTheme.backgroundColor(context);
    final surfaceBg = AppTheme.surfaceColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic_rounded,
                      color: AppTheme.electricCyan, size: 22),
                  const SizedBox(width: 8),
                  Text('Money Brain™ Voice Entry',
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Animated Pulsing Mic Button
          Center(
            child: GestureDetector(
              onTap: _toggleListening,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glowScale = _isListening
                      ? 1.0 + (_pulseController.value * 0.15)
                      : 1.0;
                  return Transform.scale(
                    scale: glowScale,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? AppTheme.warningAmber
                            : AppTheme.electricCyan,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening
                                    ? AppTheme.warningAmber
                                    : AppTheme.electricCyan)
                                .withOpacity(0.5),
                            blurRadius: _isListening ? 25 : 15,
                            spreadRadius: _isListening ? 6 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_rounded,
                        color: Colors.black,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _listeningStatus,
              style: TextStyle(
                  color:
                      _isListening ? AppTheme.warningAmber : textSecondary,
                  fontSize: 12,
                  fontWeight:
                      _isListening ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // Quick Preset Voice Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _quickVoiceChips.map((chipText) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: surfaceBg,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    label: Text(chipText,
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500)),
                    onPressed: () => _applyQuickChip(chipText),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Transcript Text Field
          TextField(
            controller: _transcriptCtrl,
            focusNode: _focusNode,
            autofocus: true,
            style: TextStyle(color: textPrimary, fontSize: 14),
            onChanged: _processText,
            decoration: InputDecoration(
              hintText: 'Speak or type entry details...',
              hintStyle: TextStyle(color: textSecondary),
              filled: true,
              fillColor: surfaceBg,
              prefixIcon: const Icon(Icons.record_voice_over_rounded,
                  color: AppTheme.electricCyan, size: 20),
              suffixIcon: _transcriptCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: textSecondary, size: 18),
                      onPressed: () {
                        _transcriptCtrl.clear();
                        _processText('');
                      },
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.electricCyan)),
            ),
          ),
          const SizedBox(height: 14),

          // Real-time Parsed Preview Card
          if (hasValidAmount) ...[
            GlassCard(
              borderColor:
                  (isCredit ? AppTheme.semanticSuccess : AppTheme.electricCyan)
                      .withOpacity(0.4),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (isCredit
                              ? AppTheme.semanticSuccess
                              : AppTheme.electricCyan)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(_parsedResult!.categoryEmoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${isCredit ? "+" : "-"}₹${_parsedResult!.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: isCredit
                                    ? AppTheme.semanticSuccess
                                    : textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isCredit
                                        ? AppTheme.semanticSuccess
                                        : AppTheme.semanticInfo)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCredit ? 'INCOME' : 'EXPENSE',
                                style: TextStyle(
                                  color: isCredit
                                      ? AppTheme.semanticSuccess
                                      : AppTheme.semanticInfo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_parsedResult!.merchant} • ${_parsedResult!.category}',
                          style: TextStyle(
                              color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else if (_transcriptCtrl.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.warningAmber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.warningAmber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Specify an amount (e.g., 250, ₹500, or 120 rs)',
                      style:
                          TextStyle(color: AppTheme.warningAmber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasValidAmount
                    ? (isCredit
                        ? AppTheme.semanticSuccess
                        : AppTheme.electricCyan)
                    : AppTheme.darkSurface,
                foregroundColor:
                    hasValidAmount ? Colors.black : AppTheme.textMuted,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed:
                  _isSaving || !hasValidAmount ? null : _handleSaveExpense,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text(
                      hasValidAmount
                          ? (isCredit
                              ? 'Confirm & Save Income'
                              : 'Confirm & Save Expense')
                          : 'Enter Amount to Save',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
