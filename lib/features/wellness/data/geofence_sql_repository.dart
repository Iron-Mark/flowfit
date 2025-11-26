import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/geofence_mission.dart';
import 'geofence_repository.dart';

class GeofenceSqlRepository extends GeofenceRepository {
  Database? _db;
  List<GeofenceMission> _cache = [];

  Future<void> _init() async {
    if (_db != null) return;
    final documentsDirectory = await getDatabasesPath();
    final path = p.join(documentsDirectory, 'geofence_missions.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE missions(
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          latitude REAL,
          longitude REAL,
          radius REAL,
          type TEXT,
          isActive INTEGER,
          targetDistance REAL,
          status TEXT
        );
      ''');
    });
    await _loadCache();
  }

  Future<void> _loadCache() async {
    if (_db == null) return;
    final rows = await _db!.query('missions');
    _cache = rows.map((r) {
      return GeofenceMission(
        id: r['id'] as String,
        title: r['title'] as String? ?? '',
        description: r['description'] as String?,
        center: LatLngSimple(r['latitude'] as double, r['longitude'] as double),
        radiusMeters: (r['radius'] as num?)?.toDouble() ?? 50.0,
        type: _missionTypeFromString(r['type'] as String?),
        isActive: (r['isActive'] as int?) == 1,
        targetDistanceMeters: (r['targetDistance'] as num?)?.toDouble(),
        status: _statusFromString(r['status'] as String?),
      );
    }).toList();
  }

  static MissionType _missionTypeFromString(String? s) {
    if (s == 'target') return MissionType.target;
    if (s == 'safetyNet') return MissionType.safetyNet;
    return MissionType.sanctuary;
  }

  static GeofenceStatus _statusFromString(String? s) {
    if (s == 'inside') return GeofenceStatus.inside;
    if (s == 'outside') return GeofenceStatus.outside;
    return GeofenceStatus.unknown;
  }

  static String _missionTypeToString(MissionType t) {
    return describeEnum(t);
  }

  static String _statusToString(GeofenceStatus s) => describeEnum(s);

  @override
  List<GeofenceMission> get current => List.unmodifiable(_cache);

  @override
  Future<List<GeofenceMission>> getAll() async {
    await _init();
    return current;
  }

  @override
  GeofenceMission? getById(String id) {
    try {
      return _cache.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> add(GeofenceMission mission) async {
    await _init();
    await _db!.insert('missions', {
      'id': mission.id,
      'title': mission.title,
      'description': mission.description,
      'latitude': mission.center.latitude,
      'longitude': mission.center.longitude,
      'radius': mission.radiusMeters,
      'type': _missionTypeToString(mission.type),
      'isActive': mission.isActive ? 1 : 0,
      'targetDistance': mission.targetDistanceMeters,
      'status': _statusToString(mission.status),
    });
    await _loadCache();
    notifyListeners();
  }

  @override
  Future<void> update(GeofenceMission mission) async {
    await _init();
    await _db!.update('missions', {
      'title': mission.title,
      'description': mission.description,
      'latitude': mission.center.latitude,
      'longitude': mission.center.longitude,
      'radius': mission.radiusMeters,
      'type': _missionTypeToString(mission.type),
      'isActive': mission.isActive ? 1 : 0,
      'targetDistance': mission.targetDistanceMeters,
      'status': _statusToString(mission.status),
    }, where: 'id = ?', whereArgs: [mission.id]);
    await _loadCache();
    notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    await _init();
    await _db!.delete('missions', where: 'id = ?', whereArgs: [id]);
    await _loadCache();
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    await _init();
    await _db!.delete('missions');
    await _loadCache();
    notifyListeners();
  }
}
