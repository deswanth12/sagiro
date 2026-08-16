import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../components/glass_card.dart';
import '../../components/animated_scale_button.dart';
import '../../theme/app_theme.dart';
import '../../providers/budget_provider.dart';
import '../models/family_models.dart';
import '../services/family_service.dart';

class FamilyDashboardPage extends StatefulWidget {
  const FamilyDashboardPage({super.key});

  @override
  State<FamilyDashboardPage> createState() => _FamilyDashboardPageState();
}

class _FamilyDashboardPageState extends State<FamilyDashboardPage> {
  bool _isLoading = true;
  FamilySummary? _summary;
  List<FamilyMember> _members = [];
  List<FamilyBudget> _budgets = [];
  List<FamilyGoal> _goals = [];
  List<FamilyActivityItem> _activities = [];
  String _activeProfileId = FamilyService.kDefaultProfileId;

  static const List<String> _avatarEmojis = [
    '👤',
    '👩',
    '👨',
    '👧',
    '👦',
    '👵',
    '👴',
    '⭐',
    '❤️',
    '🦁',
    '🐱',
    '🚀'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllFamilyData();
  }

  Future<void> _loadAllFamilyData() async {
    setState(() => _isLoading = true);
    final service = FamilyService.instance;
    await service.ensureDefaultProfile();

    final activeId = await service.getActiveProfileId();
    final summary = await service.getFamilySummary();
    final members = await service.getAllProfiles();
    final budgets = await service.getSharedBudgets();
    final goals = await service.getSharedGoals();
    final activities = await service.getRecentSharedActivity();

    if (mounted) {
      setState(() {
        _activeProfileId = activeId;
        _summary = summary;
        _members = members;
        _budgets = budgets;
        _goals = goals;
        _activities = activities;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchProfile(String profileId) async {
    await FamilyService.instance.setActiveProfileId(profileId);
    if (!mounted) return;
    final provider = Provider.of<BudgetProvider>(context, listen: false);
    await provider.loadData();
    await _loadAllFamilyData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched profile to ${_getMemberName(profileId)}'),
          backgroundColor: AppTheme.electricCyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getMemberName(String profileId) {
    for (final m in _members) {
      if (m.id == profileId) return m.name;
    }
    return 'Active Profile';
  }

  String _formatRole(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return 'Primary';
      case FamilyRole.adult:
        return 'Spouse / Adult';
      case FamilyRole.child:
        return 'Child / Student';
      case FamilyRole.guest:
        return 'Parent / Guest';
    }
  }

  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    final relationshipCtrl = TextEditingController(text: 'Spouse');
    FamilyRole selectedRole = FamilyRole.adult;
    String selectedEmoji = '👤';
    final cardBg = AppTheme.cardColor(context);
    final textPri = AppTheme.textPrimaryColor(context);
    final textSec = AppTheme.textSecondaryColor(context);

    final quickChips = [
      'Spouse',
      'Mother',
      'Father',
      'Brother',
      'Sister',
      'Son',
      'Daughter',
      'Friend',
      'Roommate'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Family Member',
              style:
                  TextStyle(color: textPri, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: textPri),
                  decoration: InputDecoration(
                    labelText: 'Member Name (e.g. Rahul, Priya)',
                    labelStyle: const TextStyle(color: AppTheme.electricCyan),
                    filled: true,
                    fillColor: AppTheme.surfaceColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Choose Avatar:',
                    style:
                        TextStyle(color: textSec, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _avatarEmojis.map((e) {
                    final isSel = selectedEmoji == e;
                    return InkWell(
                      onTap: () => setDlgState(() => selectedEmoji = e),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppTheme.electricCyan.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isSel ? AppTheme.electricCyan : AppTheme.cardBorder,
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('Type Relationship / Role:',
                    style:
                        TextStyle(color: textSec, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: relationshipCtrl,
                  style: TextStyle(color: textPri),
                  decoration: InputDecoration(
                    hintText: 'e.g. Mother, Brother, Spouse, Friend',
                    hintStyle: TextStyle(color: textSec.withOpacity(0.7)),
                    filled: true,
                    fillColor: AppTheme.surfaceColor(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    final l = val.toLowerCase();
                    if (l.contains('child') || l.contains('son') || l.contains('daughter')) {
                      selectedRole = FamilyRole.child;
                    } else if (l.contains('parent') || l.contains('mother') || l.contains('father') || l.contains('guest')) {
                      selectedRole = FamilyRole.guest;
                    } else {
                      selectedRole = FamilyRole.adult;
                    }
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: quickChips.map((chip) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: AppTheme.surfaceColor(context),
                          side: const BorderSide(color: AppTheme.cardBorder),
                          label: Text(chip,
                              style: TextStyle(
                                  color: textPri,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                          onPressed: () {
                            setDlgState(() {
                              relationshipCtrl.text = chip;
                              final l = chip.toLowerCase();
                              if (l.contains('child') || l.contains('son') || l.contains('daughter')) {
                                selectedRole = FamilyRole.child;
                              } else if (l.contains('parent') || l.contains('mother') || l.contains('father') || l.contains('guest')) {
                                selectedRole = FamilyRole.guest;
                              } else {
                                selectedRole = FamilyRole.adult;
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final customRel = relationshipCtrl.text.trim();
                if (name.isEmpty) return;

                final displayName = customRel.isNotEmpty
                    ? '$name ($customRel)'
                    : name;

                await FamilyService.instance.createProfile(
                  name: displayName,
                  avatarEmoji: selectedEmoji,
                  role: selectedRole,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                await _loadAllFamilyData();
              },
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMemberDialog(FamilyMember member) {
    final nameCtrl = TextEditingController(text: member.name);
    FamilyRole selectedRole = member.role;
    String selectedEmoji = member.avatarEmoji;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit ${member.name}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Member Name',
                    labelStyle: TextStyle(color: AppTheme.electricCyan),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Choose Avatar:',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _avatarEmojis.map((e) {
                    final isSel = selectedEmoji == e;
                    return InkWell(
                      onTap: () => setDlgState(() => selectedEmoji = e),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppTheme.electricCyan.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isSel ? AppTheme.electricCyan : Colors.white12,
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
                if (member.id != FamilyService.kDefaultProfileId) ...[
                  const SizedBox(height: 14),
                  const Text('Relationship / Role:',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<FamilyRole>(
                    value: selectedRole,
                    dropdownColor: AppTheme.darkCard,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: FamilyRole.adult,
                          child: Text('Spouse / Adult')),
                      DropdownMenuItem(
                          value: FamilyRole.child,
                          child: Text('Child / Student')),
                      DropdownMenuItem(
                          value: FamilyRole.guest,
                          child: Text('Parent / Guest')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedRole = val);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final updated = FamilyMember(
                  id: member.id,
                  name: name,
                  avatarEmoji: selectedEmoji,
                  role: selectedRole,
                  createdAt: member.createdAt,
                  isActive: member.isActive,
                );

                await FamilyService.instance.updateProfile(updated);
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadAllFamilyData();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberDetailsSheet(FamilyMember member) async {
    final stats =
        await FamilyService.instance.getMemberFinancialStats(member.id);
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final isActive = member.id == _activeProfileId;
    final isPrimary = member.id == FamilyService.kDefaultProfileId;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(member.avatarEmoji,
                        style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.electricCyan.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.electricCyan
                                          .withOpacity(0.4)),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: AppTheme.electricCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRole(member.role),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppTheme.electricCyan, size: 20),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditMemberDialog(member);
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 28),

              // Member Financial Contribution Stats
              const Text('MEMBER FINANCIAL SUMMARY',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Shared Expenses',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            currency.format(stats.sharedExpenses),
                            style: const TextStyle(
                                color: AppTheme.warningAmber,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          Text('${stats.sharedCount} shared txn',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Private Vault',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            '${stats.privateCount} txns',
                            style: const TextStyle(
                                color: AppTheme.electricCyan,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          const Text('Isolated to profile',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Actions
              if (!isActive)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  label: const Text('Switch to this Profile',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _switchProfile(member.id);
                  },
                ),

              if (!isPrimary) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.semanticDanger,
                    side: BorderSide(
                        color: AppTheme.semanticDanger.withOpacity(0.5)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Delete Profile'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppTheme.darkCard,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        title: Text('Delete ${member.name}?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        content: Text(
                          'This will delete the profile "${member.name}" and its associated private transactions.\n\nShared family transactions will remain in Family Workspace.',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel',
                                style: TextStyle(color: AppTheme.textMuted)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.semanticDanger),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FamilyService.instance.deleteProfile(member.id);
                      if (mounted) {
                        final provider =
                            Provider.of<BudgetProvider>(context, listen: false);
                        await provider.loadData();
                        await _loadAllFamilyData();
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddBudgetDialog() {
    final catCtrl = TextEditingController(text: 'Groceries');
    final limitCtrl = TextEditingController();
    const suggestions = [
      'Groceries',
      'Food',
      'Rent',
      'Utilities',
      'Bills',
      'Education',
      'Healthcare',
      'Travel',
      'Entertainment'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Shared Budget',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category:',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: catCtrl.text,
                  dropdownColor: AppTheme.darkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: suggestions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => catCtrl.text = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: limitCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Limit (₹)',
                    labelStyle: TextStyle(color: AppTheme.electricCyan),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final cat = catCtrl.text.trim();
                final limit = double.tryParse(limitCtrl.text.trim()) ?? 0.0;
                if (cat.isEmpty || limit <= 0) return;

                await FamilyService.instance
                    .addSharedBudget(category: cat, limitAmount: limit);
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadAllFamilyData();
              },
              child: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(FamilyBudget budget) {
    final limitCtrl =
        TextEditingController(text: budget.limitAmount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit ${budget.category} Budget',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: limitCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Monthly Limit (₹)',
                labelStyle: TextStyle(color: AppTheme.electricCyan),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final limit = double.tryParse(limitCtrl.text.trim()) ?? 0.0;
              if (limit <= 0) return;

              await FamilyService.instance.updateSharedBudget(
                budgetId: budget.id,
                limitAmount: limit,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadAllFamilyData();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Shared Household Goal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Goal Name (e.g. Emergency Fund, Vacation)',
                labelStyle: TextStyle(color: AppTheme.electricCyan),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Target Amount (₹)',
                labelStyle: TextStyle(color: AppTheme.electricCyan),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricMint,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final target = double.tryParse(targetCtrl.text.trim()) ?? 0.0;
              if (title.isEmpty || target <= 0) return;

              await FamilyService.instance
                  .addSharedGoal(title: title, targetAmount: target);
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadAllFamilyData();
            },
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(FamilyGoal goal) {
    final titleCtrl = TextEditingController(text: goal.title);
    final targetCtrl =
        TextEditingController(text: goal.targetAmount.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit ${goal.title}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                labelStyle: TextStyle(color: AppTheme.electricCyan),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: targetCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Target Amount (₹)',
                labelStyle: TextStyle(color: AppTheme.electricCyan),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricMint,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final target = double.tryParse(targetCtrl.text.trim()) ?? 0.0;
              if (title.isEmpty || target <= 0) return;

              await FamilyService.instance.updateSharedGoal(
                goalId: goal.id,
                title: title,
                targetAmount: target,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadAllFamilyData();
            },
            child: const Text('Update Goal'),
          ),
        ],
      ),
    );
  }

  void _showContributeGoalDialog(FamilyGoal goal) {
    final amountCtrl = TextEditingController();
    String contributingMember = _getMemberName(_activeProfileId);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Contribute to ${goal.title}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Contributing Member:',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: contributingMember,
                dropdownColor: AppTheme.darkCard,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _members
                    .map((m) =>
                        DropdownMenuItem(value: m.name, child: Text(m.name)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDlgState(() => contributingMember = val);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Contribution Amount (₹)',
                  labelStyle: TextStyle(color: AppTheme.electricMint),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricMint,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (amt <= 0) return;

                await FamilyService.instance.contributeToSharedGoal(
                  goalId: goal.id,
                  memberName: contributingMember,
                  amount: amt,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadAllFamilyData();
              },
              child: const Text('Contribute'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final textPrimary = AppTheme.textPrimaryColor(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.electricCyan),
        ),
      );
    }

    final summary = _summary ??
        const FamilySummary(
          totalFamilyNetWorth: 0,
          monthlyFamilyIncome: 0,
          monthlyFamilyExpenses: 0,
          monthlyFamilySavings: 0,
          familyHealthScore: 0,
          sharedTransactionCount: 0,
        );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Family Workspace',
            style: TextStyle(
                color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Privacy Shield Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.purpleGlow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.purpleGlow.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: AppTheme.purpleGlow, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🔒 Privacy Guard Active • Personal bank balances and private transactions remain 100% isolated to each profile.',
                      style: TextStyle(
                          color: textPrimary, fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Family Summary Hero Card
            GlassCard(
              borderColor: AppTheme.electricCyan.withOpacity(0.4),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('FAMILY NET POSITION',
                          style: TextStyle(
                              color: AppTheme.electricCyan,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: summary.familyHealthScore > 0
                              ? AppTheme.semanticSuccess.withOpacity(0.15)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          summary.familyHealthScore > 0
                              ? 'Health: ${summary.familyHealthScore}/100'
                              : 'Health: 0/100',
                          style: TextStyle(
                            color: summary.familyHealthScore > 0
                                ? AppTheme.semanticSuccess
                                : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currency.format(summary.totalFamilyNetWorth),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (summary.sharedTransactionCount == 0) ...[
                    const SizedBox(height: 3),
                    const Text(
                      'No shared financial data yet.',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Not enough shared data to calculate family health.',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn(
                          'Shared Income',
                          currency.format(summary.monthlyFamilyIncome),
                          AppTheme.semanticSuccess),
                      _buildStatColumn(
                          'Shared Spent',
                          currency.format(summary.monthlyFamilyExpenses),
                          AppTheme.warningAmber),
                      _buildStatColumn(
                          'Shared Saved',
                          currency.format(summary.monthlyFamilySavings),
                          AppTheme.electricCyan),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Family Members Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Family Members',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_members.length}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _showAddMemberDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded,
                      size: 16, color: AppTheme.electricCyan),
                  label: const Text('Add Member',
                      style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // If only primary exists, show primary + empty secondary helper
            if (_members.length <= 1) ...[
              if (_members.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _showMemberDetailsSheet(_members.first),
                    borderRadius: BorderRadius.circular(16),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      borderColor: AppTheme.electricCyan.withOpacity(0.3),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.electricCyan.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(_members.first.avatarEmoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_members.first.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Text(_formatRole(_members.first.role),
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.electricCyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                  color: AppTheme.electricCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              _buildEmptySectionCard(
                icon: Icons.group_add_outlined,
                title: 'No secondary family members yet',
                subtitle:
                    'Add family members (Spouse, Child, Parent) to manage household finances together while keeping private data isolated.',
                buttonLabel: '+ Add Family Member',
                onTap: _showAddMemberDialog,
              ),
            ] else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _members.map((m) {
                    final isActive = m.id == _activeProfileId;
                    return AnimatedScaleButton(
                      onTap: () => _showMemberDetailsSheet(m),
                      child: Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.electricCyan.withOpacity(0.15)
                              : AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.electricCyan
                                : Colors.white.withOpacity(0.06),
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(m.avatarEmoji,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text(
                              m.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatRole(m.role),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 9.5),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.electricCyan.withOpacity(0.2)
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'SWITCH',
                                style: TextStyle(
                                  color: isActive
                                      ? AppTheme.electricCyan
                                      : AppTheme.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 20),

            // 4. Shared Household Budgets Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Shared Household Budgets',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    if (_budgets.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_budgets.length}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton.icon(
                  onPressed: _showAddBudgetDialog,
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      size: 16, color: AppTheme.electricCyan),
                  label: const Text('Add Budget',
                      style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (_budgets.isEmpty)
              _buildEmptySectionCard(
                icon: Icons.pie_chart_outline_rounded,
                title: 'No shared household budgets yet',
                subtitle:
                    'Create a household budget for groceries, rent, utilities, etc.',
                buttonLabel: '+ Add Household Budget',
                onTap: _showAddBudgetDialog,
              )
            else
              ..._budgets.map((b) {
                final ratio =
                    b.limitAmount > 0 ? (b.totalSpent / b.limitAmount) : 0.0;
                final isOver = b.totalSpent > b.limitAmount;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(b.category,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Row(
                              children: [
                                Text(
                                  '${currency.format(b.totalSpent)} / ${currency.format(b.limitAmount)}',
                                  style: TextStyle(
                                    color: isOver
                                        ? AppTheme.dangerCoral
                                        : AppTheme.electricCyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded,
                                      color: AppTheme.textMuted, size: 18),
                                  color: AppTheme.darkCard,
                                  onSelected: (val) async {
                                    if (val == 'edit') {
                                      _showEditBudgetDialog(b);
                                    } else if (val == 'delete') {
                                      await FamilyService.instance
                                          .deleteSharedBudget(b.id);
                                      await _loadAllFamilyData();
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit Limit',
                                            style: TextStyle(
                                                color: Colors.white))),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete',
                                            style: TextStyle(
                                                color:
                                                    AppTheme.semanticDanger))),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOver
                              ? 'Over budget by ${currency.format(b.totalSpent - b.limitAmount)}'
                              : '${currency.format(b.remaining)} remaining',
                          style: TextStyle(
                            color: isOver
                                ? AppTheme.dangerCoral
                                : AppTheme.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          backgroundColor: Colors.white10,
                          color: isOver
                              ? AppTheme.dangerCoral
                              : AppTheme.electricCyan,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        if (b.memberContributions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: b.memberContributions.entries.map((e) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${e.key}: ${currency.format(e.value)}',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10.5),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // 5. Shared Household Goals Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Shared Household Goals',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    if (_goals.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_goals.length}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton.icon(
                  onPressed: _showAddGoalDialog,
                  icon: const Icon(Icons.flag_outlined,
                      size: 16, color: AppTheme.electricMint),
                  label: const Text('Add Goal',
                      style: TextStyle(
                          color: AppTheme.electricMint,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (_goals.isEmpty)
              _buildEmptySectionCard(
                icon: Icons.savings_outlined,
                title: 'No shared household goals yet',
                subtitle:
                    'Create a shared savings goal for your household (Emergency Fund, Vacation, etc.).',
                buttonLabel: '+ Add Household Goal',
                onTap: _showAddGoalDialog,
              )
            else
              ..._goals.map((g) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(g.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            Row(
                              children: [
                                Text(
                                  '${currency.format(g.totalSaved)} / ${currency.format(g.targetAmount)}',
                                  style: const TextStyle(
                                      color: AppTheme.electricMint,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded,
                                      color: AppTheme.textMuted, size: 18),
                                  color: AppTheme.darkCard,
                                  onSelected: (val) async {
                                    if (val == 'edit') {
                                      _showEditGoalDialog(g);
                                    } else if (val == 'delete') {
                                      await FamilyService.instance
                                          .deleteSharedGoal(g.id);
                                      await _loadAllFamilyData();
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit Goal',
                                            style: TextStyle(
                                                color: Colors.white))),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete',
                                            style: TextStyle(
                                                color:
                                                    AppTheme.semanticDanger))),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (g.progressPercentage / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.white10,
                          color: AppTheme.electricMint,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${g.progressPercentage.toStringAsFixed(0)}% Completed',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppTheme.electricMint.withOpacity(0.2),
                                foregroundColor: AppTheme.electricMint,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _showContributeGoalDialog(g),
                              child: const Text('+ Contribute',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // 6. Recent Shared Activity Section
            const Text('Recent Shared Activity',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 8),

            if (_activities.isEmpty)
              _buildEmptySectionCard(
                icon: Icons.history_rounded,
                title: 'No shared activity yet',
                subtitle:
                    'Shared transactions from family members will appear in this feed.',
                buttonLabel: null,
                onTap: () {},
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final act = _activities[idx];
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Text(act.avatarEmoji,
                              style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${act.profileName} • ${act.description}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy, h:mm a')
                                    .format(act.date),
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${act.isIncome ? '+' : '-'}${currency.format(act.amount)}',
                          style: TextStyle(
                            color: act.isIncome
                                ? AppTheme.semanticSuccess
                                : AppTheme.dangerCoral,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String? buttonLabel,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppTheme.textMuted),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 3),
          Text(subtitle,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
          if (buttonLabel != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan.withOpacity(0.18),
                foregroundColor: AppTheme.electricCyan,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onTap,
              child: Text(buttonLabel,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
