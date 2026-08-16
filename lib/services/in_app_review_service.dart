import '../services/database_helper.dart';

class ReviewAnalyticsMetrics {
  final int promptsShown;
  final int acceptedCount;
  final int dismissedCount;
  final int internalFeedbackCount;
  final int playStoreReviewCount;

  ReviewAnalyticsMetrics({
    required this.promptsShown,
    required this.acceptedCount,
    required this.dismissedCount,
    required this.internalFeedbackCount,
    required this.playStoreReviewCount,
  });

  double get acceptedRate =>
      promptsShown > 0 ? (acceptedCount / promptsShown) * 100 : 0.0;
  double get dismissedRate =>
      promptsShown > 0 ? (dismissedCount / promptsShown) * 100 : 0.0;
  double get internalFeedbackRate =>
      promptsShown > 0 ? (internalFeedbackCount / promptsShown) * 100 : 0.0;
  double get playStoreRate =>
      promptsShown > 0 ? (playStoreReviewCount / promptsShown) * 100 : 0.0;
}

class InAppReviewService {
  static final InAppReviewService instance = InAppReviewService._init();
  InAppReviewService._init();

  /// Evaluates whether the user qualifies for the Smart Rating Prompt
  Future<bool> shouldShowRatingPrompt({
    required int totalTransactionsCount,
    required bool hasCompletedConfidenceMoment,
    required bool isSafeTodayPositive,
    required bool hasRecentError,
    required Duration timeSinceLastInteraction,
  }) async {
    // Rule #10: Calm Environment Check + Silent Happiness Rule (30s inactivity)
    if (!isSafeTodayPositive ||
        hasRecentError ||
        timeSinceLastInteraction.inSeconds < 30) {
      return false;
    }

    final installDateStr =
        await DatabaseHelper.instance.getSetting('install_date') ??
            DateTime.now().toIso8601String();
    final installDate = DateTime.tryParse(installDateStr) ?? DateTime.now();
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;

    final sessionCountStr =
        await DatabaseHelper.instance.getSetting('session_count') ?? '1';
    final sessionCount = int.tryParse(sessionCountStr) ?? 1;

    final lastPromptDateStr =
        await DatabaseHelper.instance.getSetting('last_rating_prompt_date');
    final lastPromptDate =
        lastPromptDateStr != null ? DateTime.tryParse(lastPromptDateStr) : null;
    final daysSinceLastPrompt = lastPromptDate != null
        ? DateTime.now().difference(lastPromptDate).inDays
        : 999;

    final hasPreviousInternalFeedback =
        (await DatabaseHelper.instance.getSetting('internal_feedback_given')) ==
            'true';
    final hasAppUpdated = (await DatabaseHelper.instance
            .getSetting('app_updated_since_feedback')) ==
        'true';

    // Review Recovery Engine Rule: If gave 1-3 stars previously, wait for app update + 14 days
    if (hasPreviousInternalFeedback && !hasAppUpdated) return false;

    final meetsCoolOff = daysSinceLastPrompt >= 180;
    final meetsInstallAge = daysSinceInstall >= 14;
    final meetsSessionCount = sessionCount >= 20;
    final meetsTxCount = totalTransactionsCount >= 50;

    return (meetsInstallAge || hasCompletedConfidenceMoment) &&
        (meetsSessionCount || hasCompletedConfidenceMoment) &&
        meetsTxCount &&
        meetsCoolOff;
  }

  Future<bool> isFounderUser(int totalTransactions) async {
    final installDateStr =
        await DatabaseHelper.instance.getSetting('install_date') ??
            DateTime.now().toIso8601String();
    final installDate = DateTime.tryParse(installDateStr) ?? DateTime.now();
    final monthsSinceInstall =
        (DateTime.now().difference(installDate).inDays / 30).floor();

    return monthsSinceInstall >= 6 || totalTransactions >= 500;
  }

  /// Records that rating prompt was presented or rejected
  Future<void> recordPromptPresented() async {
    await DatabaseHelper.instance.setSetting(
        'last_rating_prompt_date', DateTime.now().toIso8601String());
  }

  /// Increment session counter
  Future<void> incrementSessionCount() async {
    final countStr =
        await DatabaseHelper.instance.getSetting('session_count') ?? '0';
    final count = int.tryParse(countStr) ?? 0;
    await DatabaseHelper.instance
        .setSetting('session_count', (count + 1).toString());
  }

  /// Record Aggregate Metrics (Developer Only Privacy-First Analytics)
  Future<void> recordMetric(String metricName) async {
    final countStr =
        await DatabaseHelper.instance.getSetting(metricName) ?? '0';
    final count = int.tryParse(countStr) ?? 0;
    await DatabaseHelper.instance
        .setSetting(metricName, (count + 1).toString());
  }

  Future<ReviewAnalyticsMetrics> getAnalyticsMetrics() async {
    final shown = int.tryParse(
            await DatabaseHelper.instance.getSetting('metric_prompts_shown') ??
                '0') ??
        0;
    final accepted = int.tryParse(
            await DatabaseHelper.instance.getSetting('metric_accepted') ??
                '0') ??
        0;
    final dismissed = int.tryParse(
            await DatabaseHelper.instance.getSetting('metric_dismissed') ??
                '0') ??
        0;
    final feedback = int.tryParse(await DatabaseHelper.instance
                .getSetting('metric_internal_feedback') ??
            '0') ??
        0;
    final playStore = int.tryParse(await DatabaseHelper.instance
                .getSetting('metric_playstore_review') ??
            '0') ??
        0;

    return ReviewAnalyticsMetrics(
      promptsShown: shown,
      acceptedCount: accepted,
      dismissedCount: dismissed,
      internalFeedbackCount: feedback,
      playStoreReviewCount: playStore,
    );
  }
}
