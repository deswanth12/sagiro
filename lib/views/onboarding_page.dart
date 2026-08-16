import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../components/sagiro_logo.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';
import '../components/sms_scan_result_sheet.dart';
import '../components/add_transaction_dialog.dart';
import '../components/voice_expense_sheet.dart';
import '../providers/budget_provider.dart';
import 'welcome_auth_page.dart';
import 'import_center_page.dart';
import 'main_navigation_screen.dart';
import '../services/app_settings_service.dart';

/// OnboardingPage — Sagiro 4-Step Entry Experience.
/// 1. Welcome  •  2. Privacy  •  3. Choose Starting Method  •  4. Basic Setup
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 4 Controllers
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();

  final currencyFormat = NumberFormat('#,##,##0', 'en_IN');

  @override
  void dispose() {
    _budgetController.dispose();
    _incomeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    AppTheme.triggerHaptic(HapticFeedbackType.medium);
    final provider = Provider.of<BudgetProvider>(context, listen: false);

    final rawBudgetText = _budgetController.text.replaceAll(',', '').trim();
    final budget = double.tryParse(rawBudgetText) ?? 0.0;

    final rawIncomeText = _incomeController.text.replaceAll(',', '').trim();
    final income = double.tryParse(rawIncomeText) ?? 0.0;

    if (budget > 0) {
      await provider.updateMonthlyBudget(budget);
    } else if (income > 0) {
      await provider.updateMonthlyBudget(income);
    }

    await AppSettingsService.instance.setOnboardingCompleted(true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.backgroundColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                onPressed: _previousStep,
              )
            : null,
        title: _currentStep > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SagiroLogo(size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'SAGIRO',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              )
            : null,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppTheme.semanticInfo
                            : AppTheme.surfaceColor(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (step) => setState(() => _currentStep = step),
                children: [
                  _buildScreen1Welcome(context),
                  _buildScreen2Privacy(context),
                  _buildScreen3ChooseStart(context),
                  _buildScreen4BasicSetup(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 1 — WELCOME
  // ---------------------------------------------------------------------------
  Widget _buildScreen1Welcome(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.semanticInfo.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: AppTheme.semanticInfo,
              size: 56,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'SAGIRO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your private money decision assistant.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.semanticInfo,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            padding: const EdgeInsets.all(20),
            borderColor: AppTheme.cardBorder,
            child: Column(
              children: [
                _buildBulletRow(context, Icons.analytics_outlined,
                    'Track spending automatically & manually.'),
                const SizedBox(height: 12),
                _buildBulletRow(context, Icons.today_rounded,
                    'Know what is safe to spend today.'),
                const SizedBox(height: 12),
                _buildBulletRow(context, Icons.psychology_rounded,
                    'Ask Money Brain what to do next.'),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.semanticInfo,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _nextStep,
            child: const Text(
              'Get Started',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeAuthPage()),
              );
            },
            child: Text(
              'I already have an account',
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 2 — PRIVACY
  // ---------------------------------------------------------------------------
  Widget _buildScreen2Privacy(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.semanticSuccess.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppTheme.semanticSuccess,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your money stays yours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '🔒 Local-first financial processing',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.semanticSuccess,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                borderColor: AppTheme.semanticSuccess.withOpacity(0.3),
                child: Column(
                  children: [
                    _buildPrivacyItem(
                      context,
                      icon: Icons.phonelink_ring_rounded,
                      title: 'On-Device SMS Scanning',
                      subtitle: 'Bank SMS is processed entirely on your phone.',
                    ),
                    const Divider(height: 24, color: AppTheme.cardBorder),
                    _buildPrivacyItem(
                      context,
                      icon: Icons.do_not_disturb_on_rounded,
                      title: 'Raw SMS Is Never Stored',
                      subtitle:
                          'Message text is parsed for amounts and immediately discarded.',
                    ),
                    const Divider(height: 24, color: AppTheme.cardBorder),
                    _buildPrivacyItem(
                      context,
                      icon: Icons.storage_rounded,
                      title: 'Offline Local Database',
                      subtitle:
                          'Your transaction records stay on your local device storage.',
                    ),
                    const Divider(height: 24, color: AppTheme.cardBorder),
                    _buildPrivacyItem(
                      context,
                      icon: Icons.people_outline_rounded,
                      title: 'Granular Family Privacy',
                      subtitle:
                          'Private transactions are never exposed to shared family profiles.',
                    ),
                    const Divider(height: 24, color: AppTheme.cardBorder),
                    _buildPrivacyItem(
                      context,
                      icon: Icons.lock_outline_rounded,
                      title: 'AES-256 Encrypted Backups',
                      subtitle:
                          'Vault exports are protected with a passphrase you control.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.semanticSuccess,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _nextStep,
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 3 — CHOOSE HOW TO START
  // ---------------------------------------------------------------------------
  Widget _buildScreen3ChooseStart(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Text(
            'How do you want to start?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose your preferred transaction entry method',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 1. SCAN BANK SMS — LARGE & PROMINENT
                  AnimatedScaleButton(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SmsScanResultSheet(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: AppTheme.electricCyan, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: AppTheme.electricCyan,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Scan Bank SMS',
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.electricCyan,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'RECOMMENDED',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Import recent bank transactions automatically.',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: textPrimary, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. IMPORT STATEMENT
                  _buildStartOption(
                    context,
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'Import Statement',
                    subtitle: 'Import PDF or CSV bank statements.',
                    color: AppTheme.semanticInfo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ImportCenterPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. ADD MANUALLY
                  _buildStartOption(
                    context,
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Add Manually',
                    subtitle: 'Enter your first transaction record.',
                    color: AppTheme.semanticSuccess,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddTransactionDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // 4. USE VOICE
                  _buildStartOption(
                    context,
                    icon: Icons.mic_rounded,
                    title: 'Use Voice',
                    subtitle: 'Example: "Spent ₹450 at Swiggy."',
                    color: Colors.purpleAccent,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const VoiceExpenseSheet(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.semanticInfo,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _nextStep,
            child: const Text(
              'Skip to Setup',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 4 — BASIC SETUP
  // ---------------------------------------------------------------------------
  Widget _buildScreen4BasicSetup(BuildContext context) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Let\'s set up your money plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Set your monthly budget to calculate your daily spending limit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Field 1: Monthly Budget (Primary)
                  const Text(
                    'MONTHLY BUDGET (IMPORTANT)',
                    style: TextStyle(
                      color: AppTheme.semanticInfo,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: 'e.g. 30,000',
                      hintStyle: TextStyle(
                        color: textSecondary.withOpacity(0.5),
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceColor(context),
                      contentPadding: const EdgeInsets.all(18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppTheme.semanticInfo, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Field 2: Monthly Income (Optional)
                  Text(
                    'MONTHLY INCOME (OPTIONAL)',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: 'e.g. 50,000',
                      hintStyle: TextStyle(
                        color: textSecondary.withOpacity(0.5),
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceColor(context),
                      contentPadding: const EdgeInsets.all(18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppTheme.semanticInfo, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.semanticInfo,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _finishOnboarding,
            child: const Text(
              'Start Sagiro',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildBulletRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.semanticInfo, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.semanticSuccess, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return AnimatedScaleButton(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: color.withOpacity(0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}
