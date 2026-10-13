import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'kaspot_service.dart';

/// Tracks whether the device currently has a network connection and triggers
/// the offline location queue's auto-sync the moment connectivity returns.
///
/// Note: connectivity_plus reports the presence of a network interface, not
/// guaranteed internet access (e.g. a dead Wi-Fi hotspot). This is accepted:
/// a failed upload simply stays queued and is retried on the next fix or
/// heartbeat.
class ConnectivityService {
  ConnectivityService._();

  /// Live network state for UI and services. Defaults to true so nothing is
  /// flagged offline before the first check completes.
  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _initialized = false;

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Reads the current state once and then keeps [isOnline] updated. Called
  /// from main() only. When the connection returns, any location fix that was
  /// queued while offline is flushed automatically.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final results = await Connectivity().checkConnectivity();
      isOnline.value = _hasConnection(results);
    } catch (_) {
      // Keep the optimistic default; the stream below will correct it.
    }

    try {
      _subscription = Connectivity().onConnectivityChanged.listen((results) {
        final online = _hasConnection(results);
        final wasOnline = isOnline.value;
        isOnline.value = online;
        if (online && !wasOnline) {
          // Auto-sync: upload the latest fix that failed while offline.
          unawaited(KaSpotService.flushPendingLocation());
        }
      });
    } catch (_) {}
  }

  /// Test-only reset so listeners/state never leak between test cases.
  @visibleForTesting
  static void resetForTest() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
    isOnline.value = true;
  }
}
