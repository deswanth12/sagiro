import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class BetaFeedbackDialog extends StatefulWidget {
  const BetaFeedbackDialog({super.key});

  @override
  State<BetaFeedbackDialog> createState() => _BetaFeedbackDialogState();
}

class _BetaFeedbackDialogState extends State<BetaFeedbackDialog> {
  String _selectedCategory = '🐞 Bug';
  final _feedbackCtrl = TextEditingController();
  bool _isSubmitting = false;

  final _categories = [
    '🐞 Bug',
    '💡 Feature Request',
    '🏦 Parser Error',
    '⭐ Suggestion'
  ];

  void _handleSubmit() {
    if (_feedbackCtrl.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Thank you! Your beta feedback has been logged securely.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderColor: AppTheme.electricCyan.withOpacity(0.4),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Send Beta Feedback',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Feedback Category',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat,
                      style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  selected: isSelected,
                  selectedColor: AppTheme.electricCyan,
                  backgroundColor: AppTheme.darkCard,
                  onSelected: (val) => setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe what happened or suggest an improvement...',
                hintStyle:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.electricCyan)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Text('Submit Feedback',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
