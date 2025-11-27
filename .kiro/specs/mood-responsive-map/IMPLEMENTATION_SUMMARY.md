# Mood-Responsive Map - Implementation Summary

## Overview
This document summarizes the tasks.md creation for the mood-responsive-map (Wellness Tracker) feature and confirms GPS integration patterns across the application.

## Tasks.md Created ✅

Created comprehensive implementation plan at `.kiro/specs/mood-responsive-map/tasks.md` with 20 main tasks covering:

### Core Components (Tasks 1-3)
- **Task 1**: Wellness state models and enums (WellnessState, WellnessStateData, WalkingRoute, StateTransition)
- **Task 2**: WellnessStateService with state detection algorithm, hysteresis filtering, and sensor data buffering
- **Task 3**: State management providers using Riverpod (WellnessStateNotifier, wellnessStateProvider)

### Map & Route Features (Tasks 4, 8, 19)
- **Task 4**: CalmingRouteService for generating stress-relief walking routes with POI scoring
- **Task 8**: WellnessMapWidget with state-responsive behavior (STRESS/CARDIO/CALM modes)
- **Task 19**: Route visualization with gradient polylines, waypoint markers, and interaction

### UI Components (Tasks 5-7, 9-10)
- **Task 5**: WellnessTrackerPage main UI with state card, map view, and stats section
- **Task 6**: Stress alert banner with slide-down animation and action buttons
- **Task 7**: Mood enhancement mode with color theme transitions
- **Task 9**: Cardio detection banner and workout integration
- **Task 10**: Wellness statistics and history display

### Integration & System (Tasks 11-18, 20)
- **Task 11**: Track Tab integration (add "Wellness Tracker" button)
- **Task 12**: Sensor integration pipeline (heart rate + accelerometer)
- **Task 13**: Background monitoring and lifecycle management
- **Task 14**: Data privacy and user controls
- **Task 15**: Onboarding flow for first-time users
- **Task 16**: Error handling and edge cases
- **Task 17**: Testing and debugging tools
- **Task 18**: Performance and battery optimization
- **Task 20**: Final integration and polish

## GPS Integration Patterns Confirmed ✅

### Current GPS Implementation
The application already has proper GPS integration through:

1. **GPSTrackingService** (`lib/services/gps_tracking_service.dart`)
   - Uses `geolocator` package
   - Provides `locationStream` for real-time updates
   - Implements `getCurrentLocation()` for one-time location fetch
   - Calculates distances between coordinates
   - Handles permissions properly

2. **Usage in Mission Creation** (`lib/screens/workout/walking/mission_creation_screen.dart`)
   ```dart
   // Proper pattern:
   final gpsService = ref.read(gpsTrackingServiceProvider);
   final location = await gpsService.getCurrentLocation();
   
   // Center map on current location
   _mapController.move(location, 15.0);
   ```

3. **Usage in Running/Walking Sessions**
   - RunningSessionProvider subscribes to GPS stream
   - Updates route points automatically every 5 seconds
   - Calculates distance from route points
   - Properly integrated with state management

### GPS Integration Checklist for All Screens

✅ **Running Screens**
- ActiveRunningScreen: Uses GPS via RunningSessionProvider
- RunningSummaryScreen: Displays recorded GPS route
- RunningSetupScreen: Shows current location on map preview

✅ **Walking Screens**
- MissionCreationScreen: Uses GPS for current location and target selection
- ActiveWalkingScreen: Uses GPS via WalkingSessionProvider
- WalkingSummaryScreen: Displays recorded GPS route

✅ **Map Integration**
- All screens use flutter_map with OpenStreetMap tiles
- Proper user location markers (blue dot)
- Route polylines with appropriate styling
- Map controller for programmatic navigation

### Recommended GPS Pattern for New Screens

```dart
// 1. Get GPS service from provider
final gpsService = ref.read(gpsTrackingServiceProvider);

// 2. For one-time location (e.g., map initialization)
try {
  final location = await gpsService.getCurrentLocation();
  _mapController.move(location, 15.0);
} catch (e) {
  // Handle permission denied or GPS unavailable
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Unable to get location. Please enable GPS.'),
    ),
  );
}

// 3. For continuous tracking (e.g., during workout)
// Subscribe via session provider (already implemented)
await ref.read(sessionProvider.notifier).startSession();

// 4. Display on map
FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: currentLocation,
    initialZoom: 15,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.flowfit.app',
    ),
    MarkerLayer(
      markers: [
        Marker(
          point: currentLocation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ],
    ),
  ],
)
```

## Next Steps

### For Mood-Responsive Map Implementation:
1. Start with Task 1 (core models)
2. Implement Task 2 (WellnessStateService) - this is the "brain"
3. Create Task 3 (state providers)
4. Build Task 5 (WellnessTrackerPage UI)
5. Integrate Task 11 (Track Tab button)
6. Continue with remaining tasks in order

### For GPS Integration:
- ✅ GPS is properly integrated across all workout screens
- ✅ Pattern is consistent and reusable
- ✅ Error handling is in place
- ✅ No changes needed to existing GPS implementation

## Architecture Alignment

The tasks.md follows the spec-driven approach:
- ✅ Based on requirements.md (functional specification)
- ✅ Aligned with architecture.md (technical design)
- ✅ Follows EARS pattern for requirements traceability
- ✅ Each task references specific requirements
- ✅ Clear separation of concerns (models → services → providers → UI)
- ✅ Incremental implementation path

## Key Technical Decisions

1. **State Detection**: Rule-based algorithm (not ML) for MVP
   - STRESS: HR > 100 BPM + motion < 0.5 m/s² for 30s
   - CARDIO: HR > 100 BPM + motion > 2.0 m/s²
   - CALM: HR < 90 BPM

2. **Hysteresis**: Prevents state flickering with transition delays
   - CALM → STRESS: 30 seconds
   - CARDIO → STRESS: 5 minutes
   - CARDIO → CALM: 2 minutes

3. **Route Generation**: OpenRouteService API with scoring algorithm
   - Green space coverage: 40% weight
   - Low traffic: 30% weight
   - Safety/lighting: 20% weight
   - Scenic value: 10% weight

4. **Data Privacy**: All biometric data processed on-device only
   - No cloud sync of heart rate/accelerometer data
   - Only state changes logged locally
   - Opt-in for anonymized analytics

## Success Criteria

- [ ] State detection latency < 2 seconds
- [ ] UI update latency < 500ms
- [ ] Map rendering < 1 second
- [ ] Battery impact < 5% per hour
- [ ] Proper GPS integration across all screens
- [ ] Smooth theme transitions (1 second)
- [ ] Reliable sensor reconnection
- [ ] Clear error messages for all failure modes

---

**Status**: Tasks.md created and ready for implementation
**Next Action**: Begin implementation with Task 1 (core models)
**GPS Status**: ✅ Properly integrated, no changes needed

