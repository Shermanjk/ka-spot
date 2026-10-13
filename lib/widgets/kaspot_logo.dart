import 'package:flutter/material.dart';

/// Official KaSpot brand colors matching the visual wordmark.
class KaSpotColors {
  KaSpotColors._();
  static const Color primaryDarkBlue = Color(0xFF0A6BAF); // "Ka" (light background — harmonized deep ocean blue)
  static const Color accentSkyBlue = Color(0xFF0D8AD1);   // "Spot" (both backgrounds)
  static const Color kaOnDark = Color(0xFFDCEBF4);        // "Ka" (dark background)
  static const Color taglineBlue = Color(0xFF1E4B8A);     // Tagline text
}

/// Official KaSpot Logo Widget (Wordmark + Tagline)
/// Replicates the text-based logo with the custom location-pin 'o' badge.
class KaSpotLogo extends StatelessWidget {
  const KaSpotLogo({
    super.key,
    this.fontSize = 32,
    this.showTagline = true,
    this.tagline = 'Stay connected. Wherever life takes you.',
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.isDark,
  });

  final double fontSize;
  final bool showTagline;
  final String tagline;
  final CrossAxisAlignment crossAxisAlignment;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        KaSpotWordmark(fontSize: fontSize, isDark: isDark),
        if (showTagline) ...[
          SizedBox(height: fontSize * 0.16),
          Text(
            tagline,
            style: TextStyle(
              fontSize: (fontSize * 0.38).clamp(11.0, 16.0),
              fontWeight: FontWeight.w600,
              color: KaSpotColors.taglineBlue,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }
}

/// Pure KaSpot Wordmark ("Ka" in deep ocean blue, "Sp[owl]t" in vibrant sky blue).
class KaSpotWordmark extends StatelessWidget {
  const KaSpotWordmark({
    super.key,
    this.fontSize = 24,
    this.isDark,
  });

  final double fontSize;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    final styleDark = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: effectiveIsDark ? KaSpotColors.kaOnDark : KaSpotColors.primaryDarkBlue,
      letterSpacing: -0.8,
      height: 1.0,
    );

    final styleSky = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: KaSpotColors.accentSkyBlue,
      letterSpacing: -0.8,
      height: 1.0,
    );

    // Owl 'o': resized to sit level with the name — ears end just above cap
    // height ('K'), chin rests near the baseline. Small positive gaps on both
    // sides give the badge breathing room instead of overlapping 'p' and 't'.
    // Strictly a resize of the same artwork — no redesign.
    final badgeHeight = fontSize * 0.95;
    final badgeWidth = badgeHeight * (589.0 / 506.0);
    final gap = fontSize * 0.045;
    final slotWidth = badgeWidth + gap * 2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Ka', style: styleDark),
        Text('Sp', style: styleSky),
        // "o" = owl badge sitting level with the name, breathing room both sides
        SizedBox(
          width: slotWidth,
          height: fontSize,
          child: OverflowBox(
            minWidth: badgeWidth,
            maxWidth: badgeWidth,
            minHeight: badgeHeight,
            maxHeight: badgeHeight,
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, fontSize * 0.02),
              child: _KaSpotOwlO(isDark: effectiveIsDark),
            ),
          ),
        ),
        // "t" in electric sky blue
        Text('t', style: styleSky),
      ],
    );
  }
}

/// Standalone KaSpot Icon Badge (renders the exact Owl Logo on transparent background)
class KaSpotIconBadge extends StatelessWidget {
  const KaSpotIconBadge({
    super.key,
    this.size = 36,
    this.borderRadius = 10,
    this.isDark,
  });

  final double size;
  final double borderRadius;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    return SizedBox(
      width: size * (589.0 / 506.0),
      height: size,
      child: _KaSpotOwlO(isDark: effectiveIsDark),
    );
  }
}

/// The owl 'o' badge rendered from the official transparent vector owl asset.
/// - Light background: crisp cyan contour outline, pure white head, dual blue eyes, black beak.
/// - Dark background: luminous white head with cyan contour outline popping against dark navy.
class _KaSpotOwlO extends StatelessWidget {
  final bool? isDark;
  const _KaSpotOwlO({this.isDark});

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    const assetPath = 'assets/logos/kaspot_new_owl_hero.png';

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return CustomPaint(
          painter: _OwlOPainter(isDark: effectiveIsDark),
        );
      },
    );
  }
}

class _OwlOPainter extends CustomPainter {
  final bool isDark;
  const _OwlOPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    // 100% Transparent background (no box, no squircle, no circle backing).
    final scale = size.height / 731.0;
    final tx = (size.width - 1024.0 * scale) * 0.5;
    final ty = (size.height - 731.0 * scale) * 0.5;

    canvas.save();
    canvas.translate(tx, ty);
    canvas.scale(scale);

    // Fallback vector (used only if the PNG asset fails to load).
    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFF8A8A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeJoin = StrokeJoin.round;

    final eyePaint = Paint()
      ..color = const Color(0xFF0FA1E5)
      ..style = PaintingStyle.fill;

    final littleEyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final beakPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // 1. Exact Owl Head Path (User's drawing contour: double pointy ear tufts, crown dip, chin)
    final head = Path()
      ..moveTo(512.0, 54.0)
      ..cubicTo(416.0, 54.0, 304.0, 46.0, 197.0, 40.0)
      ..cubicTo(207.0, 72.0, 218.0, 102.0, 229.0, 126.0)
      ..cubicTo(200.0, 134.0, 168.0, 140.0, 147.0, 148.0)
      ..cubicTo(184.0, 200.0, 206.0, 240.0, 218.0, 280.0)
      ..cubicTo(204.0, 370.0, 244.0, 500.0, 324.0, 580.0)
      ..cubicTo(374.0, 630.0, 439.0, 680.0, 512.0, 692.0)
      ..cubicTo(585.0, 680.0, 650.0, 630.0, 700.0, 580.0)
      ..cubicTo(780.0, 500.0, 820.0, 370.0, 806.0, 280.0)
      ..cubicTo(818.0, 240.0, 840.0, 200.0, 877.0, 148.0)
      ..cubicTo(856.0, 140.0, 824.0, 134.0, 795.0, 126.0)
      ..cubicTo(806.0, 102.0, 817.0, 72.0, 827.0, 40.0)
      ..cubicTo(720.0, 46.0, 608.0, 54.0, 512.0, 54.0)
      ..close();
    canvas.drawPath(head, headPaint);
    if (!isDark) canvas.drawPath(head, outlinePaint);

    // 2. Left Eye + Specular highlight / little eye
    canvas.drawCircle(const Offset(358.0, 350.0), 108.0, eyePaint);
    canvas.drawCircle(const Offset(397.5, 309.5), 38.0, littleEyePaint);

    // 3. Right Eye + Specular highlight / little eye
    canvas.drawCircle(const Offset(647.0, 350.0), 108.0, eyePaint);
    canvas.drawCircle(const Offset(690.5, 306.5), 38.0, littleEyePaint);

    // 4. Centered Black Beak Droplet
    final beak = Path()
      ..moveTo(505.0, 440.0)
      ..cubicTo(475.0, 440.0, 458.0, 458.0, 458.0, 478.0)
      ..cubicTo(458.0, 502.0, 485.0, 528.0, 502.0, 541.0)
      ..cubicTo(504.0, 542.5, 506.0, 542.5, 508.0, 541.0)
      ..cubicTo(525.0, 528.0, 553.0, 502.0, 553.0, 478.0)
      ..cubicTo(553.0, 458.0, 535.0, 440.0, 505.0, 440.0)
      ..close();
    canvas.drawPath(beak, beakPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OwlOPainter oldDelegate) => oldDelegate.isDark != isDark;
}
