import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'package:provider/provider.dart';
import '../providers/authentication_provider.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../components/animated_scale_button.dart';
import '../rag/rag_service.dart';
import '../billing/feature_access.dart';
import '../components/ai_pro_paywall_sheet.dart';
import '../services/money_guide_quota_service.dart';
import '../services/ask_your_money_engine.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int _remainingTokens = MoneyGuideQuotaService.maxFreeTokens;
  bool _isPro = false;

  final List<String> _quickPrompts = const [
    'What is Safe Today?',
    'Where did I spend the most?',
    'How much have I spent this month?',
    'Am I spending too much on food?',
    'How much can I safely spend today?',
  ];

  @override
  void initState() {
    super.initState();
    _loadQuotaState();
  }

  Future<void> _loadQuotaState() async {
    final isPro = FeatureAccess.hasPremium();
    final remaining = await MoneyGuideQuotaService.getRemainingTokens(isPro);
    if (mounted) {
      setState(() {
        _isPro = isPro;
        _remainingTokens = remaining;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final userName =
        authProvider.userProfile?.displayName.split(' ').first ?? 'Friend';
    final bgColor = AppTheme.backgroundColor(context);
    final surfaceColor = AppTheme.surfaceColor(context);
    final cardColor = AppTheme.cardColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);

    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        final safeToday = budgetProvider.dailySafeSpendingLimit;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded,
                        color: AppTheme.semanticInfo, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sagiro Guide',
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Ask anything about your money',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
              ],
            ),
            actions: [
              // Token Quota Badge
              GestureDetector(
                onTap: () => AiProPaywallSheet.show(context),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isPro
                        ? AppTheme.semanticSuccess.withOpacity(0.15)
                        : (_remainingTokens > 0
                            ? AppTheme.semanticInfo.withOpacity(0.15)
                            : Colors.orangeAccent.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isPro
                          ? AppTheme.semanticSuccess
                          : (_remainingTokens > 0
                              ? AppTheme.semanticInfo
                              : Colors.orangeAccent),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPro
                            ? Icons.all_inclusive_rounded
                            : Icons.bolt_rounded,
                        color: _isPro
                            ? AppTheme.semanticSuccess
                            : (_remainingTokens > 0
                                ? AppTheme.semanticInfo
                                : Colors.orangeAccent),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPro
                            ? 'PRO'
                            : '$_remainingTokens/${MoneyGuideQuotaService.maxFreeTokens}',
                        style: TextStyle(
                          color: _isPro
                              ? AppTheme.semanticSuccess
                              : (_remainingTokens > 0
                                  ? textPrimary
                                  : Colors.orangeAccent),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.settings_rounded,
                    color: textSecondary, size: 21),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Conversational Greeting Header
                      Text(
                        'Good day, $userName 👋',
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budgetProvider.hasBudget
                            ? 'Today looks healthy. You still have ₹${safeToday.toStringAsFixed(0)} available.'
                            : 'Set a monthly budget to calculate your daily Safe Today™ limit.',
                        style: TextStyle(
                            color: textSecondary, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // Today's Advice Highlight Card
                      GlassCard(
                        padding: const EdgeInsets.all(18),
                        borderColor: AppTheme.semanticInfo.withOpacity(0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    color: AppTheme.semanticInfo, size: 18),
                                SizedBox(width: 8),
                                Text('TODAY\'S ADVICE',
                                    style: TextStyle(
                                        color: AppTheme.semanticInfo,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              SpendingAnalyzer.generateTodayAdvice(
                                  budgetProvider.transactions),
                              style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                _handleSubmitted(
                                    'Which food merchants contributed most?',
                                    budgetProvider);
                              },
                              child: const Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Would you like to see which restaurants contributed most?',
                                      style: TextStyle(
                                          color: AppTheme.semanticInfo,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward,
                                      color: AppTheme.semanticInfo, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Command Prompts
                      Text('ASK ME ANYTHING',
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickPrompts
                            .map((prompt) => AnimatedScaleButton(
                                  onTap: () {
                                    _handleSubmitted(prompt, budgetProvider);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppTheme.cardBorder),
                                    ),
                                    child: Text(prompt,
                                        style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Quota exhausted warning banner if free & 0 tokens left
                      if (!_isPro && _remainingTokens <= 0) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: Colors.orangeAccent.withOpacity(0.5),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  color: Colors.orangeAccent, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Free Token Quota Reached',
                                      style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'You\'ve used your ${MoneyGuideQuotaService.maxFreeTokens} free tokens. Upgrade to Pro for unlimited AI guidance.',
                                      style: TextStyle(
                                          color: textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.semanticInfo,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () =>
                                    AiProPaywallSheet.show(context),
                                child: const Text('Upgrade',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Guidance Feed
                      if (_messages.isNotEmpty) ...[
                        Text('CONVERSATION HISTORY',
                            style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0)),
                        const SizedBox(height: 12),
                        ..._messages.map((msg) => _buildMessageBubble(msg)),
                      ],

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.semanticInfo,
                                  strokeWidth: 2)),
                        ),
                    ],
                  ),
                ),
              ),

              // Command Input Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: const Border(
                      top: BorderSide(color: AppTheme.cardBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: !_isPro && _remainingTokens <= 0
                              ? 'Quota reached (0/50 tokens left)...'
                              : 'Ask me anything...',
                          hintStyle:
                              TextStyle(color: textSecondary, fontSize: 14),
                          filled: true,
                          fillColor: surfaceColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none),
                        ),
                        onSubmitted: (text) =>
                            _handleSubmitted(text, budgetProvider),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedScaleButton(
                      onTap: () => _handleSubmitted(
                          _queryController.text, budgetProvider),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: !_isPro && _remainingTokens <= 0
                              ? Colors.grey.shade700
                              : AppTheme.semanticInfo,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.black, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSubmitted(String text, BudgetProvider provider) async {
    if (text.trim().isEmpty) return;

    // Check token quota
    final canQuery = await MoneyGuideQuotaService.canConsumeToken(_isPro);
    if (!canQuery) {
      if (mounted) {
        AppTheme.triggerHaptic(HapticFeedbackType.medium);
        AiProPaywallSheet.show(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You\'ve used all ${MoneyGuideQuotaService.maxFreeTokens} free Money Guide tokens. Upgrade to Pro for unlimited queries!'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    AppTheme.triggerHaptic(HapticFeedbackType.light);
    _queryController.clear();

    // Consume 1 token
    final remainingAfterConsume =
        await MoneyGuideQuotaService.consumeToken(_isPro);

    setState(() {
      _remainingTokens = remainingAfterConsume;
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final ragService = RagService();
      final result = await ragService.executePipeline(
        query: text,
        transactions: provider.transactions,
        subscriptions: provider.activeSubscriptions,
        monthlyBudget: provider.monthlyBudget,
      );

      final answerText = result.response.toFormattedString();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(
            text: answerText.isEmpty
                ? 'I reviewed your financial data. No specific details were found for your query. Try asking about your top spending categories or Safe Today limit!'
                : answerText,
            isUser: false,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(
            text:
                'I ran into an issue retrieving that analysis. Please verify your transaction entries and try asking again.',
            isUser: false,
            isError: true,
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final textPrimary = AppTheme.textPrimaryColor(context);
    final isUser = msg.isUser;
    if (isUser) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.semanticInfo.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.semanticInfo.withOpacity(0.3)),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final isError = msg.isError;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      alignment: Alignment.centerLeft,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: isError
            ? AppTheme.semanticDanger.withOpacity(0.5)
            : AppTheme.semanticInfo.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.psychology_rounded,
                  color:
                      isError ? AppTheme.semanticDanger : AppTheme.semanticInfo,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isError ? 'Sagiro Assistant Notice' : 'Sagiro Money Guide',
                  style: TextStyle(
                    color: isError
                        ? AppTheme.semanticDanger
                        : AppTheme.semanticInfo,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _renderFormattedText(msg.text, textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _renderFormattedText(String text, Color primaryColor) {
    final lines = text.split('\n');
    final List<Widget> children = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      if (trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
        final bulletText = trimmed.substring(2);
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ',
                    style: TextStyle(
                        color: AppTheme.semanticInfo,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Expanded(
                  child: Text(
                    bulletText.replaceAll('**', ''),
                    style: TextStyle(
                        color: primaryColor, fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (trimmed.startsWith('### ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              trimmed.substring(4).replaceAll('**', ''),
              style: const TextStyle(
                color: AppTheme.semanticInfo,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line.replaceAll('**', ''),
              style: TextStyle(color: primaryColor, fontSize: 14, height: 1.4),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}
