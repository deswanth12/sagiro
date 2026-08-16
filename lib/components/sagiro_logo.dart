import 'package:flutter/material.dart';

/// Sagiro Official Brand Emblem & Wordmark Component
///
/// Brand Specifications:
/// - BRAND: SAGIRO
/// - TAGLINE: "Your money, simplified."
/// - Colors: Primary Deep Emerald (#0B3D2E), Secondary Emerald (#087F5B), Accent Lime (#A8E063)
class SagiroLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const SagiroLogo({
    super.key,
    this.size = 80,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Deep Emerald Icon Tile with Lime Accent Glow
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0B3D2E),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA8E063).withOpacity(0.20),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            size: Size(size, size),
            painter: _SagiroEmblemPainter(),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Official Wordmark: SAGIRO
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'SAGI',
                style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              TextSpan(
                text: 'RO',
                style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFA8E063),
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),

        // 3. Official Tagline: "Your money, simplified."
        if (showTagline) ...[
          const SizedBox(height: 6),
          const Text(
            'Your money, simplified.',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8EA59B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

/// CustomPainter for the official Sagiro geometric emblem ('S' curve + financial pillar)
class _SagiroEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final s = size.width / 2.0;

    // Upper Ribbon (Lime Accent)
    final pUpper = Path()
      ..moveTo(cx + s * 0.15, cy - s * 0.85)
      ..lineTo(cx + s * 0.75, cy - s * 0.85)
      ..lineTo(cx + s * 0.45, cy - s * 0.15)
      ..lineTo(cx - s * 0.25, cy - s * 0.15)
      ..lineTo(cx - s * 0.65, cy - s * 0.85)
      ..close();

    // Lower Ribbon (Secondary Emerald)
    final pLower = Path()
      ..moveTo(cx - s * 0.15, cy + s * 0.85)
      ..lineTo(cx - s * 0.75, cy + s * 0.85)
      ..lineTo(cx - s * 0.45, cy + s * 0.15)
      ..lineTo(cx + s * 0.25, cy + s * 0.15)
      ..lineTo(cx + s * 0.65, cy + s * 0.85)
      ..close();

    // Core Interlocking Diamond (White / Accent)
    final pCore = Path()
      ..moveTo(cx - s * 0.25, cy - s * 0.15)
      ..lineTo(cx + s * 0.45, cy - s * 0.15)
      ..lineTo(cx + s * 0.25, cy + s * 0.15)
      ..lineTo(cx - s * 0.45, cy + s * 0.15)
      ..close();

    final paintLower = Paint()
      ..color = const Color(0xFF087F5B)
      ..style = PaintingStyle.fill;
    final paintUpper = Paint()
      ..color = const Color(0xFFA8E063)
      ..style = PaintingStyle.fill;
    final paintCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(pLower, paintLower);
    canvas.drawPath(pUpper, paintUpper);
    canvas.drawPath(pCore, paintCore);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Backward-compatible typedefs
typedef PaisaPilotLogo = SagiroLogo;
typedef HisariLogo = SagiroLogo;
