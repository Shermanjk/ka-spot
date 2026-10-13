import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 100% pure Flutter, vector-animated 3D perspective globe hero illustration for KaSpot.
///
/// Features:
/// - 3D curved globe horizon & perspective latitude/longitude grid terrain.
/// - Centered KaSpot profile beacon — a larger, unique "You" avatar badge standing on the tracked spot, with a gentle breathing pulse & pulsing cyan halo aura.
/// - 4 active orbiting member avatar pins (Cobalt Blue, Emerald Green, Purple, Sky Blue).
/// - Dynamic 3D depth scaling (foreground pins scale up with full brightness, background pins recede).
/// - Live constellation connection beams with traveling signal light packets.
/// - 100% mathematically seamless looping with zero pops, jumps, or resets.
/// - 100% vector rendering — pure Flutter, no raster assets.
/// - Respects [MediaQuery.disableAnimations] for accessibility.
class CircleTrustIllustration extends StatefulWidget {
  const CircleTrustIllustration({
    super.key,
    this.height = 230,
    this.child,
  });

  final double height;
  final Widget? child;

  @override
  State<CircleTrustIllustration> createState() => _CircleTrustIllustrationState();
}

class _CircleTrustIllustrationState extends State<CircleTrustIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final animationLayer = RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _Vector3DGlobeHeroPainter(
                progress: disableAnimations ? 0.35 : _controller.value,
              ),
            );
          },
        ),
      ),
    );

    if (widget.child == null) {
      return animationLayer;
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: animationLayer),
          Center(child: widget.child!),
        ],
      ),
    );
  }
}

class _Vector3DGlobeHeroPainter extends CustomPainter {
  _Vector3DGlobeHeroPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Ground focal point where the central beacon touches the 3D globe surface
    final groundCenter = Offset(width * 0.50, height * 0.60);

    // 1. Sky Atmosphere & Curved Globe Horizon
    _drawAtmosphereAndGlobe(canvas, width, height, groundCenter);

    // 2. Perspective Curved Coordinate Grid Lines
    _drawPerspectiveGrid(canvas, width, height, groundCenter);

    // 3. Concentric Cyan Radar Ripple Waves on Terrain
    _drawRadarRipples(canvas, groundCenter, width);

    // 4. Dedicated Ground Center Anchor & Target Point
    _drawCenterPointAnchor(canvas, groundCenter);

    // 5. Four Active Orbiting Member Avatar Pins (with 3D depth scaling)
    _drawOrbitingMembers(canvas, groundCenter, width, height);

    // 6. Central KaSpot Profile Beacon — "You" avatar badge on the tracked spot
    _drawCenterProfileBeacon(canvas, groundCenter);

    // 7. Ambient Constellation Particles / Light Flares
    _drawAmbientSparkles(canvas, width, height);
  }

  /// Soft morning sky glow and ambient globe bloom
  void _drawAtmosphereAndGlobe(Canvas canvas, double width, double height, Offset groundCenter) {
    // A. Central Ethereal Cyan Radial Bloom
    final bloomRadius = (width * 0.45).clamp(110.0, 200.0);
    final bloomPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.32),
          const Color(0xFF0284C7).withValues(alpha: 0.12),
          const Color(0xFFBAE6FD).withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: groundCenter, radius: bloomRadius));
    canvas.drawCircle(groundCenter, bloomRadius, bloomPaint);

    // B. Stylized Organic Landmass Contours on Globe
    _drawLandmassContours(canvas, width, height, groundCenter);
  }

  /// Stylized landmass silhouettes in soft green/blue tints
  void _drawLandmassContours(Canvas canvas, double width, double height, Offset groundCenter) {
    final landPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6EE7B7).withValues(alpha: 0.14);

    final landPaintBlue = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.16);

    // Left landmass patch
    final land1 = Path()
      ..moveTo(width * 0.12, height * 0.50)
      ..cubicTo(width * 0.18, height * 0.38, width * 0.28, height * 0.44, width * 0.34, height * 0.52)
      ..cubicTo(width * 0.30, height * 0.62, width * 0.20, height * 0.65, width * 0.12, height * 0.50);
    canvas.drawPath(land1, landPaint);

    // Right landmass patch
    final land2 = Path()
      ..moveTo(width * 0.65, height * 0.42)
      ..cubicTo(width * 0.76, height * 0.36, width * 0.88, height * 0.46, width * 0.84, height * 0.58)
      ..cubicTo(width * 0.75, height * 0.64, width * 0.62, height * 0.54, width * 0.65, height * 0.42);
    canvas.drawPath(land2, landPaintBlue);
  }

  /// 3D perspective latitude and longitude coordinate grid
  void _drawPerspectiveGrid(Canvas canvas, double width, double height, Offset groundCenter) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // 4 Elliptical Latitude rings
    for (int i = 1; i <= 4; i++) {
      final rx = width * (0.16 + i * 0.11);
      final ry = rx * 0.36; // 3D Perspective tilt ratio
      final alpha = (0.08 + i * 0.04).clamp(0.06, 0.24);

      gridPaint.color = const Color(0xFF38BDF8).withValues(alpha: alpha);
      canvas.drawOval(
        Rect.fromCenter(center: groundCenter, width: rx * 2, height: ry * 2),
        gridPaint,
      );
    }

    // 5 Longitude perspective arcs converging towards the horizon
    final longPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.15);

    for (int i = -2; i <= 2; i++) {
      final bottomX = groundCenter.dx + (i * width * 0.22);
      final topX = groundCenter.dx + (i * width * 0.10);
      final p = Path()
        ..moveTo(bottomX, height * 0.82)
        ..quadraticBezierTo(
          groundCenter.dx + (i * width * 0.14),
          groundCenter.dy,
          topX,
          height * 0.28,
        );
      canvas.drawPath(p, longPaint);
    }
  }

  /// Concentric cyan ripple waves expanding continuously from central pin contact
  void _drawRadarRipples(Canvas canvas, Offset groundCenter, double width) {
    for (int i = 0; i < 3; i++) {
      final waveT = (progress + (i / 3.0)) % 1.0;
      final maxRx = width * 0.36;
      final rx = 16.0 + (waveT * maxRx);
      final ry = rx * 0.36;

      // Symmetrical sine envelope: 0 at start, peak at 0.5, 0 at perimeter
      final envelope = math.sin(waveT * math.pi);
      final opacity = (envelope * 0.40).clamp(0.0, 0.40);
      if (opacity <= 0.002) continue;

      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = const Color(0xFF00E5FF).withValues(alpha: opacity);

      canvas.drawOval(
        Rect.fromCenter(center: groundCenter, width: rx * 2, height: ry * 2),
        ripplePaint,
      );
    }
  }

  /// 4 Active Orbiting Member Avatar Pins with dynamic 3D depth scaling
  void _drawOrbitingMembers(Canvas canvas, Offset groundCenter, double width, double height) {
    // 🔵 Node 1 (Cobalt Blue): Top-Left Harmonic Orbit
    _drawMemberPin(
      canvas: canvas,
      groundCenter: groundCenter,
      width: width,
      rx: (width * 0.34).clamp(90.0, 140.0),
      ry: 38.0,
      tiltRad: 0.16,
      revolutions: 1,
      phaseOffset: 0.20,
      color: const Color(0xFF1E5EBF),
      pinLabel: 'blue',
    );

    // 🟢 Node 2 (Emerald Green): Top-Right Counter Orbit
    _drawMemberPin(
      canvas: canvas,
      groundCenter: groundCenter,
      width: width,
      rx: (width * 0.38).clamp(100.0, 160.0),
      ry: 42.0,
      tiltRad: -0.20,
      revolutions: -1,
      phaseOffset: 0.70,
      color: const Color(0xFF10B981),
      pinLabel: 'green',
    );

    // 🟣 Node 3 (Purple/Violet): Mid-Left Inner Orbit
    _drawMemberPin(
      canvas: canvas,
      groundCenter: groundCenter,
      width: width,
      rx: (width * 0.28).clamp(75.0, 115.0),
      ry: 32.0,
      tiltRad: 0.26,
      revolutions: 1,
      phaseOffset: 0.48,
      color: const Color(0xFF8B5CF6),
      pinLabel: 'purple',
    );

    // 🔵 Node 4 (Sky Blue): Mid-Right Wide Orbit
    _drawMemberPin(
      canvas: canvas,
      groundCenter: groundCenter,
      width: width,
      rx: (width * 0.36).clamp(95.0, 150.0),
      ry: 40.0,
      tiltRad: -0.12,
      revolutions: 1,
      phaseOffset: 0.95,
      color: const Color(0xFF0284C7),
      pinLabel: 'sky',
    );
  }

  void _drawMemberPin({
    required Canvas canvas,
    required Offset groundCenter,
    required double width,
    required double rx,
    required double ry,
    required double tiltRad,
    required int revolutions,
    required double phaseOffset,
    required Color color,
    required String pinLabel,
  }) {
    // Exact mathematical angle ensuring 100% seamless continuity
    final theta = ((progress * revolutions) + phaseOffset) * 2 * math.pi;

    // Parametric point on untilted ellipse
    final unrotX = rx * math.cos(theta);
    final unrotY = ry * math.sin(theta);

    // 3D rotation by tilt angle
    final cosT = math.cos(tiltRad);
    final sinT = math.sin(tiltRad);
    final rotX = (unrotX * cosT) - (unrotY * sinT);
    final rotY = (unrotX * sinT) + (unrotY * cosT);

    final groundContact = Offset(groundCenter.dx + rotX, groundCenter.dy + rotY);

    // 3D Depth calculation: points lower on the tilted plane appear closer to the user
    final depth = (math.sin(theta) * 0.5 + 0.5); // 0.0 (back) to 1.0 (front)
    final scale = 0.80 + (depth * 0.36); // 0.80x to 1.16x
    final opacity = (0.55 + (depth * 0.45)).clamp(0.50, 1.0);

    // A. Constellation Connection Beam from Member to Central Beacon
    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.22 * opacity);
    canvas.drawLine(groundCenter, groundContact, beamPaint);

    // Traveling light signal pulse along the beam
    final signalT = (progress * 2.0 + phaseOffset) % 1.0;
    final sx = groundCenter.dx + (groundContact.dx - groundCenter.dx) * signalT;
    final sy = groundCenter.dy + (groundContact.dy - groundCenter.dy) * signalT;
    final signalFade = math.sin(signalT * math.pi);
    if (signalFade > 0.05) {
      final pulsePaint = Paint()
        ..color = Colors.white.withValues(alpha: signalFade * 0.85 * opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sx, sy), 2.2 * scale, pulsePaint);
    }

    // B. Ground Shadow & Glowing Ground Ring
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.30 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: groundContact, width: 18 * scale, height: 7 * scale),
      shadowPaint,
    );

    // Ground ripple ring
    final groundRingPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromCenter(center: groundContact, width: 22 * scale, height: 9 * scale),
      groundRingPaint,
    );

    // C. Elevated Member Pin Position
    final pinHeadCenter = Offset(groundContact.dx, groundContact.dy - (18 * scale));
    final headRadius = 12.0 * scale;

    // Pin stem connecting head to ground
    final stemPath = Path()
      ..moveTo(groundContact.dx, groundContact.dy)
      ..lineTo(pinHeadCenter.dx - headRadius * 0.75, pinHeadCenter.dy + headRadius * 0.2)
      ..lineTo(pinHeadCenter.dx + headRadius * 0.75, pinHeadCenter.dy + headRadius * 0.2)
      ..close();
    final stemPaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(stemPath, stemPaint);

    // Outer soft glow halo
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.28 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinHeadCenter, headRadius + (3.5 * scale), haloPaint);

    // Crisp white border ring
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinHeadCenter, headRadius + (1.2 * scale), borderPaint);

    // Solid colorful core badge
    final corePaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinHeadCenter, headRadius, corePaint);

    // D. White Person / Avatar Silhouette Glyph inside Badge
    _drawAvatarSilhouette(canvas, pinHeadCenter, headRadius * 0.55, opacity);
  }

  /// Clean, vector avatar/person silhouette (head circle + shoulder arc)
  void _drawAvatarSilhouette(Canvas canvas, Offset center, double size, double opacity) {
    final avatarPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.95)
      ..style = PaintingStyle.fill;

    // Head
    final headCenter = Offset(center.dx, center.dy - size * 0.36);
    canvas.drawCircle(headCenter, size * 0.36, avatarPaint);

    // Shoulders
    final shoulderPath = Path()
      ..moveTo(center.dx - size * 0.75, center.dy + size * 0.65)
      ..cubicTo(
        center.dx - size * 0.70, center.dy + size * 0.05,
        center.dx + size * 0.70, center.dy + size * 0.05,
        center.dx + size * 0.75, center.dy + size * 0.65,
      )
      ..close();
    canvas.drawPath(shoulderPath, avatarPaint);
  }

  /// Dedicated Ground Center Anchor & Target Point
  void _drawCenterPointAnchor(Canvas canvas, Offset groundCenter) {
    // A. Soft oval contact shadow on the terrain (pin is planted — static)
    final shadowPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: groundCenter, width: 38, height: 13),
      shadowPaint,
    );

    // B. Concentric glowing target ring on the ground
    final targetRingPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawOval(
      Rect.fromCenter(center: groundCenter, width: 22, height: 8),
      targetRingPaint,
    );

    // C. Solid glowing focal center dot marking exact coordinate origin
    final focalDotPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: groundCenter, width: 6.0, height: 2.8),
      focalDotPaint,
    );
  }

  /// Central KaSpot "You" Profile Beacon — a larger, unique avatar badge
  /// standing on the tracked spot.
  ///
  /// Shares the member-pin family (white-bordered circle + white avatar glyph)
  /// but stands out with a gradient core, a slim stem, an orbiting beacon halo
  /// ring, a gentle breathing pulse and the luminous pulsing cyan aura.
  void _drawCenterProfileBeacon(Canvas canvas, Offset groundCenter) {
    final pulseScale = 1.0 + math.sin(progress * 2 * math.pi) * 0.02;

    // Badge proportions — deliberately larger than the orbiting member pins.
    const badgeRadius = 22.0;
    const badgeCenterLift = 34.0; // badge centre above the ground contact
    const badgeCenter = Offset(0, -badgeCenterLift);

    canvas.save();
    // Scale around the ground contact so the beacon stays planted.
    canvas.translate(groundCenter.dx, groundCenter.dy);
    canvas.scale(pulseScale);

    // A. Luminous Pulsing Cyan / Sky-Blue Halo Aura
    const auraRadius = 44.0;
    final auraPulse = math.sin(progress * 2 * math.pi) * 0.5 + 0.5;
    final auraOpacity = (0.28 + auraPulse * 0.22).clamp(0.20, 0.55);
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: auraOpacity),
          const Color(0xFF0D8AD1).withValues(alpha: auraOpacity * 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: badgeCenter, radius: auraRadius));
    canvas.drawCircle(badgeCenter, auraRadius, auraPaint);

    // B. Slim rounded stem connecting the badge to the tracked spot
    final stemWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;
    final stemCore = Paint()
      ..color = const Color(0xFF0A6BAF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -1), const Offset(0, -14), stemWhite);
    canvas.drawLine(const Offset(0, -1), const Offset(0, -14), stemCore);

    // C. Unique beacon halo ring orbiting the badge (no member pin has this)
    final haloRingPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.30 + auraPulse * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(badgeCenter, badgeRadius + 6.5, haloRingPaint);

    // D. Crisp white border ring (member-pin family look, thicker at this size)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius + 2.6, borderPaint);

    // E. Gradient core badge (unique to the center — members use flat colors)
    final corePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3FB2EE), Color(0xFF0A6BAF)],
      ).createShader(Rect.fromCircle(center: badgeCenter, radius: badgeRadius));
    canvas.drawCircle(badgeCenter, badgeRadius, corePaint);

    // Soft inner bevel rim for depth
    final bevelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(badgeCenter, badgeRadius - 2.2, bevelPaint);

    // F. Bigger white person / avatar glyph (same silhouette family as members)
    _drawAvatarSilhouette(canvas, badgeCenter, badgeRadius * 0.56, 1.0);

    // G. Soft specular highlight for a polished 3D read
    canvas.save();
    canvas.translate(badgeCenter.dx - badgeRadius * 0.32, badgeCenter.dy - badgeRadius * 0.42);
    canvas.rotate(-0.31);
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.26);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: badgeRadius * 0.42, height: badgeRadius * 0.55),
      highlightPaint,
    );
    canvas.restore();

    canvas.restore();
  }

  /// Floating ambient constellation particles & sparkle orbs
  void _drawAmbientSparkles(Canvas canvas, double width, double height) {
    final sparkles = [
      Offset(width * 0.20, height * 0.32),
      Offset(width * 0.82, height * 0.30),
      Offset(width * 0.40, height * 0.24),
      Offset(width * 0.62, height * 0.26),
    ];

    for (int i = 0; i < sparkles.length; i++) {
      final t = (progress + (i * 0.25)) % 1.0;
      final pulse = math.sin(t * 2 * math.pi) * 0.5 + 0.5;
      final opacity = (0.25 + pulse * 0.55).clamp(0.0, 0.80);

      final glow = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: opacity * 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sparkles[i], 5.0, glow);

      final core = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sparkles[i], 1.8, core);
    }
  }

  @override
  bool shouldRepaint(covariant _Vector3DGlobeHeroPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
