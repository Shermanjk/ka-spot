import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'kaspot_service.dart';

/// Service managing user-controlled background location sharing.
///
/// Features:
/// - Explicit user consent toggle (OFF by default).
/// - Android foreground service notification ('KaSpot: Location Sharing Active').
/// - 5-meter distance filtering and 3-second interval for near-real-time tracking.
/// - Heartbeat every 30 seconds when stationary to keep the map marker fresh.
/// - Automatic transmission when the device is connected to the internet.
class BackgroundLocationService {
  BackgroundLocationService._();

  static final ValueNotifier<bool> isBackgroundSharingEnabled = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isStreamingActive = ValueNotifier<bool>(false);

  /// Emits every fresh GPS position from the background stream so the map
  /// screen can update the own-user marker without requiring a manual recenter.
  static final ValueNotifier<Position?> livePosition = ValueNotifier<Position?>(null);

  static StreamSubscription<Position>? _positionSubscription;
  static Timer? _heartbeatTimer;
  static DateTime? _lastFixAt;

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

    // Near-real-time settings:
    // - 5m distance filter: catches slow walking and fine movement
    // - 3s interval: map marker updates every ~3 seconds while moving
    late final LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'KaSpot · Live Sharing Active',
          notificationText: 'Sharing your location with your authorized circle',
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) async {
        try {
          livePosition.value = position;
          await KaSpotService.upsertOwnLocation(position);
          _lastFixAt = DateTime.now();
        } catch (e) {
          debugPrint('Background location transmission paused (will retry on next fix): $e');
        }
      },
      onError: (Object error) {
        debugPrint('Background location stream error: $error');
      },
    );

    // Heartbeat: with the 5m distance filter a stationary phone emits no stream
    // updates. Send a lightweight fix every 30 seconds so the map marker stays
    // live even when the user hasn't moved.
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final last = _lastFixAt;
      if (last != null && DateTime.now().difference(last) < const Duration(seconds: 20)) {
        return; // A movement update was already reported recently.
      }
      unawaited(_sendHeartbeat());
    });

    isStreamingActive.value = true;
    isBackgroundSharingEnabled.value = true;

    if (persist) {
      await KaSpotService.setNotificationPreference('background_sharing_enabled', true);
    }
  }

  /// One lightweight stationary fix, sent by the heartbeat timer.
  static Future<void> _sendHeartbeat() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      livePosition.value = position;
      await KaSpotService.upsertOwnLocation(position);
      _lastFixAt = DateTime.now();
      debugPrint('KaSpot heartbeat sent.');
    } catch (e) {
      debugPrint('KaSpot heartbeat skipped: $e');
    }
  }

  /// Stop background stream and dismiss ongoing notification.
  static Future<void> stopBackgroundTracking({bool persist = true}) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
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
