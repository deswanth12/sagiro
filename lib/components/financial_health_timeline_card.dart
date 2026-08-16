import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/financial_health_timeline.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class FinancialHealthTimelineCard extends StatelessWidget {
  final List<FinancialTimelineItem> timelineItems;
  final VoidCallback? onAddTap;

  const FinancialHealthTimelineCard({
    super.key,
    required this.timelineItems,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    if (timelineItems.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome,
                color: AppTheme.electricCyan, size: 36),
            const SizedBox(height: 12),
            Text(
              'Your financial story starts today.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your first expense or import your bank SMS to generate your timeline.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (onAddTap != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAddTap,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add First Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.timeline,
                        color: AppTheme.electricCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Journey',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.electricCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.electricCyan.withOpacity(0.3)),
                ),
                child: Text(
                  '${timelineItems.length} Events',
                  style: const TextStyle(
                      color: AppTheme.electricCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timelineItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = timelineItems[index];
              final dateStr =
                  DateFormat('MMM d, h:mm a').format(item.timestamp);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.accentColor.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.accentColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.accentColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (item.badgeText != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.accentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.badgeText!,
                                    style: TextStyle(
                                      color: item.accentColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dateStr,
                            style: TextStyle(
                                color: AppTheme.textMuted.withOpacity(0.6),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
