import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class NextBestMoveCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  const NextBestMoveCard({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppTheme.electricCyan.withOpacity(0.35),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.electricCyan.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded,
                color: AppTheme.electricCyan, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR NEXT BEST MOVE',
                  style: TextStyle(
                      color: AppTheme.electricCyan,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0),
                ),
                const SizedBox(height: 3),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: onAction,
            child: Text(actionLabel,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
