import 'package:flutter/material.dart';
import '../services/referral_service.dart';
import '../theme/app_theme.dart';

class ReferralModalSheet extends StatefulWidget {
  const ReferralModalSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReferralModalSheet(),
    );
  }

  @override
  State<ReferralModalSheet> createState() => _ReferralModalSheetState();
}

class _ReferralModalSheetState extends State<ReferralModalSheet> {
  final TextEditingController _codeController = TextEditingController();
  String _userCode = 'PAISA-...';
  int _proDaysEarned = 0;
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final code = await ReferralService.getUserReferralCode();
    final days = await ReferralService.getProDaysEarned();
    if (mounted) {
      setState(() {
        _userCode = code;
        _proDaysEarned = days;
      });
    }
  }

  Future<void> _redeemCode() async {
    final inputCode = _codeController.text.trim();
    if (inputCode.isEmpty) return;

    setState(() => _isRedeeming = true);
    final success = await ReferralService.redeemReferralCode(inputCode);
    if (mounted) {
      setState(() => _isRedeeming = false);
      if (success) {
        _codeController.clear();
        await _loadReferralData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '🎉 Referral code redeemed! You unlocked 30 Days of Sagiro Pro!'),
            backgroundColor: AppTheme.semanticSuccess,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Invalid or self-referral code. Please check and try again.'),
            backgroundColor: AppTheme.dangerCoral,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border:
            Border(top: BorderSide(color: AppTheme.electricCyan, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.electricCyan.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: AppTheme.electricCyan, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite Friends & Unlock Pro',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Both get 30 Days Pro for free',
                          style: TextStyle(
                              color: AppTheme.electricCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Explanation Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Love Sagiro? Invite a friend to build financial discipline together. When they join, both of you unlock 30 Days of Sagiro Pro for free!',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                  if (_proDaysEarned > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.semanticSuccess.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                          '🎉 You unlocked $_proDaysEarned Days of Pro!',
                          style: const TextStyle(
                              color: AppTheme.semanticSuccess,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Your Personal Referral Code
            const Text('YOUR REFERRAL CODE',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.electricCyan.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_userCode,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1.5)),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Referral code $_userCode copied to clipboard! Share with friends.'),
                          backgroundColor: AppTheme.semanticSuccess,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy,
                        color: AppTheme.electricCyan, size: 16),
                    label: const Text('Copy',
                        style: TextStyle(
                            color: AppTheme.electricCyan,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Redeem Friend's Code Section
            const Text('REDEEM FRIEND\'S CODE',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter PAISA-XXXXXX',
                      hintStyle: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.darkSurface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isRedeeming ? null : _redeemCode,
                    child: _isRedeeming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Text('Redeem',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
