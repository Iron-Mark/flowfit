import 'dart:async';
import 'package:native_geofence/native_geofence.dart' as ng;
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';

/// A small native_geofence wrapper that maps `GeofenceMission` to the plugin's Geofence
/// and exposes a Dart Stream of plugin events. We register a top-level callback (entry point)
/// for background events.

class NativeGeofenceWrapper {
  static final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();

  static Stream<Map<String, dynamic>> get events => _controller.stream;

  static Future<void> initialize() async {
    try {
      await ng.NativeGeofenceManager.instance.initialize();
    } catch (_) {}
  }

  static Future<bool> register(GeofenceMission mission, {String? callbackName}) async {
    try {
      // Build a dynamic zone object to avoid relying on exact plugin types at compile-time.
      final dynamic zone = {
        'id': mission.id,
        'location': {'latitude': mission.center.latitude, 'longitude': mission.center.longitude},
        'radiusMeters': mission.radiusMeters,
        'triggers': ['enter', 'exit'],
        'iosSettings': {'initialTrigger': true},
        'androidSettings': {
          'initialTriggers': ['enter'],
          'expiration': const Duration(days: 7).inMilliseconds,
          'loiteringDelay': const Duration(minutes: 5).inMilliseconds,
          'notificationResponsiveness': const Duration(minutes: 5).inMilliseconds,
        }
      };
      // Default to shared callback name if not specified (not used currently)
      // Pass the top-level callback function for background handling.
      await ng.NativeGeofenceManager.instance.createGeofence(zone, flowfitGeofenceCallback);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unregister(String id) async {
    try {
      await ng.NativeGeofenceManager.instance.removeGeofenceById(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getRegisteredGeofences() async {
    try {
      return List<dynamic>.from(await ng.NativeGeofenceManager.instance.getRegisteredGeofences());
    } catch (_) {
      return [];
    }
  }

  static Future<void> promoteToForeground() => ng.NativeGeofenceBackgroundManager.instance.promoteToForeground();
  static Future<void> demoteToBackground() => ng.NativeGeofenceBackgroundManager.instance.demoteToBackground();

  /// Internal callback name used for registration.
  // No per-geofence callback name required; we register a single global callback

  @pragma('vm:entry-point')
  static Future<void> flowfitGeofenceCallback(dynamic params) async {
    // Convert to standard map to publish on the stream.
    try {
      final missionId = params.id ?? params['id'] ?? params['missionId'];
      final event = params.event?.toString() ?? (params['type'] ?? 'unknown');
      final loc = params.location ?? params['location'];
      final lat = loc?.latitude ?? loc?['latitude'] ?? loc?['lat'];
      final lon = loc?.longitude ?? loc?['longitude'] ?? loc?['lon'];
      final timestampMs = params.timestamp ?? params['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
      final map = <String, dynamic>{
        'missionId': missionId,
        'type': event,
        'lat': lat,
        'lon': lon,
        'timestamp': timestampMs,
      };
      _controller.add(map);
    } catch (_) {
      // Best-effort: if we can't parse, add raw param
      _controller.add({'raw': params});
    }
  }
}
