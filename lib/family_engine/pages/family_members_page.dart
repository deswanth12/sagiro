import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/glass_card.dart';
import '../../providers/budget_provider.dart';
import '../../theme/app_theme.dart';
import '../models/family_models.dart';
import '../services/family_service.dart';

class FamilyMembersPage extends StatefulWidget {
  final List<FamilyMember>? initialProfiles;
  const FamilyMembersPage({super.key, this.initialProfiles});

  @override
  State<FamilyMembersPage> createState() => _FamilyMembersPageState();
}

class _FamilyMembersPageState extends State<FamilyMembersPage> {
  List<FamilyMember> _profiles = [];
  String _activeProfileId = FamilyService.kDefaultProfileId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfiles != null) {
      _profiles = widget.initialProfiles!;
      _isLoading = false;
    }
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    if (_profiles.isEmpty) {
      setState(() => _isLoading = true);
    }
    final list = await FamilyService.instance.getAllProfiles();
    final activeId = await FamilyService.instance.getActiveProfileId();
    if (mounted) {
      setState(() {
        _profiles = list;
        _activeProfileId = activeId;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddProfileDialog() async {
    final nameController = TextEditingController();
    String selectedEmoji = '👤';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Family Member Profile',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Profile Name',
                  hintText: 'e.g. Spouse, Child, Parent',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👤', '👩', '👨', '👦', '👧', '👴'].map((emoji) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedEmoji = emoji),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedEmoji == emoji
                            ? AppTheme.electricCyan.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final navigator = Navigator.of(context);
                await FamilyService.instance.createProfile(
                  name: nameController.text.trim(),
                  avatarEmoji: selectedEmoji,
                );
                navigator.pop();
                _loadProfiles();
              },
              child: const Text('Create Profile'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteProfile(FamilyMember member) async {
    if (member.id == FamilyService.kDefaultProfileId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Profile "${member.name}"?',
              style: const TextStyle(
                  color: AppTheme.semanticDanger, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete profile "${member.name}"? This action will permanently delete this family profile and all associated local transactions from your device.',
            style: TextStyle(
                color: AppTheme.textPrimaryColor(context), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.semanticDanger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete Profile'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await FamilyService.instance.deleteProfile(member.id);
      if (mounted) {
        final budgetProvider =
            Provider.of<BudgetProvider>(context, listen: false);
        await budgetProvider.loadData();
        await _loadProfiles();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Manage Family Profiles',
            style: TextStyle(
                color: textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.electricCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    borderColor: AppTheme.electricCyan.withOpacity(0.2),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LOCAL FAMILY WORKSPACE',
                            style: TextStyle(
                                color: AppTheme.electricCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        Text(
                          'Separate family members on this device. Each profile retains private dashboards and transaction isolation.',
                          style: TextStyle(
                              color: AppTheme.textSecondaryColor(context),
                              fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.electricCyan,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _showAddProfileDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Member Profile'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Profiles on this Device',
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  ..._profiles.map((m) {
                    final isActive = m.id == _activeProfileId;
                    final isDefault = m.id == FamilyService.kDefaultProfileId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        borderColor: isActive
                            ? AppTheme.electricCyan
                            : AppTheme.cardBorder,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Text(m.avatarEmoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(m.name,
                                          style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      if (isActive) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.electricCyan
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text('ACTIVE',
                                              style: TextStyle(
                                                  color: AppTheme.electricCyan,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isDefault
                                        ? 'Primary Owner Profile'
                                        : 'Member Profile',
                                    style: TextStyle(
                                        color: AppTheme.textSecondaryColor(
                                            context),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (!isActive)
                              TextButton(
                                onPressed: () async {
                                  final provider = Provider.of<BudgetProvider>(
                                      context,
                                      listen: false);
                                  await provider.switchProfile(m.id);
                                  await _loadProfiles();
                                },
                                child: const Text('Switch'),
                              ),
                            if (!isDefault)
                              IconButton(
                                key: Key('delete_profile_${m.id}'),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppTheme.semanticDanger, size: 20),
                                onPressed: () => _confirmDeleteProfile(m),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
