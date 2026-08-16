import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class SmartRatingDialog extends StatefulWidget {
  final int totalTransactions;
  final double totalSaved;
  final int daysWithinBudget;
  final bool isFounder;

  const SmartRatingDialog({
    super.key,
    required this.totalTransactions,
    required this.totalSaved,
    this.daysWithinBudget = 23,
    this.isFounder = false,
  });

  static void showIfEligible(
    BuildContext context, {
    required int totalTransactions,
    required double totalSaved,
    int daysWithinBudget = 23,
    bool isFounder = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => SmartRatingDialog(
        totalTransactions: totalTransactions,
        totalSaved: totalSaved,
        daysWithinBudget: daysWithinBudget,
        isFounder: isFounder,
      ),
    );
  }

  @override
  State<SmartRatingDialog> createState() => _SmartRatingDialogState();
}

class _SmartRatingDialogState extends State<SmartRatingDialog> {
  int _selectedStars = 5;
  bool _showFeedbackInput = false;
  bool _showThankYou = false;
  String _selectedCategory = '💡 Feature Request';
  final TextEditingController _feedbackController = TextEditingController();

  final List<String> _feedbackCategories = const [
    '🐞 Bug',
    '💡 Feature Request',
    '🎨 UI/UX',
    '⚡ Performance',
    '🔒 Privacy',
    '📥 Import',
    '🏦 SMS Parsing',
    '☁️ Private Sync',
    '⭐ Other',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassCard(
        borderColor: AppTheme.electricCyan.withOpacity(0.4),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showThankYou) ...[
              Center(
                  child: Text('💙 Thank You',
                      style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 20))),
              const SizedBox(height: 12),
              Text(
                'Your review helps keep Sagiro independent, private, and focused on people instead of advertising. Because of users like you, we can continue building a finance app that puts trust first.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCyan,
                      foregroundColor: Colors.white),
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: const Text('Join Early Access ✨',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            '🌟 Welcome to Sagiro Early Access! You\'ll receive beta builds first.'),
                        backgroundColor: AppTheme.electricCyan,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done',
                      style:
                          TextStyle(color: AppTheme.textMutedColor(context), fontSize: 12)),
                ),
              ),
            ] else if (_showFeedbackInput) ...[
              Text('How can we make Sagiro better?',
                  style: TextStyle(
                      color: AppTheme.textPrimaryColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 6),
              Text('Select feedback category:',
                  style: TextStyle(color: AppTheme.textMutedColor(context), fontSize: 11)),
              const SizedBox(height: 10),

              // Category Selector Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _feedbackCategories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat,
                        style: TextStyle(
                            color: isSel ? Colors.white : AppTheme.textPrimaryColor(context),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    selected: isSel,
                    selectedColor: AppTheme.electricCyan,
                    backgroundColor: AppTheme.cardColor(context),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'Describe issue or suggestion for core engineering...',
                  hintStyle:
                      TextStyle(color: AppTheme.textMutedColor(context), fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.cardColor(context),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(color: AppTheme.textMutedColor(context))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCyan,
                        foregroundColor: Colors.white),
                    onPressed: () {
                      setState(() => _showThankYou = true);
                    },
                    child: const Text('Send Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ] else ...[
              if (widget.isFounder) ...[
                const Center(
                    child: Text('🌟 Thank You Early Supporter',
                        style: TextStyle(
                            color: AppTheme.warningAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 18))),
                const SizedBox(height: 8),
                Text(
                  'You\'ve been with Sagiro since the beginning. You\'re one of the key people helping us build a better finance app. Has Sagiro made managing your money easier?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontSize: 12.5,
                      height: 1.4),
                ),
              ] else ...[
                Center(
                    child: Text('🎉 One Month Together',
                        style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 18))),
                const SizedBox(height: 10),
                Text(
                  'Over the past month you\'ve tracked ${widget.totalTransactions} transactions, saved ₹${widget.totalSaved.toStringAsFixed(0)}, and stayed within budget for ${widget.daysWithinBudget} days. Has Sagiro made managing your money easier?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontSize: 12.5,
                      height: 1.4),
                ),
              ],
              const SizedBox(height: 16),

              // Star Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  final isFilled = starNum <= _selectedStars;
                  return IconButton(
                    icon: Icon(
                      isFilled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color:
                          isFilled ? AppTheme.warningAmber : AppTheme.textMutedColor(context),
                      size: 32,
                    ),
                    onPressed: () => setState(() => _selectedStars = starNum),
                  );
                }),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    if (_selectedStars == 5) {
                      setState(() => _showThankYou = true);
                    } else {
                      setState(() => _showFeedbackInput = true);
                    }
                  },
                  child: const Text('Submit Rating',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('No thanks',
                      style:
                          TextStyle(color: AppTheme.textMutedColor(context), fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
