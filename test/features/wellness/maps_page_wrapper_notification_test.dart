import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flowfit/features/wellness/presentation/maps_page_wrapper.dart';
import 'package:flowfit/features/wellness/presentation/maps_page.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:flowfit/features/wellness/services/geofence_service.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';
import 'package:flowfit/features/wellness/services/notification_service.dart';

void main() {
  testWidgets('MapsPageWrapper listens to notification taps and requests focus', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapsPageWrapper(autoStartMoodTracker: false)));

    // Get repository and service from the MultiProvider of the MapsPageWrapper
    final mapsFinder = find.byType(WellnessMapsPage);
    expect(mapsFinder, findsOneWidget);
    final repo = tester.element(mapsFinder).read<GeofenceRepository>();

    final mission = GeofenceMission(
      id: 'm1',
      title: 'Test M',
      center: LatLngSimple(0.0, 0.0),
      radiusMeters: 50,
    );
    await repo.add(mission);

    // Short pump to let widget build and listeners subscribe
    await tester.pump();
    await Future.delayed(const Duration(milliseconds: 50));

    final service = tester.element(mapsFinder).read<GeofenceService>();

    final events = <String>[];
    final sub = service.focusRequests.listen((id) => events.add(id));

    // Simulate notification tap
    NotificationService.debugSimulateTap('focus:m1');
    await tester.pump();
    await Future.delayed(const Duration(milliseconds: 50));

    expect(events.contains('m1'), true);

    await sub.cancel();
  });
}
