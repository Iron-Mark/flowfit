
enum MissionType { target, sanctuary, safetyNet }

enum GeofenceStatus { unknown, inside, outside }

class LatLngSimple {
  final double latitude;
  final double longitude;
  const LatLngSimple(this.latitude, this.longitude);
}

class GeofenceMission {
  final String id;
  String title;
  String? description;
  LatLngSimple center;
  double radiusMeters;
  MissionType type;
  bool isActive;
  double? targetDistanceMeters; // Only for target missions

  // Runtime only
  GeofenceStatus status;

  GeofenceMission({
    required this.id,
    required this.title,
    this.description,
    required this.center,
    this.radiusMeters = 50.0,
    this.type = MissionType.sanctuary,
    this.isActive = false,
    this.targetDistanceMeters,
    this.status = GeofenceStatus.unknown,
  });

  GeofenceMission copyWith({
    String? title,
    String? description,
    LatLngSimple? center,
    double? radiusMeters,
    MissionType? type,
    bool? isActive,
    double? targetDistanceMeters,
    GeofenceStatus? status,
  }) {
    return GeofenceMission(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      center: center ?? this.center,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      targetDistanceMeters: targetDistanceMeters ?? this.targetDistanceMeters,
      status: status ?? this.status,
    );
  }
}
