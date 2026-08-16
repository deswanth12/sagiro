import 'package:flutter/material.dart';
import '../../components/glass_card.dart';
import '../../theme/app_theme.dart';
import '../models/discovered_bank.dart';
import '../services/bank_discovery_service.dart';

class BankDiscoveryCard extends StatefulWidget {
  final VoidCallback? onScanCompleted;

  const BankDiscoveryCard({
    super.key,
    this.onScanCompleted,
  });

  @override
  State<BankDiscoveryCard> createState() => _BankDiscoveryCardState();
}

class _BankDiscoveryCardState extends State<BankDiscoveryCard> {
  bool _isScanning = false;
  BankDiscoveryScanResult? _lastScanResult;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    await BankDiscoveryService.instance.loadCheckpoint();
    if (mounted) setState(() {});
  }

  Future<void> _runScan() async {
    setState(() => _isScanning = true);
    final result =
        await BankDiscoveryService.instance.scanSmsAndDiscoverBanks();
    if (mounted) {
      setState(() {
        _isScanning = false;
        _lastScanResult = result;
      });
      if (widget.onScanCompleted != null) {
        widget.onScanCompleted!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final banks = BankDiscoveryService.instance.discoveredBanks;
    final primary = BankDiscoveryService.instance.primaryBank;
    final secondary = BankDiscoveryService.instance.secondaryBank;
    final checkpoint = BankDiscoveryService.instance.checkpoint;

    return GlassCard(
      borderColor: AppTheme.electricCyan.withOpacity(0.3),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_rounded,
                      color: AppTheme.electricCyan, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Bank Discovery Engine',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan.withOpacity(0.15),
                  foregroundColor: AppTheme.electricCyan,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isScanning ? null : _runScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.electricCyan),
                      )
                    : const Icon(Icons.radar_rounded, size: 16),
                label: Text(
                  _isScanning ? 'Scanning...' : 'Scan SMS',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            checkpoint.totalScannedCount > 0
                ? 'Total SMS Scanned: ${checkpoint.totalScannedCount} • Evidence-based local discovery'
                : 'Scans SMS locally on-device to discover your active bank accounts.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          if (_lastScanResult != null) ...[
            const SizedBox(height: 6),
            Text(
              'Scanned ${_lastScanResult!.newMessagesScanned} new SMS in ${_lastScanResult!.scanDuration.inMilliseconds}ms',
              style: const TextStyle(
                  color: AppTheme.electricMint,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ],
          if (primary != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 14),
            _buildBankStatusTile(primary, isPrimaryHeader: true),
          ],
          if (secondary != null) ...[
            const SizedBox(height: 10),
            _buildBankStatusTile(secondary, isSecondaryHeader: true),
          ],
          if (banks.length > 2) ...[
            const SizedBox(height: 14),
            const Text(
              'Additional Detected Banks',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...banks.skip(2).map((b) => _buildBankStatusTile(b)),
          ],
          if (banks.isEmpty && !_isScanning) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.textMuted, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap "Scan SMS" to discover your primary and connected bank accounts.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankStatusTile(
    DiscoveredBank bank, {
    bool isPrimaryHeader = false,
    bool isSecondaryHeader = false,
  }) {
    final isHigh = bank.confidenceLevel == BankConfidenceLevel.high;
    final isMediumOrLow = bank.confidenceLevel == BankConfidenceLevel.medium ||
        bank.confidenceLevel == BankConfidenceLevel.low;

    final badgeColor = isPrimaryHeader
        ? AppTheme.electricMint
        : isSecondaryHeader
            ? AppTheme.purpleGlow
            : isHigh
                ? AppTheme.semanticSuccess
                : AppTheme.warningAmber;

    final statusText = isPrimaryHeader
        ? 'PRIMARY BANK 🏆'
        : isSecondaryHeader
            ? 'SECONDARY BANK 🏦'
            : isHigh
                ? 'HIGH CONFIDENCE 🟢'
                : 'NEEDS CONFIRMATION ❓';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _getBankEmoji(bank.bankCode),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.bankName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      Text(
                        '${bank.confirmedTransactionCount} Transactions • Score ${bank.evidenceScore.toStringAsFixed(0)} pts',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          if (bank.accountLast4Set.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Linked Account: XXXX${bank.accountLast4Set.join(", XXXX")}',
              style: const TextStyle(
                color: AppTheme.electricCyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // Confirmation Prompt for Medium/Low Confidence Banks
          if (isMediumOrLow && !bank.userConfirmed) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.warningAmber.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We found activity associated with ${bank.bankName}. Confirm this is your bank account?',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.semanticSuccess,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            BankDiscoveryService.instance
                                .userConfirmBank(bank.bankCode);
                          });
                        },
                        child: Text('Add ${bank.bankName}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            BankDiscoveryService.instance
                                .userRejectBank(bank.bankCode);
                          });
                        },
                        child: const Text('Not my bank',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getBankEmoji(String code) {
    switch (code) {
      case 'HDFCBK':
      case 'HDFCBANK':
        return '🏛️';
      case 'SBI':
      case 'SBIINB':
        return '🏦';
      case 'ICICIB':
      case 'ICICIBANK':
        return '💳';
      case 'AXISBK':
      case 'AXISBANK':
        return '💎';
      case 'KOTAKB':
      case 'KOTAK':
        return '🔴';
      default:
        return '🏦';
    }
  }
}
