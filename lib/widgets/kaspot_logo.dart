import 'package:flutter/material.dart';

/// Official KaSpot brand colors matching the visual wordmark.
class KaSpotColors {
  KaSpotColors._();
  static const Color primaryDarkBlue = Color(0xFF1E5EBF); // "Ka"
  static const Color accentSkyBlue = Color(0xFF2196F3);   // "Spot"
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
  });

  final double fontSize;
  final bool showTagline;
  final String tagline;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        KaSpotWordmark(fontSize: fontSize),
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

/// Pure KaSpot Wordmark ("Ka" in dark cobalt, "Sp[pin]t" in vibrant sky blue).
class KaSpotWordmark extends StatelessWidget {
  const KaSpotWordmark({
    super.key,
    this.fontSize = 24,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final styleDark = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: KaSpotColors.primaryDarkBlue,
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

    final pinSize = fontSize * 0.92;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // "Ka" in deep cobalt blue
        Text('Ka', style: styleDark),
        // "Sp" in electric sky blue
        Text('Sp', style: styleSky),
        // "o" as the signature location pin badge
        Padding(
          padding: EdgeInsets.symmetric(horizontal: fontSize * 0.02),
          child: SizedBox(
            width: pinSize,
            height: pinSize,
            child: const _KaSpotPinO(),
          ),
        ),
        // "t" in electric sky blue
        Text('t', style: styleSky),
      ],
    );
  }
}

/// Standalone KaSpot Icon Badge (Squircle/Circle for app bar and avatar)
class KaSpotIconBadge extends StatelessWidget {
  const KaSpotIconBadge({
    super.key,
    this.size = 36,
    this.borderRadius = 10,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: KaSpotColors.accentSkyBlue,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x302196F3),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.location_on_rounded,
        color: Colors.white,
        size: size * 0.62,
      ),
    );
  }
}

/// Custom painter for the signature 'o' badge:
/// Solid sky-blue circular badge with an inner white location pin teardrop and sky-blue center dot.
class _KaSpotPinO extends StatelessWidget {
  const _KaSpotPinO();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PinOPainter(),
    );
  }
}

class _PinOPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.width * 0.5;

    // 1. Sky blue circle base
    final circlePaint = Paint()
      ..color = KaSpotColors.accentSkyBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // 2. White location pin teardrop
    final pinWidth = size.width * 0.52;
    final pinHeight = size.height * 0.66;
    final pinTop = center.dy - (pinHeight * 0.55);

    final path = Path();
    // Top circle arc of pin
    final pinCenter = Offset(center.dx, pinTop + (pinWidth * 0.5));
    final pinHeadRadius = pinWidth * 0.5;

    path.addArc(
      Rect.fromCircle(center: pinCenter, radius: pinHeadRadius),
      -3.14159,
      3.14159,
    );

    // Downward triangle tip
    path.lineTo(center.dx + (pinWidth * 0.46), pinCenter.dy + (pinHeight * 0.1));
    path.lineTo(center.dx, pinTop + pinHeight);
    path.lineTo(center.dx - (pinWidth * 0.46), pinCenter.dy + (pinHeight * 0.1));
    path.close();

    final pinPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, pinPaint);

    // 3. Sky blue center dot inside the white pin
    final dotPaint = Paint()
      ..color = KaSpotColors.accentSkyBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinCenter, pinHeadRadius * 0.38, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
