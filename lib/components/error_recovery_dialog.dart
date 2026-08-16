import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorRecoveryDialog extends StatelessWidget {
  final String title;
  final String whatHappened;
  final String dataSafetyNote;
  final String primaryActionText;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const ErrorRecoveryDialog({
    super.key,
    required this.title,
    required this.whatHappened,
    this.dataSafetyNote =
        '🔒 Your existing transactions and local data are 100% safe on this device.',
    required this.primaryActionText,
    required this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String whatHappened,
    String dataSafetyNote =
        '🔒 Your existing transactions and local data are 100% safe on this device.',
    required String primaryActionText,
    required VoidCallback onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
  }) {
    showDialog(
      context: context,
      builder: (_) => ErrorRecoveryDialog(
        title: title,
        whatHappened: whatHappened,
        dataSafetyNote: dataSafetyNote,
        primaryActionText: primaryActionText,
        onPrimaryAction: onPrimaryAction,
        secondaryActionText: secondaryActionText,
        onSecondaryAction: onSecondaryAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppTheme.dangerCoral.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon & Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerCoral.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.dangerCoral, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // What Happened Section
            const Text(
              'WHAT HAPPENED',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              whatHappened,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Data Safety Reassurance Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.electricMint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppTheme.electricMint.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppTheme.electricMint, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dataSafetyNote,
                      style: const TextStyle(
                        color: AppTheme.electricMint,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (secondaryActionText != null) ...[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onSecondaryAction?.call();
                    },
                    child: Text(
                      secondaryActionText!,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onPrimaryAction();
                  },
                  child: Text(
                    primaryActionText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
