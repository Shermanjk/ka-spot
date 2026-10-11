import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Reusable KaSpot Avatar widget that supports:
/// - Base64 data URLs (`data:image/...;base64,...`) from local device gallery/camera
/// - Remote HTTP/HTTPS image URLs
/// - Graceful fallback to dual-tone brand gradient with user's initial
class KaSpotAvatar extends StatelessWidget {
  const KaSpotAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 44,
    this.borderRadius,
    this.isCircle = true,
    this.showBorder = false,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
  });

  final String name;
  final String? avatarUrl;
  final double size;
  final double? borderRadius;
  final bool isCircle;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim().characters.first.toUpperCase() : 'K';
    final radius = borderRadius ?? (isCircle ? size / 2 : 12.0);

    Widget imageContent;

    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        // Base64 data URI
        try {
          final commaIndex = url.indexOf(',');
          final base64Data = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
          final Uint8List bytes = base64Decode(base64Data);
          imageContent = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallbackInitial(initial),
          );
        } catch (_) {
          imageContent = _buildFallbackInitial(initial);
        }
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        // Remote Network URL
        imageContent = Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackInitial(initial),
        );
      } else {
        imageContent = _buildFallbackInitial(initial);
      }
    } else {
      imageContent = _buildFallbackInitial(initial);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        border: showBorder ? Border.all(color: borderColor, width: borderWidth) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCircle ? size / 2 : radius),
        child: imageContent,
      ),
    );
  }

  Widget _buildFallbackInitial(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E5EBF), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: (size * 0.42).clamp(12.0, 32.0),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}
