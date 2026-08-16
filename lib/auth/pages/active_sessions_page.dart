import 'package:flutter/material.dart';
import '../../components/glass_card.dart';
import '../../theme/app_theme.dart';
import '../services/auth_service.dart';

class ActiveSessionsPage extends StatefulWidget {
  const ActiveSessionsPage({super.key});

  @override
  State<ActiveSessionsPage> createState() => _ActiveSessionsPageState();
}

class _ActiveSessionsPageState extends State<ActiveSessionsPage> {
  @override
  Widget build(BuildContext context) {
    final sessions = AuthService.instance.getActiveSessions();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Active Devices & Sessions',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Logged In Devices',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 12),
            ...sessions.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderColor: s.isCurrentDevice
                      ? AppTheme.electricCyan.withOpacity(0.4)
                      : Colors.white10,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        s.platform.contains('macOS') ||
                                s.platform.contains('Windows')
                            ? Icons.laptop_mac_rounded
                            : Icons.phone_android_rounded,
                        color: s.isCurrentDevice
                            ? AppTheme.electricCyan
                            : AppTheme.textMuted,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text(s.deviceName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14))),
                                if (s.isCurrentDevice)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: AppTheme.electricCyan
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Text('This Device',
                                        style: TextStyle(
                                            color: AppTheme.electricCyan,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Platform: ${s.platform} • IP: ${s.ipAddress}',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (!s.isCurrentDevice)
                        IconButton(
                          icon: const Icon(Icons.logout_rounded,
                              color: AppTheme.warningAmber, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text('Session ${s.sessionId} revoked.')));
                          },
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
