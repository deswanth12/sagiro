import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FieldConfidence {
  final int dateConfidence; // 0 - 100%
  final int amountConfidence; // 0 - 100%
  final int merchantConfidence; // 0 - 100%
  final int balanceConfidence; // 0 - 100%
  final int referenceConfidence; // 0 - 100%
  final int overallConfidence; // 0 - 100%
  final List<String> reasons;

  const FieldConfidence({
    required this.dateConfidence,
    required this.amountConfidence,
    required this.merchantConfidence,
    required this.balanceConfidence,
    required this.referenceConfidence,
    required this.overallConfidence,
    required this.reasons,
  });

  bool get needsReview => overallConfidence < 85;

  String get summaryReason => reasons.join(' • ');

  Color get color => overallConfidence >= 90
      ? AppTheme.semanticSuccess
      : (overallConfidence >= 75
          ? AppTheme.warningAmber
          : AppTheme.dangerCoral);
}
