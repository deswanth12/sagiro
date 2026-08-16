import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import '../views/notification_history_page.dart';

class SmartNotificationCenterCard extends StatefulWidget {
  const SmartNotificationCenterCard({super.key});

  @override
  State<SmartNotificationCenterCard> createState() =>
      _SmartNotificationCenterCardState();
}

class _SmartNotificationCenterCardState
    extends State<SmartNotificationCenterCard> {
  bool _quietModeEnabled = false;
  String _briefingTime = 'smart';
  bool _morningPlanEnabled = true;
  bool _billsEnabled = true;
  bool _goalsEnabled = true;
  bool _weeklyReflectionEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final quiet =
        await DatabaseHelper.instance.getSetting('quiet_mode_enabled') ??
            'false';
    final time =
        await DatabaseHelper.instance.getSetting('morning_briefing_time') ??
            'smart';
    final morning =
        await DatabaseHelper.instance.getSetting('notif_morning_plan') ??
            'true';
    final bills =
        await DatabaseHelper.instance.getSetting('notif_bills') ?? 'true';
    final goals =
        await DatabaseHelper.instance.getSetting('notif_goals') ?? 'true';
    final reflection =
        await DatabaseHelper.instance.getSetting('notif_weekly_reflection') ??
            'true';

    setState(() {
      _quietModeEnabled = quiet == 'true';
      _briefingTime = time;
      _morningPlanEnabled = morning == 'true';
      _billsEnabled = bills == 'true';
      _goalsEnabled = goals == 'true';
      _weeklyReflectionEnabled = reflection == 'true';
    });
  }

  Future<void> _toggleSetting(String key, bool val) async {
    await DatabaseHelper.instance.setSetting(key, val ? 'true' : 'false');
  }

  Future<void> _setBriefingTime(String val) async {
    setState(() => _briefingTime = val);
    await DatabaseHelper.instance.setSetting('morning_briefing_time', val);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppTheme.electricCyan.withOpacity(0.35),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppTheme.electricCyan, size: 20),
                  SizedBox(width: 8),
                  Text('CO-PILOT BRIEFING ENGINE',
                      style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                          letterSpacing: 1.0)),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationHistoryPage())),
                child: const Text('LOG & RATIONALE ➔',
                    style: TextStyle(
                        color: AppTheme.semanticSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 🌙 Quiet Mode Toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _quietModeEnabled
                  ? AppTheme.semanticInfo.withOpacity(0.15)
                  : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _quietModeEnabled
                      ? AppTheme.semanticInfo
                      : Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.nightlight_round,
                    color: AppTheme.semanticInfo, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quiet Day (Silence Routine Alerts)',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      SizedBox(height: 2),
                      Text(
                          'Sagiro stays silent unless critical security requires attention',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 10.5)),
                    ],
                  ),
                ),
                Switch(
                  value: _quietModeEnabled,
                  activeColor: AppTheme.semanticInfo,
                  onChanged: (v) {
                    setState(() => _quietModeEnabled = v);
                    _toggleSetting('quiet_mode_enabled', v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ⏰ Morning Briefing Schedule Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Morning briefing schedule',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTimeChip('smart', 'Smart Time (Learned Habit)'),
                    const SizedBox(width: 6),
                    _buildTimeChip('07:00', '7:00 AM'),
                    const SizedBox(width: 6),
                    _buildTimeChip('08:00', '8:00 AM'),
                    const SizedBox(width: 6),
                    _buildTimeChip('09:00', '9:00 AM'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildNotifSwitch(
            title: 'Morning financial plan',
            subtitle:
                'Safe Today (Adaptive daily plan, only if app not checked)',
            value: _morningPlanEnabled,
            onChanged: (v) {
              setState(() => _morningPlanEnabled = v);
              _toggleSetting('notif_morning_plan', v);
            },
          ),
          const SizedBox(height: 8),
          _buildNotifSwitch(
            title: 'Bills & Actionable Payments',
            subtitle: 'Rent Due Reminders (Actionable reminders only)',
            value: _billsEnabled,
            onChanged: (v) {
              setState(() => _billsEnabled = v);
              _toggleSetting('notif_bills', v);
            },
          ),
          const SizedBox(height: 8),
          _buildNotifSwitch(
            title: 'Goals & Milestones',
            subtitle: 'Goal Completed (Savings celebrations)',
            value: _goalsEnabled,
            onChanged: (v) {
              setState(() => _goalsEnabled = v);
              _toggleSetting('notif_goals', v);
            },
          ),
          const SizedBox(height: 8),
          _buildNotifSwitch(
            title: 'Weekly reflection',
            subtitle: 'Sunday reflection (Weekly summary)',
            value: _weeklyReflectionEnabled,
            onChanged: (v) {
              setState(() => _weeklyReflectionEnabled = v);
              _toggleSetting('notif_weekly_reflection', v);
            },
          ),
          const SizedBox(height: 8),
          _buildLockedSecuritySwitch(
            title: 'Critical security & data protection',
            subtitle: 'Backup verification & local safety (Always active)',
          ),
          const SizedBox(height: 14),

          if (kDebugMode)
            Consumer<BudgetProvider>(
              builder: (context, provider, child) => Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.electricCyan,
                        side: const BorderSide(color: AppTheme.electricCyan),
                        minimumSize: const Size(0, 42),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await NotificationService.instance
                            .triggerMorningReassurance(
                                safeTodayLimit: provider.dailySafeSpendingLimit,
                                spentSoFarToday: provider.todaySpend);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Test Adaptive Briefing Notification triggered!'),
                            backgroundColor: AppTheme.semanticSuccess,
                          ),
                        );
                      },
                      child: const Text('TRIGGER TEST BRIEFING'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String value, String label) {
    final isSelected = _briefingTime == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: AppTheme.electricCyan,
      backgroundColor: AppTheme.darkCard,
      onSelected: (_) => _setBriefingTime(value),
    );
  }

  Widget _buildNotifSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10.5)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.electricCyan,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedSecuritySwitch({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.semanticSuccess.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5)),
                    const SizedBox(width: 6),
                    const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.semanticSuccess, size: 13),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10.5)),
              ],
            ),
          ),
          const Switch(
            value: true,
            onChanged: null,
          ),
        ],
      ),
    );
  }
}
