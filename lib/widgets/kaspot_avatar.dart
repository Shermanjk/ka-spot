import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reusable KaSpot Avatar widget that supports:
/// - Base64 data URLs (`data:image/...;base64,...`) with in-memory byte caching
///   to prevent frame eviction during high-frequency heartbeat/radar animations
/// - Remote HTTP/HTTPS image URLs with progressive frame loading
/// - Local device file paths with cross-platform fallback
/// - Multi-layered solid backing so avatars never render hollow or transparent
/// - Dual-tone brand gradient with user's initial fallback
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
    this.backgroundColor,
  });

  final String name;
  final String? avatarUrl;
  final double size;
  final double? borderRadius;
  final bool isCircle;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  /// In-memory cache for decoded Base64 avatar bytes.
  /// Reuses identical [Uint8List] references across animation frames so that
  /// Flutter's [MemoryImage] provider recognizes cache identity and paints
  /// immediately without restarting decode on every animation tick.
  static final Map<String, Uint8List> _base64Cache = <String, Uint8List>{};

  /// Bounded cache limit to prevent memory growth across hundreds of avatar loads.
  static const int _maxCacheSize = 64;

  static Uint8List? _getOrDecodeBase64(String dataUri) {
    final cached = _base64Cache[dataUri];
    if (cached != null) return cached;

    try {
      final commaIndex = dataUri.indexOf(',');
      final base64Data = commaIndex != -1 ? dataUri.substring(commaIndex + 1) : dataUri;
      final bytes = base64Decode(base64Data);
      if (_base64Cache.length >= _maxCacheSize) {
        _base64Cache.remove(_base64Cache.keys.first);
      }
      _base64Cache[dataUri] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Clears the in-memory byte cache (used primarily for unit testing).
  @visibleForTesting
  static void clearCache() {
    _base64Cache.clear();
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim().characters.first.toUpperCase() : 'K';
    final radius = borderRadius ?? (isCircle ? size / 2 : 12.0);

    Widget? imageContent;
    final url = avatarUrl?.trim();

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        // Base64 data URI with cached byte reference
        final bytes = _getOrDecodeBase64(url);
        if (bytes != null) {
          imageContent = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return _buildFallbackInitial(initial);
            },
            errorBuilder: (_, _, _) => _buildFallbackInitial(initial),
          );
        }
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        // Remote Network URL
        imageContent = Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return _buildFallbackInitial(initial);
          },
          errorBuilder: (_, _, _) => _buildFallbackInitial(initial),
        );
      } else if (!kIsWeb && (url.startsWith('file://') || url.startsWith('/') || (url.length > 2 && url[1] == ':'))) {
        // Local file path (e.g. mobile gallery cache or desktop PC)
        try {
          final filePath = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
          final file = io.File(filePath);
          if (file.existsSync()) {
            imageContent = Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }
                return _buildFallbackInitial(initial);
              },
              errorBuilder: (_, _, _) => _buildFallbackInitial(initial),
            );
          }
        } catch (_) {
          imageContent = null;
        }
      }
    }

    final fallback = _buildFallbackInitial(initial);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF1E5EBF),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        border: showBorder ? Border.all(color: borderColor, width: borderWidth) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCircle ? size / 2 : radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            ?imageContent,
          ],
        ),
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
