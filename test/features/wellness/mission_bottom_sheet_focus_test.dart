import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/wellness/presentation/maps_page_wrapper.dart';
import 'package:flowfit/features/wellness/presentation/maps_page.dart';
import 'package:flowfit/features/wellness/data/geofence_repository.dart';
import 'package:provider/provider.dart';
import 'package:flowfit/features/wellness/domain/geofence_mission.dart';

void main() {
  testWidgets('Pressing Focus & Navigate triggers FocusMissionOverlay', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapsPageWrapper(autoStartMoodTracker: false)));

    await tester.pump();
    await Future.delayed(const Duration(milliseconds: 50));

    final mapsFinder = find.byType(WellnessMapsPage);
    final repo = Provider.of<GeofenceRepository>(tester.element(mapsFinder), listen: false);

    final mission = GeofenceMission(id: 'm1', title: 'Test M', center: LatLngSimple(0.0, 0.0), radiusMeters: 50);
    await repo.add(mission);

    await tester.pump();
    await Future.delayed(const Duration(milliseconds: 50));

    // Tap the add button to ensure bottom sheet exists if not visible
    // (If there's already bottom sheet, this will no-op)
    final addFinder = find.widgetWithIcon(ElevatedButton, Icons.add);
    if (addFinder.evaluate().isNotEmpty) {
      await tester.tap(addFinder);
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Find the flag IconButton for the mission and tap it.
    final flagFinder = find.widgetWithIcon(IconButton, Icons.flag).first;
    expect(flagFinder, findsOneWidget);
    await tester.tap(flagFinder);
    await tester.pump();
    await Future.delayed(const Duration(milliseconds: 50));

    // Now the FocusMissionOverlay should be visible and contain the mission title.
    expect(find.text('Test M'), findsWidgets);
  });
}
