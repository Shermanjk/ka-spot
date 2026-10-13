import 'package:flutter/material.dart';

/// Official KaSpot Owl App Icon Widget.
///
/// Renders the official pixel-perfect, crisp asset from [assets/logos/kaspot_owl_icon.png]
/// matching the exact Android launcher icon across all screen densities.
class KaSpotOwlIcon extends StatelessWidget {
  /// The width and height of the icon.
  final double size;

  /// Whether to render an ambient drop shadow beneath the badge.
  final bool hasShadow;

  const KaSpotOwlIcon({
    super.key,
    this.size = 80.0,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/logos/kaspot_owl_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

/// A composite brand header combining [KaSpotOwlIcon] with official typography.
class KaSpotBrandHeader extends StatelessWidget {
  final double iconSize;
  final bool showTagline;
  final bool isDark;

  const KaSpotBrandHeader({
    super.key,
    this.iconSize = 72.0,
    this.showTagline = true,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KaSpotOwlIcon(size: iconSize),
        const SizedBox(height: 14),
        Text(
          'KaSpot',
          style: TextStyle(
            fontSize: iconSize * 0.42,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Stay connected. Wherever life takes you.',
            style: TextStyle(
              fontSize: (iconSize * 0.18).clamp(11.0, 14.0),
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }
}
