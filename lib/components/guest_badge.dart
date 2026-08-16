import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GuestBadge extends StatelessWidget {
  final bool isGuest;

  const GuestBadge({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isGuest ? AppTheme.electricMint : AppTheme.electricCyan)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isGuest ? AppTheme.electricMint : AppTheme.electricCyan)
              .withOpacity(0.4),
        ),
      ),
      child: Text(
        isGuest ? 'GUEST MODE' : 'GOOGLE LINKED',
        style: TextStyle(
          color: isGuest ? AppTheme.electricMint : AppTheme.electricCyan,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
