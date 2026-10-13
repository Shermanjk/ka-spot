import 'package:flutter/material.dart';

/// Clean, official-style Google Sign-In button adhering to Google Identity guidelines.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.label = 'Continue with Google',
    this.busyLabel = 'Signing in…',
  });

  final VoidCallback? onPressed;
  final bool busy;
  final String label;

  /// Replaces [label] next to the spinner while [busy] is true, so the tapped
  /// button itself reports progress (e.g. "Signing in…", "Creating account…").
  final String busyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: busy ? null : onPressed,
          child: Center(
            child: busy
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF1E60AA),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            busyLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E60AA),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CustomPaint(
                          size: Size(20, 20),
                          painter: _GoogleLogoPainter(),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Razor-sharp vector painter for the official 4-color Google "G" logo.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    // Blue
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(23.75, 12.27)
      ..cubicTo(23.75, 11.48, 23.68, 10.73, 23.55, 10.01)
      ..lineTo(12.0, 10.01)
      ..lineTo(12.0, 14.77)
      ..lineTo(18.6, 14.77)
      ..cubicTo(18.31, 16.32, 17.42, 17.63, 16.08, 18.52)
      ..lineTo(16.08, 21.65)
      ..lineTo(20.14, 21.65)
      ..cubicTo(22.52, 19.46, 23.75, 16.16, 23.75, 12.27)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.92, 19.95, 21.08)
      ..lineTo(16.08, 18.08)
      ..cubicTo(14.99, 18.81, 13.6, 19.26, 12.0, 19.26)
      ..cubicTo(8.87, 19.26, 6.22, 17.15, 5.27, 14.3)
      ..lineTo(1.07, 14.3)
      ..lineTo(1.07, 17.56)
      ..cubicTo(3.15, 21.69, 7.26, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.27, 14.29)
      ..cubicTo(5.03, 13.57, 4.9, 12.8, 4.9, 12.0)
      ..cubicTo(4.9, 11.2, 5.03, 10.43, 5.27, 9.71)
      ..lineTo(5.27, 6.44)
      ..lineTo(1.07, 6.44)
      ..cubicTo(0.25, 8.08, -0.2, 9.97, -0.2, 12.0)
      ..cubicTo(-0.2, 14.03, 0.25, 15.92, 1.07, 17.56)
      ..lineTo(5.27, 14.29)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0, 4.74)
      ..cubicTo(13.76, 4.74, 15.34, 5.35, 16.59, 6.54)
      ..lineTo(20.04, 3.09)
      ..cubicTo(17.95, 1.15, 15.23, 0.0, 12.0, 0.0)
      ..cubicTo(7.26, 0.0, 3.15, 2.31, 1.07, 6.44)
      ..lineTo(5.27, 9.71)
      ..cubicTo(6.22, 6.85, 8.87, 4.74, 12.0, 4.74)
      ..close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
