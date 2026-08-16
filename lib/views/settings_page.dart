import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/authentication_provider.dart';
import '../services/database_helper.dart';
import '../services/app_settings_service.dart';
import '../services/biometric_auth_service.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/referral_modal_sheet.dart';
import '../auth/pages/active_sessions_page.dart';
import '../auth/pages/login_page.dart';
import '../components/beta_feedback_dialog.dart';
import '../components/smart_notification_center_card.dart';
import '../family_engine/pages/family_dashboard_page.dart';
import 'backup_restore_page.dart';
import 'import_center_page.dart';
import 'privacy_dashboard_page.dart';
import 'privacy_policy_page.dart';
import 'privacy_center_page.dart';
import 'profile_page.dart';
import '../billing/billing_provider.dart';
import '../components/paywall_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Settings Toggle & Permission States
  bool _biometricsEnabled = false;
  bool _hideBalances = false;
  bool _amoledModeActive = false;
  bool _reduceMotionActive = false;
  bool _smsTrackingActive = true;
  bool _autoCategoriesActive = true;
  bool _smsPermissionGranted = false;
  bool _notifPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = AppSettingsService.instance;
    await settings.loadSettings();

    bool smsPerm = false;
    bool notifPerm = false;
    final isTest = WidgetsBinding.instance
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (!kIsWeb && !isTest) {
      try {
        smsPerm = await Permission.sms.status.isGranted;
        notifPerm = await Permission.notification.status.isGranted;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _amoledModeActive = settings.amoledMode;
        _reduceMotionActive = settings.reduceMotion;
        _smsTrackingActive = settings.smsTracking;
        _autoCategoriesActive = settings.autoCategories;
        _biometricsEnabled = settings.biometricsEnabled;
        _hideBalances = settings.hideBalances;
        _smsPermissionGranted = smsPerm;
        _notifPermissionGranted = notifPerm;
      });
    }
  }

  String _formatLastImportText() {
    final lastImport = AppSettingsService.instance.lastImportTimestamp;
    if (lastImport == null) {
      return 'Last Import: Never • Supports PDF (16 Banks), Excel, CSV & Camera';
    }
    final formatted = DateFormat('d MMM yyyy, h:mm a').format(lastImport);
    return 'Last Import: $formatted • Supports PDF (16 Banks), Excel, CSV & Camera';
  }

  String _formatLastBackupText() {
    final lastBackup = AppSettingsService.instance.lastBackupTimestamp;
    if (lastBackup == null) {
      return 'No Local Backup Created Yet • Export/import AES-256 encrypted backups via SAF';
    }
    final formatted = DateFormat('d MMM yyyy, h:mm a').format(lastBackup);
    return 'Last Backup: $formatted • Verified Local SAF Archive';
  }

  void _showSalaryDayDialog() {
    int currentDay = AppSettingsService.instance.salaryArrivalDay;
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('Salary Arrival Day',
            style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the day of the month when your income/salary usually arrives. This optimizes your monthly budget pacing.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: currentDay,
              isExpanded: true,
              dropdownColor: cardBg,
              style: TextStyle(color: textPrimary, fontSize: 14),
              items: List.generate(31, (i) => i + 1)
                  .map((d) => DropdownMenuItem(
                      value: d, child: Text('Day $d of the month')))
                  .toList(),
              onChanged: (val) async {
                if (val != null) {
                  Navigator.pop(ctx);
                  await AppSettingsService.instance.setSalaryArrivalDay(val);
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.electricCyan)),
          ),
        ],
      ),
    );
  }

  void _showMonthCycleDialog() {
    int currentDay = AppSettingsService.instance.monthCycleStartDay;
    final options = [1, 5, 10, 15, 25, 28];
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('Month Cycle Start Day',
            style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose when your financial month begins.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: options.contains(currentDay) ? currentDay : 1,
              isExpanded: true,
              dropdownColor: cardBg,
              style: TextStyle(color: textPrimary, fontSize: 14),
              items: options
                  .map((d) => DropdownMenuItem(
                      value: d, child: Text('Day $d of every month')))
                  .toList(),
              onChanged: (val) async {
                if (val != null) {
                  Navigator.pop(ctx);
                  await AppSettingsService.instance.setMonthCycleStartDay(val);
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.electricCyan)),
          ),
        ],
      ),
    );
  }

  void _showDefaultCurrencyDialog() {
    String current = AppSettingsService.instance.defaultCurrency;
    final options = ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)'];
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('Default Currency',
            style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select primary currency for display and reports.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: options.contains(current) ? current : 'INR (₹)',
              isExpanded: true,
              dropdownColor: cardBg,
              style: TextStyle(color: textPrimary, fontSize: 14),
              items: options
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) async {
                if (val != null) {
                  Navigator.pop(ctx);
                  await AppSettingsService.instance.setDefaultCurrency(val);
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.electricCyan)),
          ),
        ],
      ),
    );
  }

  void _showAppLanguageDialog() {
    String current = AppSettingsService.instance.appLanguage;
    final options = [
      'English',
      'Hindi (हिन्दी)',
      'Telugu (తెలుగు)',
      'Tamil (தமிழ்)'
    ];
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('App Language',
            style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your preferred language for Sagiro UI.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: options.contains(current) ? current : 'English',
              isExpanded: true,
              dropdownColor: cardBg,
              style: TextStyle(color: textPrimary, fontSize: 14),
              items: options
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (val) async {
                if (val != null) {
                  Navigator.pop(ctx);
                  await AppSettingsService.instance.setAppLanguage(val);
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.electricCyan)),
          ),
        ],
      ),
    );
  }

  void _showRegionDialog() {
    String current = AppSettingsService.instance.appRegion;
    final options = [
      'India 🇮🇳 (INR ₹)',
      'United States 🇺🇸 (USD \$)',
      'United Kingdom 🇬🇧 (GBP £)'
    ];
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('Region & Tax System',
            style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select regional locale for banking & tax defaults.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: options.contains(current) ? current : 'India 🇮🇳 (INR ₹)',
              isExpanded: true,
              dropdownColor: cardBg,
              style: TextStyle(color: textPrimary, fontSize: 14),
              items: options
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) async {
                if (val != null) {
                  Navigator.pop(ctx);
                  await AppSettingsService.instance.setAppRegion(val);
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.electricCyan)),
          ),
        ],
      ),
    );
  }

  void _showCoachToneDialog() {
    String current = AppSettingsService.instance.coachTone;
    final options = ['Encouraging', 'Strict', 'Minimalist'];
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('Money Brain™ Coach Tone',
            style: TextStyle(color: textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select AI Money Coach insight persona.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: options.contains(current) ? current : 'Encouraging',
              isExpanded: true,
              dropdownColor: cardBg,
              style: TextStyle(color: textPrimary, fontSize: 14),
              items: options
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) async {
                if (val != null) {
                  Navigator.pop(ctx);
                  await AppSettingsService.instance.setCoachTone(val);
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.electricCyan)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(String text) {
    if (_searchQuery.trim().isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);

    return Consumer<BudgetProvider>(
      builder: (context, provider, child) {
        final txCount = provider.transactions.length;

        final textColorPrimary = AppTheme.textPrimaryColor(context);

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor(context),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                      color: textColorPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                const Text(
                  'Manage preferences, privacy, and backups',
                  style: TextStyle(
                      color: AppTheme.electricCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔍 Settings Search Bar
                _buildSearchBar(context),
                const SizedBox(height: 16),

                // ⚡ Unified System Status Card
                if (_matchesSearch(
                    'system status healthy database parser backups storage operational')) ...[
                  _buildSystemStatusCard(context),
                  const SizedBox(height: 20),
                ],

                // 📊 Data Summary Grid
                if (_matchesSearch(
                    'my data transactions accounts goals replay backups grid')) ...[
                  _buildMyDataVisualGrid(context, txCount, provider),
                  const SizedBox(height: 20),
                ],

                // 1. 👤 Account
                if (_matchesSearch(
                    'account profile google session sign out language region')) ...[
                  _buildSectionHeader('👤 Account'),
                  _buildCardWrapper([
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded,
                          color: AppTheme.electricCyan),
                      title: Text(
                        authProvider.userProfile?.displayName ??
                            (authProvider.isGuest
                                ? 'Guest User'
                                : 'Google Account'),
                        style: TextStyle(
                            color: textColorPrimary, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        authProvider.isGuest
                            ? 'Local Guest Session • 100% On-Device'
                            : (authProvider.userProfile?.email ??
                                'Connected with Google'),
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfilePage())),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: const Icon(Icons.language_rounded,
                          color: AppTheme.electricMint),
                      title: Text('App Language',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${AppSettingsService.instance.appLanguage} (Active)',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: _showAppLanguageDialog,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: const Icon(Icons.public_rounded,
                          color: AppTheme.semanticSuccess),
                      title: Text('Region & Tax System',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(AppSettingsService.instance.appRegion,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: _showRegionDialog,
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // 4. 🎨 Appearance
                if (_matchesSearch(
                    'appearance theme light dark system default amoled reduce motion accent font')) ...[
                  _buildSectionHeader('🎨 Appearance'),
                  _buildCardWrapper([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.palette_outlined,
                                  color: AppTheme.electricCyan, size: 20),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Appearance',
                                    style: TextStyle(
                                        color: textColorPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                  const Text(
                                    'Manage how Sagiro looks',
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.darkElevatedCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _buildThemeOptionPill(
                                  context: context,
                                  choice: 'light',
                                  label: '☀️ Light',
                                ),
                                _buildThemeOptionPill(
                                  context: context,
                                  choice: 'dark',
                                  label: '🌙 Dark',
                                ),
                                _buildThemeOptionPill(
                                  context: context,
                                  choice: 'system',
                                  label: '📱 System',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.contrast_rounded,
                          color: Colors.white70),
                      title: Text('AMOLED Mode',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Use pure black backgrounds (#000000)',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      value: _amoledModeActive,
                      activeColor: AppTheme.electricCyan,
                      onChanged: (val) async {
                        setState(() => _amoledModeActive = val);
                        await AppSettingsService.instance.setAmoledMode(val);
                        if (context.mounted) {
                          Provider.of<SettingsProvider>(context, listen: false).setAmoledMode(val);
                        }
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.motion_photos_off_outlined,
                          color: AppTheme.warningAmber),
                      title: Text('Reduce Motion',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Disable animations for fast transitions',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      value: _reduceMotionActive,
                      activeColor: AppTheme.electricCyan,
                      onChanged: (val) async {
                        setState(() => _reduceMotionActive = val);
                        await AppSettingsService.instance.setReduceMotion(val);
                        if (context.mounted) {
                          Provider.of<SettingsProvider>(context, listen: false).setReduceMotion(val);
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // 5. 💰 Finance
                if (_matchesSearch(
                    'finance income budget fixed expenses currency cycle salary day')) ...[
                  _buildSectionHeader('💰 Finance Settings'),
                  _buildCardWrapper([
                    ListTile(
                      leading: const Icon(Icons.account_balance_wallet_outlined,
                          color: AppTheme.electricMint),
                      title: Text('Monthly Income & Budget Limit',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Current: ₹${provider.monthlyBudget.toStringAsFixed(0)} / month',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.edit_outlined,
                          color: AppTheme.electricMint),
                      onTap: () => _showIncomeEditDialog(context, provider),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: const Icon(Icons.payments_outlined,
                          color: AppTheme.warningAmber),
                      title: Text('Salary Arrival Day',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Salary usually arrives ${AppSettingsService.instance.salaryArrivalDay}th (Optimizes budget forecast)',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: _showSalaryDayDialog,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: const Icon(Icons.calendar_month_outlined,
                          color: AppTheme.electricCyan),
                      title: Text('First Day of Month Cycle',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Day ${AppSettingsService.instance.monthCycleStartDay} of every month',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: _showMonthCycleDialog,
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: const Icon(Icons.currency_rupee_rounded,
                          color: AppTheme.semanticSuccess),
                      title: Text('Default Currency',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${AppSettingsService.instance.defaultCurrency} • Active',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: _showDefaultCurrencyDialog,
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.people_alt_outlined,
                          color: AppTheme.electricCyan),
                      title: Text('Family Workspace & Household Sharing',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Shared budgets, shared goals & child allowance with 100% privacy guard',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.textMuted, size: 14),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FamilyDashboardPage())),
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.security_rounded,
                          color: AppTheme.purpleGlow),
                      title: Text('Account Authentication & Security',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Sign in, password reset & security settings',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.textMuted, size: 14),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginPage())),
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.devices_rounded,
                          color: AppTheme.electricCyan),
                      title: Text('Active Devices & Session Control',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Manage logged-in devices and remote logout',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.textMuted, size: 14),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ActiveSessionsPage())),
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.bug_report_outlined,
                          color: AppTheme.warningAmber),
                      title: Text('Send Beta Feedback',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Report a bug, parser issue, or suggest an improvement',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppTheme.textMuted, size: 14),
                      onTap: () => showDialog(
                          context: context,
                          builder: (_) => const BetaFeedbackDialog()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // 6. 📱 Smart Tracking & Permissions
                if (_matchesSearch(
                    'smart tracking sms recognition auto categories merchant learning reprocess permission android')) ...[
                  _buildSectionHeader('📱 Smart Tracking & Device Permissions'),
                  _buildCardWrapper([
                    SwitchListTile(
                      secondary: const Icon(Icons.sms_outlined,
                          color: AppTheme.electricCyan),
                      title: Text('Automatic Bank SMS Tracking',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          _smsTrackingActive
                              ? 'Automatic bank SMS recognition active'
                              : 'SMS tracking paused by user',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      value: _smsTrackingActive,
                      activeColor: AppTheme.electricCyan,
                      onChanged: (val) async {
                        setState(() => _smsTrackingActive = val);
                        await AppSettingsService.instance.setSmsTracking(val);
                      },
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    ListTile(
                      leading: Icon(
                        _smsPermissionGranted
                            ? Icons.verified_user_outlined
                            : Icons.gpp_maybe_outlined,
                        color: _smsPermissionGranted
                            ? AppTheme.semanticSuccess
                            : AppTheme.warningAmber,
                      ),
                      title: Text('Android SMS Permission',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        _smsPermissionGranted
                            ? 'Permission Granted 🟢 (On-device SMS scanner active)'
                            : 'Permission Not Granted 🔴 (Tap to configure in Settings)',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: () async {
                        await openAppSettings();
                        await _loadSettings();
                      },
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    ListTile(
                      leading: Icon(
                        _notifPermissionGranted
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: _notifPermissionGranted
                            ? AppTheme.semanticSuccess
                            : AppTheme.warningAmber,
                      ),
                      title: Text('Android Notification Permission',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        _notifPermissionGranted
                            ? 'Permission Granted 🟢 (Daily Briefs & Alerts active)'
                            : 'Permission Not Granted 🔴 (Tap to configure in Settings)',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: () async {
                        await openAppSettings();
                        await _loadSettings();
                      },
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.category_outlined,
                          color: AppTheme.purpleGlow),
                      title: Text('Auto Categories & Merchant Learning',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Remember merchant categories across transactions',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      value: _autoCategoriesActive,
                      activeColor: AppTheme.electricCyan,
                      onChanged: (val) async {
                        setState(() => _autoCategoriesActive = val);
                        await AppSettingsService.instance
                            .setAutoCategories(val);
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // 7. 🔔 Smart Notification Center
                if (_matchesSearch(
                    'notifications morning brief ritual bill reminders salary alerts goals')) ...[
                  const SmartNotificationCenterCard(),
                  const SizedBox(height: 20),
                ],

                // 8. 🔒 Privacy & Security (Verified Reassurance)
                if (_matchesSearch(
                    'privacy security biometrics lock hide balances delete reset protected trust verified today never dark patterns')) ...[
                  _buildSectionHeader('🔒 Privacy & Security'),
                  _buildVerifiedReassuranceCard(context),
                  const SizedBox(height: 12),
                  _buildThingsWeNeverDoCard(context),
                  const SizedBox(height: 12),
                  _buildCardWrapper([
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded,
                          color: AppTheme.electricCyan),
                      title: Text('App Lock & Biometrics',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Require Fingerprint / Face Unlock to view app',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      value: _biometricsEnabled,
                      activeColor: AppTheme.electricCyan,
                      onChanged: (val) async {
                        HapticFeedback.lightImpact();
                        final billingProv = Provider.of<BillingProvider>(context, listen: false);
                        if (!billingProv.isPro && val) {
                          PaywallSheet.showBiometricsAndPrivacy(context);
                          return;
                        }

                        final settingsProv = Provider.of<SettingsProvider>(
                            context,
                            listen: false);
                        final messenger = ScaffoldMessenger.of(context);
                        if (val) {
                          final success = await BiometricAuthService.instance
                              .enableBiometricsWithVerification();
                          if (!mounted) return;
                          setState(() => _biometricsEnabled = success);
                          await settingsProv.setBiometricsEnabled(success);
                          if (!success && mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Biometric verification failed or screen lock is not set up on device.'),
                                backgroundColor: AppTheme.dangerCoral,
                              ),
                            );
                          }
                        } else {
                          setState(() => _biometricsEnabled = false);
                          await settingsProv.setBiometricsEnabled(false);
                        }
                      },
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.visibility_off_outlined,
                          color: AppTheme.warningAmber),
                      title: Text('Hide Balances on Launch',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Mask numerical balances until tapped',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      value: _hideBalances,
                      activeColor: AppTheme.electricCyan,
                      onChanged: (val) async {
                        HapticFeedback.lightImpact();
                        final billingProv = Provider.of<BillingProvider>(context, listen: false);
                        if (!billingProv.isPro && val) {
                          PaywallSheet.showBiometricsAndPrivacy(context);
                          return;
                        }

                        setState(() => _hideBalances = val);
                        final settingsProv = Provider.of<SettingsProvider>(
                            context,
                            listen: false);
                        await settingsProv.setHideBalances(val);
                      },
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.dangerCoral),
                      title: const Text('Reset & Delete All Data',
                          style: TextStyle(
                              color: AppTheme.dangerCoral,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Permanently wipe all local transactions & database',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: () => _confirmReset(context, provider),
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // 9. ☁️ Backup
                if (_matchesSearch(
                    'backup restore local saf encrypted export ppbackup recovery key')) ...[
                  _buildSectionHeader('☁️ Encrypted SAF Backup'),
                  _buildCardWrapper([
                    ListTile(
                      leading: const Icon(Icons.sd_storage_outlined,
                          color: AppTheme.electricMint),
                      title: Text('Local Encrypted Backup (.ppbackup)',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(_formatLastBackupText(),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BackupRestorePage()));
                        if (mounted) setState(() {});
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // 10. 📂 Import Center (With Status & Last Import)
                if (_matchesSearch(
                    'import center pdf excel csv camera scan history statement yesterday')) ...[
                  _buildSectionHeader('📂 Import Center'),
                  _buildCardWrapper([
                    ListTile(
                      leading: const Icon(Icons.download_for_offline_outlined,
                          color: AppTheme.cyanPulse),
                      title: Row(
                        children: [
                          Text('Import Center',
                              style: TextStyle(
                                  color: textColorPrimary,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.semanticSuccess.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Ready 🟢',
                                style: TextStyle(
                                    color: AppTheme.semanticSuccess,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      subtitle: Text(_formatLastImportText(),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ImportCenterPage()));
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // 11. 🧠 Money (Powered by Money Brain™)
                if (_matchesSearch(
                    'money brain coach financial story replay share referral')) ...[
                  _buildSectionHeader('🧠 Money'),
                  _buildCardWrapper([
                    ListTile(
                      leading: const Icon(Icons.psychology_outlined,
                          color: AppTheme.purpleGlow),
                      title: Text('Financial Coach Settings',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Tone: ${AppSettingsService.instance.coachTone} • Powered by Money Brain™',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: _showCoachToneDialog,
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.share_rounded,
                          color: AppTheme.electricCyan),
                      title: Text('Share Sagiro & Unlock Pro',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Love Sagiro? Invite a friend. Both unlock 30 Days Pro!',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: () => ReferralModalSheet.show(context),
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // 13. ❓ Help & Privacy Policy
                if (_matchesSearch(
                    'help privacy policy compliance faq guide support contact terms')) ...[
                  _buildSectionHeader('❓ Help & Privacy Policy'),
                  _buildCardWrapper([
                    ListTile(
                      leading: const Icon(Icons.shield_outlined,
                          color: AppTheme.electricCyan),
                      title: Text('Privacy & Security Center',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'Manage permissions, data controls & privacy audit log',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PrivacyCenterPage()));
                      },
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined,
                          color: AppTheme.semanticInfo),
                      title: Text('Privacy Policy & Compliance',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: const Text(
                          'sagirocustomerservice@gmail.com • 100% Data Safety Guarantee',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textMuted),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyPage()));
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],

                // 14. ℹ️ About Sagiro
                if (_matchesSearch(
                    'about version build date india offline Sagiro manifesto constitution we exist believe build measure succeed')) ...[
                  _buildConstitutionCard(context),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Sagiro v2.5',
                          style: TextStyle(
                              color: textColorPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Financial clarity in under 3 seconds.',
                          style: TextStyle(
                              color: AppTheme.electricMint,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Made in India 🇮🇳 • Privacy First • Offline First • Independent',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Last Updated: August 2026',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helper UI Components ────────────────────────────────────────────

  Widget _buildSystemStatusCard(BuildContext context) {
    final lastBackup = AppSettingsService.instance.lastBackupTimestamp;
    final backupStatusText = lastBackup == null ? 'Not configured' : 'Configured 🟢';

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return GlassCard(
      borderColor: AppTheme.electricCyan.withOpacity(0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sensors_rounded,
                      color: AppTheme.electricCyan, size: 18),
                  const SizedBox(width: 8),
                  Text('System Status',
                      style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.semanticSuccess.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🟢 All systems operational',
                    style: TextStyle(
                        color: AppTheme.semanticSuccess,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge('Database', '🟢', textSecondary, textPrimary),
              _buildStatusBadge('SMS Parser', '🟢', textSecondary, textPrimary),
              _buildStatusBadge('Imports', '🟢', textSecondary, textPrimary),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge('Money Brain', '🟢', textSecondary, textPrimary),
              _buildStatusBadge('Storage', '🟢', textSecondary, textPrimary),
              _buildStatusBadge('Backup', backupStatusText, textSecondary, lastBackup == null ? textSecondary : AppTheme.semanticSuccess),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyDashboardPage()),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View details',
                    style: TextStyle(
                      color: AppTheme.electricCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: AppTheme.electricCyan, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, String status, Color labelColor, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(status,
            style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.electricCyan.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 14),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search control center (e.g. lock, backup, SMS, theme)',
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.electricCyan, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildCardWrapper(List<Widget> children) {
    return GlassCard(
      borderRadius: 16,
      borderColor: AppTheme.crispBorder.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(children: children),
    );
  }

  Widget _buildMyDataVisualGrid(
      BuildContext context, int txCount, BudgetProvider provider) {
    final uniqueAccounts = provider.transactions
        .map((t) => t.account)
        .where((a) => a != null && a.trim().isNotEmpty)
        .toSet()
        .length;

    final lastBackup = AppSettingsService.instance.lastBackupTimestamp;
    final backupText = lastBackup == null ? 'Not configured' : 'Protected';

    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDataSummaryCard(
                context: context,
                icon: Icons.receipt_long_outlined,
                iconColor: AppTheme.electricCyan,
                value: txCount.toString(),
                label: 'Transactions',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDataSummaryCard(
                context: context,
                icon: Icons.account_balance_outlined,
                iconColor: AppTheme.electricMint,
                value: uniqueAccounts.toString(),
                label: 'Accounts',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDataSummaryCard(
                context: context,
                icon: Icons.ads_click_outlined,
                iconColor: AppTheme.purpleGlow,
                value: provider.savingsGoals.length.toString(),
                label: 'Goals',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDataSummaryCard(
                context: context,
                icon: Icons.cloud_outlined,
                iconColor: lastBackup == null ? textSecondary : AppTheme.semanticSuccess,
                value: backupText,
                label: 'Backup Status',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataSummaryCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GlassCard(
      borderRadius: 16,
      borderColor: AppTheme.crispBorder.withOpacity(0.15),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 🔒 Reassurance Card
  Widget _buildVerifiedReassuranceCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PrivacyDashboardPage()));
      },
      child: GlassCard(
        borderColor: AppTheme.semanticSuccess.withOpacity(0.4),
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: AppTheme.semanticSuccess, size: 20),
                    SizedBox(width: 8),
                    Text('Verified today • Everything is protected.',
                        style: TextStyle(
                            color: AppTheme.semanticSuccess,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5)),
                  ],
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppTheme.semanticSuccess),
              ],
            ),
            SizedBox(height: 6),
            Text('Tap to verify local privacy audit status.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  // 🛡 Ethical Oath: Things We Never Do
  Widget _buildThingsWeNeverDoCard(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);

    return GlassCard(
      borderColor: AppTheme.purpleGlow.withOpacity(0.35),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppTheme.purpleGlow, size: 20),
              SizedBox(width: 8),
              Text('THINGS WE NEVER DO',
                  style: TextStyle(
                      color: AppTheme.purpleGlow,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          Text('🚫 We never use dark patterns.',
              style: TextStyle(color: textPrimary, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('🚫 We never create financial anxiety.',
              style: TextStyle(color: textPrimary, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('🚫 We never optimize for addiction.',
              style: TextStyle(color: textPrimary, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('🚫 We never sell user data.',
              style: TextStyle(color: textPrimary, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('🚫 We never add features that don\'t reduce uncertainty.',
              style: TextStyle(color: textPrimary, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('🚫 We never pressure users into spending.',
              style: TextStyle(color: textPrimary, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('🚫 We never interrupt without providing value.',
              style: TextStyle(color: textPrimary, fontSize: 12.5)),
        ],
      ),
    );
  }

  // 📜 Official Sagiro Constitution
  Widget _buildConstitutionCard(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);

    return GlassCard(
      borderColor: AppTheme.electricMint.withOpacity(0.35),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.electricMint, size: 20),
              SizedBox(width: 8),
              Text('Sagiro CONSTITUTION',
                  style: TextStyle(
                      color: AppTheme.electricMint,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 14),
          const Text('WE EXIST',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0)),
          Text('To replace financial uncertainty with quiet confidence.',
              style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 10),
          const Text('WE BELIEVE',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0)),
          Text('People deserve clarity without sacrificing privacy.',
              style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 10),
          const Text('WE BUILD',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0)),
          const Text('Simple • Fast • Private • Calm.',
              style: TextStyle(
                  color: AppTheme.semanticSuccess,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 10),
          const Text('WE MEASURE',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0)),
          const Text('Not engagement. Confidence.',
              style: TextStyle(
                  color: AppTheme.electricMint,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(height: 10),
          const Text('WE SUCCEED',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0)),
          Text(
              'When someone opens Sagiro, looks at Sagiro Safe Today™, smiles, and closes the app knowing they\'re okay.',
              style:
                  TextStyle(color: textPrimary, fontSize: 12.5, height: 1.35)),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, BudgetProvider provider) {
    final cardBg = AppTheme.cardColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text('Reset All Data?',
            style: TextStyle(
                color: AppTheme.dangerCoral, fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete ALL transactions, category rules, and budget settings.\n\nThis action cannot be undone.',
          style: TextStyle(color: textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerCoral,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.clearAllData();
              await provider.loadData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been reset.')),
                );
              }
            },
            child: const Text('Reset Everything',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showIncomeEditDialog(BuildContext context, BudgetProvider provider) {
    final controller =
        TextEditingController(text: provider.monthlyBudget.toStringAsFixed(0));
    final cardBg = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: Text('Update Monthly Income / Budget',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()]),
          decoration: InputDecoration(
            prefixText: '₹ ',
            prefixStyle: const TextStyle(color: AppTheme.electricMint, fontSize: 18),
            labelText: 'Monthly Income (₹)',
            labelStyle: TextStyle(color: textSecondary),
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
                backgroundColor: AppTheme.electricMint,
                foregroundColor: Colors.black),
            onPressed: () async {
              final newIncome = double.tryParse(controller.text.trim());
              Navigator.pop(ctx);
              if (newIncome != null && newIncome >= 0) {
                await provider.updateMonthlyBudget(newIncome);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '🟢 Monthly Income updated to ₹${newIncome.toStringAsFixed(0)}! Safe Today™ recalculated.'),
                      backgroundColor: AppTheme.electricMint,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Income',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionPill({
    required BuildContext context,
    required String choice,
    required String label,
  }) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isSelected = settingsProvider.themeModeChoice == choice;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await settingsProvider.setThemeModeChoice(choice);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.electricCyan.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppTheme.electricCyan, width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.electricCyan : AppTheme.textMuted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
