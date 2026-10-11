import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Result holder containing the optimized avatar bytes and metrics.
class ImageOptimizationResult {
  const ImageOptimizationResult({
    required this.bytes,
    required this.base64DataUri,
    required this.byteCount,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final String base64DataUri;
  final int byteCount;
  final int width;
  final int height;

  double get kilobytes => byteCount / 1024.0;
}

/// Pure Flutter in-memory avatar compression and square-cropping utility.
///
/// Guarantees that every user avatar is center-cropped and compressed to a
/// tiny footprint (target: 15 KB – 35 KB) without native C++ plugin dependencies.
class ImageOptimizer {
  ImageOptimizer._();

  static const int defaultDimension = 200;
  static const int maxTargetKilobytes = 35;

  /// Optimizes and center-crops [rawBytes] into a lightweight square avatar.
  ///
  /// - Pass 1: Square center-crops and scales to [defaultDimension] (200x200).
  /// - Pass 2 (Adaptive safety): If size exceeds [maxTargetKilobytes], scales to 150x150.
  /// - Pass 3 (Strict safety): If still over, scales to 120x120.
  static Future<ImageOptimizationResult> compressAvatar(
    Uint8List rawBytes, {
    int targetDimension = defaultDimension,
    int maxKb = maxTargetKilobytes,
  }) async {
    // 1. Initial pass at targetDimension (200x200)
    int currentDimension = targetDimension;
    Uint8List compressed = await _cropAndEncode(rawBytes, currentDimension);

    // 2. Adaptive safety pass: if > maxKb, step down to 150px
    if (compressed.lengthInBytes > maxKb * 1024 && currentDimension > 150) {
      currentDimension = 150;
      compressed = await _cropAndEncode(rawBytes, currentDimension);
    }

    // 3. Strict safety pass: if still > maxKb, step down to 120px
    if (compressed.lengthInBytes > maxKb * 1024 && currentDimension > 120) {
      currentDimension = 120;
      compressed = await _cropAndEncode(rawBytes, currentDimension);
    }

    final base64Uri = 'data:image/png;base64,${base64Encode(compressed)}';

    return ImageOptimizationResult(
      bytes: compressed,
      base64DataUri: base64Uri,
      byteCount: compressed.lengthInBytes,
      width: currentDimension,
      height: currentDimension,
    );
  }

  static Future<Uint8List> _cropAndEncode(Uint8List sourceBytes, int targetSize) async {
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frameInfo = await codec.getNextFrame();
    final original = frameInfo.image;

    final srcWidth = original.width.toDouble();
    final srcHeight = original.height.toDouble();
    final minSide = srcWidth < srcHeight ? srcWidth : srcHeight;

    // Center-crop bounding box
    final srcRect = Rect.fromCenter(
      center: Offset(srcWidth / 2, srcHeight / 2),
      width: minSide,
      height: minSide,
    );
    final dstRect = Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, dstRect);
    final paint = Paint()..filterQuality = FilterQuality.medium;

    canvas.drawImageRect(original, srcRect, dstRect, paint);
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(targetSize, targetSize);

    final byteData = await cropped.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
