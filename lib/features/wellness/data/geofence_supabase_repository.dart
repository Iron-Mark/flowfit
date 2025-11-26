// supabase-backed Geofence repository
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/geofence_mission.dart';
import 'geofence_repository.dart';

class GeofenceSupabaseRepository extends GeofenceRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final List<GeofenceMission> _cache = [];

  Future<void> _loadCache() async {
    final response = await _client.from('geofence_missions').select();
    final data = response as List<dynamic>;
    _cache.clear();
    for (final row in data) {
      final r = row as Map<String, dynamic>;
      _cache.add(_rowToMission(r));
    }
    notifyListeners();
  }

  GeofenceMission _rowToMission(Map<String, dynamic> r) {
    return GeofenceMission(
      id: r['id'] as String,
      title: r['title'] as String? ?? '',
      description: r['description'] as String?,
      center: LatLngSimple((r['latitude'] as num).toDouble(), (r['longitude'] as num).toDouble()),
      radiusMeters: (r['radius'] as num?)?.toDouble() ?? 50.0,
      type: _typeFromString(r['type'] as String?),
      isActive: (r['isActive'] as bool?) ?? false,
      targetDistanceMeters: (r['targetDistance'] as num?)?.toDouble(),
      status: _statusFromString(r['status'] as String?),
    );
  }

  static MissionType _typeFromString(String? s) {
    if (s == 'target') return MissionType.target;
    if (s == 'safetyNet') return MissionType.safetyNet;
    return MissionType.sanctuary;
  }

  static GeofenceStatus _statusFromString(String? s) {
    if (s == 'inside') return GeofenceStatus.inside;
    if (s == 'outside') return GeofenceStatus.outside;
    return GeofenceStatus.unknown;
  }

  static String _typeToString(MissionType t) => describeEnum(t);
  static String _statusToString(GeofenceStatus s) => describeEnum(s);

  @override
  List<GeofenceMission> get current => List.unmodifiable(_cache);

  @override
  Future<List<GeofenceMission>> getAll() async {
    await _loadCache();
    return current;
  }

  @override
  GeofenceMission? getById(String id) {
    try {
      return _cache.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> add(GeofenceMission mission) async {
    final payload = {
      'id': mission.id,
      'title': mission.title,
      'description': mission.description,
      'latitude': mission.center.latitude,
      'longitude': mission.center.longitude,
      'radius': mission.radiusMeters,
      'type': _typeToString(mission.type),
      'isActive': mission.isActive,
      'targetDistance': mission.targetDistanceMeters,
      'status': _statusToString(mission.status),
    };
    try {
      await _client.from('geofence_missions').insert(payload);
    } catch (_) {
      // simply continue - offline mode or not configured
      _cache.add(mission);
      notifyListeners();
      return;
    }
    await _loadCache();
  }

  @override
  Future<void> update(GeofenceMission mission) async {
    // optimistic update
    final i = _cache.indexWhere((e) => e.id == mission.id);
    if (i >= 0) _cache[i] = mission;
    notifyListeners();

    final payload = {
      'title': mission.title,
      'description': mission.description,
      'latitude': mission.center.latitude,
      'longitude': mission.center.longitude,
      'radius': mission.radiusMeters,
      'type': _typeToString(mission.type),
      'isActive': mission.isActive,
      'targetDistance': mission.targetDistanceMeters,
      'status': _statusToString(mission.status),
    };
    try {
      await _client.from('geofence_missions').update(payload).eq('id', mission.id);
    } catch (_) {
      // fallback: keep cache
      return;
    }
    await _loadCache();
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.from('geofence_missions').delete().eq('id', id);
    } catch (_) {
      _cache.removeWhere((e) => e.id == id);
      notifyListeners();
      return;
    }
    await _loadCache();
  }

  @override
  Future<void> clear() async {
    // Simple backup: remove all local cache and attempt to clear server
    try {
      await _client.from('geofence_missions').delete();
    } catch (_) {}
    _cache.clear();
    notifyListeners();
  }

  /// A simple sync strategy: push local to supabase, then pull remote.
  Future<void> sync() async {
    // push local
    for (final mission in _cache) {
      await _client.from('geofence_missions').upsert({
        'id': mission.id,
        'title': mission.title,
        'description': mission.description,
        'latitude': mission.center.latitude,
        'longitude': mission.center.longitude,
        'radius': mission.radiusMeters,
        'type': _typeToString(mission.type),
        'isActive': mission.isActive,
        'targetDistance': mission.targetDistanceMeters,
        'status': _statusToString(mission.status),
      });
    }
    // pull remote
    await _loadCache();
  }
}
