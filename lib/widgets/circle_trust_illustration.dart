import 'package:flutter/material.dart';

/// Tasteful, lightweight custom illustration representing trusted circle members
/// connected via real-time location sharing. Uses pure Flutter CustomPainter
/// with zero external asset dependencies.
class CircleTrustIllustration extends StatefulWidget {
  const CircleTrustIllustration({
    super.key,
    this.height = 190,
  });

  final double height;

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
      duration: const Duration(seconds: 4),
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

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CircleTrustPainter(
              progress: disableAnimations ? 0.5 : _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _CircleTrustPainter extends CustomPainter {
  _CircleTrustPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;

    // 1. Concentric Soft Radar Pulse Rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 3; i++) {
      final pulse = (progress + (i * 0.33)) % 1.0;
      final radius = 30.0 + (pulse * 65.0);
      final opacity = ((1.0 - pulse) * 0.35).clamp(0.0, 0.35);

      ringPaint.color = const Color(0xFF2196F3).withValues(alpha: opacity);
      canvas.drawCircle(center, radius, ringPaint);
    }

    // 2. Member Node Coordinates
    final nodeSpread = (width * 0.28).clamp(70.0, 110.0);
    final leftNode = Offset(center.dx - nodeSpread, center.dy);
    final rightNode = Offset(center.dx + nodeSpread, center.dy);

    // 3. Curved Connection Arc
    final path = Path()
      ..moveTo(leftNode.dx, leftNode.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy - 34,
        rightNode.dx,
        rightNode.dy,
      );

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFCBD5E1);
    canvas.drawPath(path, trackPaint);

    final activeArcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E5EBF), Color(0xFF10B981)],
      ).createShader(Rect.fromPoints(leftNode, rightNode));
    canvas.drawPath(path, activeArcPaint);

    // 4. Moving Pulse Beacon along the Arc
    final beaconT = (progress * 2) % 1.0;
    final beaconX = (1 - beaconT) * (1 - beaconT) * leftNode.dx +
        2 * (1 - beaconT) * beaconT * center.dx +
        beaconT * beaconT * rightNode.dx;
    final beaconY = (1 - beaconT) * (1 - beaconT) * leftNode.dy +
        2 * (1 - beaconT) * beaconT * (center.dy - 34) +
        beaconT * beaconT * rightNode.dy;

    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(beaconX, beaconY), 9.0, glowPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(beaconX, beaconY), 4.0, dotPaint);

    // 5. Draw Member Nodes
    _drawMemberNode(canvas, leftNode, const Color(0xFF1E5EBF), Icons.person_rounded);
    _drawMemberNode(canvas, rightNode, const Color(0xFF0284C7), Icons.favorite_rounded);

    // 6. Floating Central Trust Shield
    final shieldCenter = Offset(center.dx, center.dy + 22);
    _drawTrustBadge(canvas, shieldCenter);
  }

  void _drawMemberNode(Canvas canvas, Offset offset, Color color, IconData icon) {
    // Outer glow
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(offset, 25, shadowPaint);

    // White border ring
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, 24, borderPaint);

    // Core circle
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, 20, corePaint);

    // Icon glyph inside
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 20,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }

  void _drawTrustBadge(Canvas canvas, Offset offset) {
    // Background pill
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: offset, width: 84, height: 26),
      const Radius.circular(13),
    );

    final bgPaint = Paint()
      ..color = const Color(0xFFECFDF5)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFA7F3D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rect, borderPaint);

    // Label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🛡️ Trusted',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF047857),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CircleTrustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
