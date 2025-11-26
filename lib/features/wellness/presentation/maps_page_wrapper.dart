import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/geofence_repository.dart';
import '../domain/geofence_mission.dart';
import '../services/geofence_service.dart';
import 'maps_page.dart';
import '../services/notification_service.dart';

class MapsPageWrapper extends StatelessWidget {
  const MapsPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
      final GeofenceRepository repo = InMemoryGeofenceRepository();
    final service = GeofenceService(repository: repo);
    // Add a sample mission for demo purposes
    final sample = GeofenceMission(
      id: 'sample-1',
      title: 'Neighborhood Walk',
      description: 'A friendly walking target',
      center: LatLngSimple(37.4219999, -122.0840575),
      radiusMeters: 100,
      type: MissionType.target,
      targetDistanceMeters: 500,
    );
    // fire-and-forget add
    repo.add(sample);
      // Initialize notifications (fire-and-forget)
      NotificationService.init();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider.value(value: service),
      ],
      child: const WellnessMapsPage(),
    );
  }
}

// How to use:
// - Add `MapsPageWrapper()` to your application's routing for `wellness` category.
// - Ensure google_maps_flutter has been configured with platform API keys.
// - Optionally, replace `InMemoryGeofenceRepository` with a persisted implementation.
