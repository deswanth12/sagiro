import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const LogoutDialog({super.key, required this.onConfirm});

  static Future<void> show(BuildContext context,
      {required VoidCallback onConfirm}) {
    return showDialog(
      context: context,
      builder: (_) => LogoutDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.logout, color: AppTheme.dangerCoral),
          SizedBox(width: 10),
          Text('Sign Out?',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ],
      ),
      content: const Text(
        'Your transaction history and settings will remain safe on your device.\n\nOnly your active login session will be cleared.',
        style:
            TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.dangerCoral,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
