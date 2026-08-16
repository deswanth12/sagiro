import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dt.year, dt.month, dt.day);
    final timeStr = DateFormat.jm().format(dt);

    if (itemDate == today) {
      return 'Today • $timeStr';
    } else if (itemDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday • $timeStr';
    } else {
      return '${DateFormat('MMM d').format(dt)} • $timeStr';
    }
  }

  void _showWhyThisAppearedDialog(NotificationHistoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded,
                color: AppTheme.electricCyan, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Why did I see this?',
                style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title,
                style: const TextStyle(
                    color: AppTheme.electricCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 4),
            Text(item.body,
                style: TextStyle(color: AppTheme.textSecondaryColor(context), fontSize: 12.5)),
            Divider(color: AppTheme.borderColor(context), height: 24),
            Text(
              'REASON & RATIONALE',
              style: TextStyle(
                  color: AppTheme.textMutedColor(context),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              item.rationale,
              style: TextStyle(
                  color: AppTheme.textPrimaryColor(context), fontSize: 12.5, height: 1.35),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await NotificationService.instance
                  .disableCategory(item.categoryKey);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  const SnackBar(
                    content:
                        Text('Category notifications disabled in settings.'),
                    backgroundColor: AppTheme.warningAmber,
                  ),
                );
              }
            },
            child: const Text('Turn Off Category',
                style: TextStyle(color: AppTheme.dangerCoral, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = NotificationService.instance.getNotificationHistory();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Co-Pilot Briefing Log',
                style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const Text('100% Local Log • Notification Constitution Active',
                style: TextStyle(
                    color: AppTheme.electricCyan,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        centerTitle: true,
      ),
      body: history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCyan.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_paused_rounded,
                          color: AppTheme.electricCyan, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text('Zero Unnecessary Alerts',
                        style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      'Sagiro strictly obeys the 1-Notification-Per-Day rule. Routine alerts are only delivered when there is real, useful financial information.\n\nSilence is considered a successful outcome.',
                      style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 13,
                          height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = history[index];
                return GlassCard(
                  borderColor: AppTheme.electricCyan.withOpacity(0.2),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppTheme.electricCyan.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.notifications_active_rounded,
                                color: AppTheme.electricCyan,
                                size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(item.title,
                                          style: TextStyle(
                                              color: AppTheme.textPrimaryColor(context),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTimestamp(item.timestamp),
                                      style: TextStyle(
                                          color: AppTheme.textMutedColor(context),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item.body,
                                    style: TextStyle(
                                        color: AppTheme.textSecondaryColor(context),
                                        fontSize: 12,
                                        height: 1.35)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _showWhyThisAppearedDialog(item),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: AppTheme.electricCyan, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Why did I see this?',
                                  style: TextStyle(
                                      color: AppTheme.electricCyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
