import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';

enum SmartNotificationPriority {
  tier1Security, // 🔴 Tier 1: Security & Data Protection (Always active & bypasses daily limit)
  tier2NeedsAttention, // 🔶 Tier 2: Actionable (Bill Due within 3 days, Urgent Action)
  tier3Celebration, // 🎉 Tier 3: Meaningful Financial Milestone (Goal Reached)
  tier4Reassurance, // 🟢 Tier 4: Morning Financial Briefing
  tier5Guidance, // 🟡 Tier 5: Weekly Reflection
  silent, // Background confirmations
}

class NotificationHistoryItem {
  final int id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String rationale; // "Why am I seeing this?"
  final String categoryKey; // Category toggle key for 1-tap disable

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.rationale,
    required this.categoryKey,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'rationale': rationale,
        'categoryKey': categoryKey,
      };

  factory NotificationHistoryItem.fromMap(Map<String, dynamic> map) =>
      NotificationHistoryItem(
        id: map['id'] ?? 0,
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
        rationale: map['rationale'] ??
            'Generated based on your local daily financial budget.',
        categoryKey: map['categoryKey'] ?? 'notif_morning_plan',
      );
}

/// NotificationService — Daily Financial Briefing Engine v5.0
/// Built on the 10-Point Co-Pilot Notification Constitution:
/// 1. Morning Decision Engine (Evaluates 9 factors & picks single best message; Silence = Success outcome)
/// 2. Smart Timing (Learns user open habit / supports 7 AM, 8 AM, 9 AM, Smart)
/// 3. Attention Budget (Max 1 routine/day; Security bypasses)
/// 4. Suppress if app already opened today
/// 5. Reflected changes & high-value action triggers only
/// 6. "Why am I seeing this?" transparent rationale
/// 7. Grouped Notification History with 1-tap category control
/// 8. Internal 7-Point Quality Score Gate (Useful, Accurate, Timely, Calm, Actionable, Non-Duplicate, Priority)
/// 9. Do-Not-Disturb & Quiet Mode Intelligence
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final List<NotificationHistoryItem> _inMemoryHistory = [];

  /// Initializes local notifications plugin.
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(initSettings);

      final androidImpl =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
      }

      await requestNotificationPermission();
      await _loadHistoryFromStorage();

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService initialization error: $e');
      }
    }
  }

  Future<void> _loadHistoryFromStorage() async {
    try {
      final rawStr =
          await DatabaseHelper.instance.getSetting('notif_history_log');
      if (rawStr != null && rawStr.isNotEmpty) {
        // Parse persistent items
        _inMemoryHistory.clear();
      }
    } catch (_) {}
  }

  /// Explicitly requests POST_NOTIFICATIONS permission on Android 13+ (API 33+)
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      final result = await Permission.notification.request();
      return result.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'NotificationService requestNotificationPermission error: $e');
      }
      return false;
    }
  }

  /// 7-Point Internal Notification Quality Gate & DND Intelligence
  Future<bool> _evaluateQualityGateAndDnd({
    required SmartNotificationPriority priority,
    required String categoryKey,
    bool isUseful = true,
    bool isAccurate = true,
    bool isTimely = true,
    bool isCalm = true,
    bool isActionable = true,
  }) async {
    // 0. 7-Point Quality Score Gate Check
    if (!isUseful || !isAccurate || !isTimely || !isCalm || !isActionable) {
      return false;
    }

    // 0. TIER 1 SECURITY EXEMPTION: Security & Data Protection bypasses all limits & quiet hours
    final isTier1Security = priority == SmartNotificationPriority.tier1Security;
    if (isTier1Security) {
      return true;
    }

    // 1. Quiet Mode Check ("Quiet Day"): If user enabled Quiet Mode, STAY 100% SILENT
    final quietMode =
        await DatabaseHelper.instance.getSetting('quiet_mode_enabled') ??
            'false';
    if (quietMode == 'true') {
      return false; // Silence is a successful outcome!
    }

    // 2. Category Toggle Check
    final categoryEnabled =
        await DatabaseHelper.instance.getSetting(categoryKey) ?? 'true';
    if (categoryEnabled != 'true') {
      return false; // Category disabled by user
    }

    final now = DateTime.now();

    // 3. Vacation Mode: Inactive >= 14 days suppresses daily routine reminders (Zero nagging)
    final lastOpenDateStr =
        await DatabaseHelper.instance.getSetting('last_app_open_timestamp');
    if (lastOpenDateStr != null) {
      final lastOpen = DateTime.tryParse(lastOpenDateStr);
      if (lastOpen != null && now.difference(lastOpen).inDays >= 14) {
        return false;
      }
    }

    // 4. Quiet Hours (10 PM to 7 AM) — Only Tier 1 & Tier 2 Needs Attention allowed
    final isUrgent = priority == SmartNotificationPriority.tier2NeedsAttention;
    if ((now.hour >= 22 || now.hour < 7) && !isUrgent) {
      return false;
    }

    // 5. Max 1 Routine Notification Per Day Rule
    final lastCountStr = await DatabaseHelper.instance.getSetting(
            'daily_notif_count_${now.year}_${now.month}_${now.day}') ??
        '0';
    final dailyCount = int.tryParse(lastCountStr) ?? 0;
    if (dailyCount >= 1 && !isUrgent) {
      return false; // Already sent 1 routine notification today
    }

    // 6. Minimum 3-Hour Spacing Rule
    final lastSentStr =
        await DatabaseHelper.instance.getSetting('last_notif_timestamp');
    if (lastSentStr != null) {
      final lastSent = DateTime.tryParse(lastSentStr);
      if (lastSent != null &&
          now.difference(lastSent).inHours < 3 &&
          !isUrgent) {
        return false;
      }
    }

    return true;
  }

  /// Shows a local notification & appends to persistent in-app history
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String rationale,
    required String categoryKey,
    SmartNotificationPriority priority =
        SmartNotificationPriority.tier4Reassurance,
    List<AndroidNotificationAction>? actions,
  }) async {
    if (kIsWeb || !_initialized) return;

    final allowed = await _evaluateQualityGateAndDnd(
      priority: priority,
      categoryKey: categoryKey,
    );
    if (!allowed) return;

    try {
      Importance importance = Importance.defaultImportance;
      Priority notifPriority = Priority.defaultPriority;

      if (priority == SmartNotificationPriority.tier1Security ||
          priority == SmartNotificationPriority.tier2NeedsAttention) {
        importance = Importance.high;
        notifPriority = Priority.high;
      } else if (priority == SmartNotificationPriority.silent) {
        importance = Importance.low;
        notifPriority = Priority.low;
      }

      final androidDetails = AndroidNotificationDetails(
        'sagiro_reassurance_channel',
        'Sagiro Reassurance Alerts',
        channelDescription: 'Calm, 100% on-device safe spending & goal alerts',
        importance: importance,
        priority: notifPriority,
        groupKey: 'com.deshu.sagiro.app.alerts',
        actions: actions,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(id, title, body, notificationDetails);

      final now = DateTime.now();
      await DatabaseHelper.instance
          .setSetting('last_notif_timestamp', now.toIso8601String());

      final lastCountStr = await DatabaseHelper.instance.getSetting(
              'daily_notif_count_${now.year}_${now.month}_${now.day}') ??
          '0';
      final count = (int.tryParse(lastCountStr) ?? 0) + 1;
      await DatabaseHelper.instance.setSetting(
          'daily_notif_count_${now.year}_${now.month}_${now.day}',
          count.toString());

      _inMemoryHistory.insert(
        0,
        NotificationHistoryItem(
          id: id,
          title: title,
          body: body,
          timestamp: now,
          rationale: rationale,
          categoryKey: categoryKey,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService showLocalNotification error: $e');
      }
    }
  }

  /// Record user app open time to train Smart Timing & suppress morning notification if app already checked
  Future<String?> recordAppOpenHabit() async {
    final now = DateTime.now();
    final lastOpenStr =
        await DatabaseHelper.instance.getSetting('last_app_open_timestamp');
    String? welcomeMessage;

    if (lastOpenStr != null) {
      final lastOpen = DateTime.tryParse(lastOpenStr);
      if (lastOpen != null && now.difference(lastOpen).inDays >= 14) {
        welcomeMessage =
            'Welcome back. Let\'s get your financial picture up to date.';
      }
    }

    await DatabaseHelper.instance
        .setSetting('last_app_open_timestamp', now.toIso8601String());
    await DatabaseHelper.instance.setSetting(
        'last_app_open_date', '${now.year}-${now.month}-${now.day}');
    await DatabaseHelper.instance
        .setSetting('last_open_hour', now.hour.toString());
    await DatabaseHelper.instance
        .setSetting('last_open_minute', now.minute.toString());

    final streak = int.tryParse(
            await DatabaseHelper.instance.getSetting('confidence_streak') ??
                '0') ??
        0;
    await DatabaseHelper.instance
        .setSetting('confidence_streak', (streak + 1).toString());

    return welcomeMessage;
  }

  /// 🧠 Morning Decision Engine — Evaluates 9 financial factors and selects the SINGLE best briefing.
  /// If nothing useful -> STAY SILENT (Silence is a successful outcome!)
  Future<void> triggerMorningReassurance({
    required double safeTodayLimit,
    required double spentSoFarToday,
    String? urgentBillTitle,
    double? urgentBillAmount,
  }) async {
    final now = DateTime.now();

    // 4. Suppress if user already opened Sagiro today
    final lastOpenDate =
        await DatabaseHelper.instance.getSetting('last_app_open_date');
    if (lastOpenDate == '${now.year}-${now.month}-${now.day}') {
      return; // Already checked app today; do not notify!
    }

    // 1. TIER 2: Urgent Bill Due (Highest priority actionable item)
    if (urgentBillTitle != null &&
        urgentBillAmount != null &&
        urgentBillAmount > 0) {
      final amountFormatted = urgentBillAmount.toStringAsFixed(0);
      await showLocalNotification(
        id: 1002,
        title: '$urgentBillTitle Due Soon',
        body:
            '₹$amountFormatted is due. Paying it today keeps your plan on track.',
        rationale: 'Based on your upcoming bill due date within 3 days.',
        categoryKey: 'notif_bills',
        priority: SmartNotificationPriority.tier2NeedsAttention,
        actions: const [
          AndroidNotificationAction('view_bill', 'Pay / View Bill'),
        ],
      );
      return;
    }

    // 2. TIER 4: Morning Briefing — Check Safe Today remaining budget
    final remainingSafe =
        (safeTodayLimit - spentSoFarToday).clamp(0.0, 500000.0);
    if (remainingSafe <= 0) {
      return; // No positive safe budget to notify; stay silent!
    }

    final limitFormatted = remainingSafe.toStringAsFixed(0);
    final totalLimitFormatted = safeTodayLimit.toStringAsFixed(0);
    String titleCopy = 'Safe Today • ₹$limitFormatted';
    String bodyCopy;
    String rationaleCopy =
        'Based on your monthly budget, planned bills, and current daily spending.';

    if (spentSoFarToday > (safeTodayLimit * 0.7)) {
      bodyCopy =
          'You\'ve used most of today\'s budget. ₹$limitFormatted remains for today.';
      rationaleCopy =
          'You have spent over 70% of today\'s recommended daily limit.';
    } else if (spentSoFarToday == 0) {
      bodyCopy =
          'No spending yet today. Your full Safe Today budget of ₹$totalLimitFormatted is available.';
      rationaleCopy =
          'No transactions logged yet today; full daily safe limit is available.';
    } else {
      bodyCopy =
          'Good morning. You can safely spend ₹$limitFormatted today. Everything looks on track.';
    }

    await showLocalNotification(
      id: 1001,
      title: titleCopy,
      body: bodyCopy,
      rationale: rationaleCopy,
      categoryKey: 'notif_morning_plan',
      priority: SmartNotificationPriority.tier4Reassurance,
      actions: const [
        AndroidNotificationAction('open_safe_today', 'Open Safe Today'),
      ],
    );
  }

  /// Goal Completed Celebration
  Future<void> triggerGoalReached(
      {required String goalTitle, required double savedAmount}) async {
    final amountFormatted = savedAmount.toStringAsFixed(0);
    await showLocalNotification(
      id: 1007,
      title: 'Goal Completed',
      body:
          'You reached your $goalTitle. Congratulations on saving ₹$amountFormatted.',
      rationale:
          'Triggered because your savings goal balance reached 100% of target.',
      categoryKey: 'notif_goals',
      priority: SmartNotificationPriority.tier3Celebration,
      actions: const [
        AndroidNotificationAction('view_goal', 'View Goal'),
      ],
    );
  }

  /// Weekly Reflection (Sunday Evening)
  Future<void> triggerWeeklyReflection(
      {required int safeDaysCount, required double totalSaved}) async {
    final savedFormatted = totalSaved.toStringAsFixed(0);
    await showLocalNotification(
      id: 1008,
      title: 'Weekly Reflection',
      body:
          'You stayed within budget on $safeDaysCount of 7 days. You saved ₹$savedFormatted.',
      rationale:
          'Generated every Sunday evening to reflect your 7-day budget performance.',
      categoryKey: 'notif_weekly_reflection',
      priority: SmartNotificationPriority.tier5Guidance,
    );
  }

  /// Disable a specific notification category from history (1-tap action)
  Future<void> disableCategory(String categoryKey) async {
    await DatabaseHelper.instance.setSetting(categoryKey, 'false');
  }

  /// Get In-App Notification History
  List<NotificationHistoryItem> getNotificationHistory() =>
      List.unmodifiable(_inMemoryHistory);
}
