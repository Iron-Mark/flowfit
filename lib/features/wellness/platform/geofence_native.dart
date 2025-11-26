import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';

class GeofenceNative {
  static const MethodChannel _channel = MethodChannel('com.flowfit.geofence/native');
  static const EventChannel _events = EventChannel('com.flowfit.geofence/events');

  static Future<bool> register(GeofenceMission mission) async {
    try {
      await _channel.invokeMethod('registerGeofence', {
        'id': mission.id,
        'lat': mission.center.latitude,
        'lon': mission.center.longitude,
        'radius': mission.radiusMeters,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unregister(String id) async {
    try {
      await _channel.invokeMethod('unregisterGeofence', {'id': id});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Stream<dynamic> get events => _events.receiveBroadcastStream();
}
