import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KaSpotService {
  KaSpotService._();
  static SupabaseClient? _client;
  static void configure(SupabaseClient client) {
    _client = client;
    authStateNotifier.value = client.auth.currentUser != null;
    client.auth.onAuthStateChange.listen((data) {
      authStateNotifier.value = data.session != null;
    });
  }

  static SupabaseClient? get client => _client;
  static bool get isConfigured => _client != null;

  // Real authentication state listenable for clean reactive transitions
  static final ValueNotifier<bool> authStateNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<Map<String, dynamic>?> profileNotifier = ValueNotifier<Map<String, dynamic>?>(null);

  // Local session state (used when no Supabase backend is configured)
  static Map<String, dynamic>? _localUser;
  static final List<Map<String, dynamic>> _localSavedPlaces = [];
  static final List<Map<String, dynamic>> _localConnections = [];
  static final List<Map<String, dynamic>> _localRequests = [];
  static final Map<String, bool> _localSharingGrants = {};
  static final Map<String, dynamic> _localPrefs = {
    'connection_notifications_enabled': true,
    'arrival_alerts_enabled': false,
    'background_sharing_enabled': false,
  };

  static bool get isAuthenticated {
    if (_client != null) return _client!.auth.currentUser != null;
    return _localUser != null;
  }

  static String get userId {
    if (_client != null) return _client!.auth.currentUser?.id ?? '';
    return _localUser?['id'] as String? ?? '';
  }

  static Future<void> signIn(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_client != null) {
      await _client!.auth.signInWithPassword(email: cleanEmail, password: password);
      await ensureProfile();
    } else {
      // Local development session validation
      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        throw Exception('Please enter a valid email address.');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }
      final name = cleanEmail.split('@').first;
      final displayName = name.isNotEmpty ? '${name[0].toUpperCase()}${name.substring(1)}' : 'Member';
      _localUser = {
        'id': 'u-${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
        'email': cleanEmail,
        'display_name': displayName,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      profileNotifier.value = _localUser;
      authStateNotifier.value = true;
    }
  }

  static Future<void> register(String name, String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    if (_client != null) {
      final result = await _client!.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'display_name': cleanName},
      );
      if (result.session != null) await ensureProfile(name: cleanName);
    } else {
      // Local development registration
      if (cleanName.isEmpty) throw Exception('Please enter your name.');
      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        throw Exception('Please enter a valid email address.');
      }
      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters.');
      }
      _localUser = {
        'id': 'u-${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
        'email': cleanEmail,
        'display_name': cleanName,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      profileNotifier.value = _localUser;
      authStateNotifier.value = true;
    }
  }

  static Future<void> recoverPassword(String email) async {
    if (_client != null) {
      await _client!.auth.resetPasswordForEmail(email.trim());
    }
  }

  static Future<void> signOut() async {
    if (_client != null) {
      await _client!.auth.signOut();
    }
    _localUser = null;
    authStateNotifier.value = false;
    profileNotifier.value = null;
  }

  static Future<void> ensureProfile({String? name}) async {
    if (_client == null) return;
    final user = _client!.auth.currentUser;
    if (user == null) return;
    final displayName = name ??
        (user.userMetadata?['display_name'] as String?) ??
        user.email?.split('@').first ??
        'KaSpot member';
    await _client!.from('profiles').upsert({
      'id': user.id,
      'display_name': displayName,
    }, onConflict: 'id', ignoreDuplicates: true);
    profileNotifier.value = await myProfile();
  }

  static Future<Map<String, dynamic>?> myProfile() async {
    if (_client != null) {
      final rows = await _client!.from('profiles').select().eq('id', userId).limit(1);
      return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
    }
    return _localUser;
  }

  static Future<void> updateMyName(String name) async {
    final cleanName = name.trim();
    if (_client != null) {
      await _client!.from('profiles').upsert({
        'id': userId,
        'display_name': cleanName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');
    } else if (_localUser != null) {
      _localUser!['display_name'] = cleanName;
    }
    profileNotifier.value = await myProfile();
  }

  static Future<void> updateMyAvatar(String? avatarUrl) async {
    if (_client != null) {
      await _client!.from('profiles').upsert({
        'id': userId,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');
    } else if (_localUser != null) {
      _localUser!['avatar_url'] = avatarUrl;
    }
    profileNotifier.value = await myProfile();
  }

  static Future<List<Map<String, dynamic>>> requests() async {
    if (_client != null) {
      final rows = await _client!.from('connection_requests').select().or(
            'requester_id.eq.$userId,recipient_id.eq.$userId',
          ).order('created_at', ascending: false);
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    }
    return List<Map<String, dynamic>>.from(_localRequests);
  }

  static Future<void> sendRequest(String recipientId) async {
    final cleanId = recipientId.trim();
    if (cleanId == userId) throw Exception('You cannot connect to yourself.');

    if (_client != null) {
      await _client!.from('connection_requests').insert({
        'requester_id': userId,
        'recipient_id': cleanId,
      });
    } else {
      _localRequests.insert(0, {
        'id': 'req-${DateTime.now().millisecondsSinceEpoch}',
        'requester_id': userId,
        'recipient_id': cleanId,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  static Future<void> respondToRequest(String requestId, String status) async {
    if (_client != null) {
      await _client!.from('connection_requests').update({'status': status}).eq('id', requestId);
    } else {
      final index = _localRequests.indexWhere((r) => r['id'] == requestId);
      if (index != -1) {
        _localRequests[index]['status'] = status;
        if (status == 'accepted') {
          final otherId = _localRequests[index]['requester_id'] == userId
              ? _localRequests[index]['recipient_id']
              : _localRequests[index]['requester_id'];
          _localConnections.add({
            'id': 'conn-${DateTime.now().millisecondsSinceEpoch}',
            'other_id': otherId,
            'display_name': 'Connected Member',
          });
        }
      }
    }
  }

  static Future<List<Map<String, dynamic>>> connections() async {
    if (_client != null) {
      final rows = await _client!.from('connections').select().or(
            'user_a_id.eq.$userId,user_b_id.eq.$userId',
          );
      if (rows.isEmpty) return [];
      final ids = rows.map((row) => row['user_a_id'] == userId
          ? row['user_b_id'] as String
          : row['user_a_id'] as String).toSet().toList();
      final profiles = await _client!.from('profiles').select('id,display_name,avatar_url').inFilter('id', ids);
      final byId = {for (final profile in profiles) profile['id'] as String: profile};
      return rows.map((row) {
        final otherId = row['user_a_id'] == userId ? row['user_b_id'] as String : row['user_a_id'] as String;
        return {
          ...Map<String, dynamic>.from(row),
          'other_id': otherId,
          'display_name': byId[otherId]?['display_name'] ?? 'KaSpot member',
        };
      }).toList();
    }
    return List<Map<String, dynamic>>.from(_localConnections);
  }

  static Future<void> removeConnection(String connectionId) async {
    if (_client != null) {
      await _client!.from('connections').delete().eq('id', connectionId);
    } else {
      _localConnections.removeWhere((c) => c['id'] == connectionId);
    }
  }

  static Future<List<Map<String, dynamic>>> sharingGrants() async {
    if (_client != null) {
      final rows = await _client!.from('location_sharing').select().eq('owner_id', userId);
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    }
    return _localSharingGrants.entries
        .map((e) => {'recipient_id': e.key, 'is_enabled': e.value})
        .toList();
  }

  static Future<Map<String, bool>> incomingSharingStatus() async {
    if (_client != null) {
      final rows = await _client!.from('location_sharing')
          .select('owner_id,is_enabled').eq('recipient_id', userId);
      return {for (final row in rows) row['owner_id'] as String: row['is_enabled'] as bool};
    }
    return {};
  }

  static Future<void> setSharing(String recipientId, bool enabled) async {
    if (_client != null) {
      await _client!.from('location_sharing').upsert({
        'owner_id': userId,
        'recipient_id': recipientId,
        'is_enabled': enabled,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'owner_id,recipient_id');
      if (!enabled) await _removeLocationIfNoActiveGrants();
    } else {
      _localSharingGrants[recipientId] = enabled;
    }
  }

  static Future<void> setSharingForAll(bool enabled) async {
    if (_client != null) {
      final grants = await sharingGrants();
      for (final grant in grants) {
        await _client!.from('location_sharing').update({
          'is_enabled': enabled,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', grant['id']);
      }
      if (!enabled || grants.isEmpty) await _removeLocationIfNoActiveGrants();
    } else {
      for (final key in _localSharingGrants.keys) {
        _localSharingGrants[key] = enabled;
      }
    }
  }

  static Future<bool> anySharingEnabled() async {
    if (_client != null) {
      final rows = await _client!.from('location_sharing').select('id').eq('owner_id', userId).eq('is_enabled', true).limit(1);
      return rows.isNotEmpty;
    }
    return _localSharingGrants.values.any((enabled) => enabled);
  }

  static Future<void> upsertOwnLocation(Position position) async {
    if (!await anySharingEnabled()) return;
    if (_client != null) {
      await _client!.from('locations').upsert({
        'user_id': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    }
  }

  static Future<void> _removeLocationIfNoActiveGrants() async {
    if (_client != null && !await anySharingEnabled()) {
      await _client!.from('locations').delete().eq('user_id', userId);
    }
  }

  static Future<List<Map<String, dynamic>>> sharedLocations() async {
    if (_client != null) {
      final grants = await _client!.from('location_sharing')
          .select('owner_id').eq('recipient_id', userId).eq('is_enabled', true);
      if (grants.isEmpty) return [];
      final ids = grants.map((row) => row['owner_id'] as String).toSet().toList();
      final locations = await _client!.from('locations').select().inFilter('user_id', ids);
      final profiles = await _client!.from('profiles').select('id,display_name,avatar_url').inFilter('id', ids);
      final profileMap = {for (final profile in profiles) profile['id'] as String: profile};
      return locations.map((row) {
        final profile = profileMap[row['user_id']];
        return {
          ...Map<String, dynamic>.from(row),
          'display_name': profile?['display_name'] ?? 'KaSpot member',
          'avatar_url': profile?['avatar_url'] as String?,
        };
      }).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> savedPlaces() async {
    if (_client != null) {
      final rows = await _client!.from('saved_places').select().eq('user_id', userId).order('created_at');
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    }
    return List<Map<String, dynamic>>.from(_localSavedPlaces);
  }

  static Future<void> addSavedPlace(String name, Position position) async {
    final cleanName = name.trim();
    if (_client != null) {
      await _client!.from('saved_places').insert({
        'user_id': userId,
        'name': cleanName,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } else {
      _localSavedPlaces.insert(0, {
        'id': 'place-${DateTime.now().millisecondsSinceEpoch}',
        'name': cleanName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  static Future<void> deleteSavedPlace(String id) async {
    if (_client != null) {
      await _client!.from('saved_places').delete().eq('id', id);
    } else {
      _localSavedPlaces.removeWhere((p) => p['id'] == id);
    }
  }

  static Future<Map<String, dynamic>> notificationPreferences() async {
    if (_client != null) {
      final rows = await _client!.from('notification_preferences').select().eq('user_id', userId).limit(1);
      if (rows.isEmpty) {
        return {
          'connection_notifications_enabled': true,
          'arrival_alerts_enabled': false,
          'background_sharing_enabled': false,
        };
      }
      return Map<String, dynamic>.from(rows.first);
    }
    return Map<String, dynamic>.from(_localPrefs);
  }

  static Future<void> setNotificationPreference(String field, bool value) async {
    if (!{'connection_notifications_enabled', 'arrival_alerts_enabled', 'background_sharing_enabled'}.contains(field)) return;
    if (_client != null) {
      await _client!.from('notification_preferences').upsert({
        'user_id': userId,
        field: value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } else {
      _localPrefs[field] = value;
    }
  }
}
