import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'kaspot_service.dart';

/// Service managing user-controlled background location sharing.
///
/// Features:
/// - Explicit user consent toggle (OFF by default).
/// - Android foreground service notification ('KaSpot: Location Sharing Active').
/// - 50-meter distance filtering and 30-second interval throttling to protect battery.
/// - Automatic transmission when the device is connected to the internet.
class BackgroundLocationService {
  BackgroundLocationService._();

  static final ValueNotifier<bool> isBackgroundSharingEnabled = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isStreamingActive = ValueNotifier<bool>(false);

  static StreamSubscription<Position>? _positionSubscription;

  /// Loads persisted preference and starts service if user previously enabled it.
  static Future<void> initialize() async {
    try {
      final prefs = await KaSpotService.notificationPreferences();
      final enabled = prefs['background_sharing_enabled'] as bool? ?? false;
      isBackgroundSharingEnabled.value = enabled;

      if (enabled && KaSpotService.isAuthenticated) {
        await startBackgroundTracking(persist: false);
      }
    } catch (_) {}
  }

  /// Request required foreground & background permissions.
  static Future<bool> requestBackgroundPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Device location services are turned off. Please enable GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied. Background sharing cannot start.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please select "Allow all the time" in your device App Settings.',
      );
    }

    return true;
  }

  /// Start background stream with persistent foreground notification.
  static Future<void> startBackgroundTracking({bool persist = true}) async {
    await stopBackgroundTracking(persist: false);

    final hasPermission = await requestBackgroundPermission();
    if (!hasPermission) return;

    // Movement-optimized settings:
    // - 50m distance filter: phone sleeps when user is stationary (saving battery & egress!)
    // - 30s interval: smooth update rate when traveling
    late final LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'KaSpot · Live Sharing Active',
          notificationText: 'Sharing your location with your authorized circle',
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) async {
        try {
          await KaSpotService.upsertOwnLocation(position);
        } catch (e) {
          debugPrint('Background location transmission paused (will retry on next fix): $e');
        }
      },
      onError: (Object error) {
        debugPrint('Background location stream error: $error');
      },
    );

    isStreamingActive.value = true;
    isBackgroundSharingEnabled.value = true;

    if (persist) {
      await KaSpotService.setNotificationPreference('background_sharing_enabled', true);
    }
  }

  /// Stop background stream and dismiss ongoing notification.
  static Future<void> stopBackgroundTracking({bool persist = true}) async {
    if (_positionSubscription != null) {
      await _positionSubscription!.cancel();
      _positionSubscription = null;
    }

    isStreamingActive.value = false;
    isBackgroundSharingEnabled.value = false;

    if (persist) {
      await KaSpotService.setNotificationPreference('background_sharing_enabled', false);
    }
  }

  /// Toggle background sharing mode with consent and preference persistence.
  static Future<void> toggleBackgroundSharing(bool enabled) async {
    if (enabled) {
      await startBackgroundTracking(persist: true);
    } else {
      await stopBackgroundTracking(persist: true);
    }
  }
}
