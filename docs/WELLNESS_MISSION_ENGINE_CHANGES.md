## Wellness Mission Engine (Maps/Geofence) - Change Log & Implementation Notes

Summary
-------
- Purpose: Implement a maps-based "Mission Engine" for three mission types: Target, Sanctuary, and Safety Net. Provides geofencing, simple mission lifecycle, local notifications, and a Google Maps-based UI.
- High-level design: Lightweight, feature-first clean architecture with domain, data, services, platform, and presentation layers; default to an in-memory repository for persistence; optional native background geofence scaffolding.

Files Added
-----------
- lib/features/wellness/domain/geofence_mission.dart
  - Domain model: GeofenceMission, types (MissionType), runtime status (GeofenceStatus), and JSON (de)serialization.

- lib/features/wellness/data/geofence_repository.dart
  - Abstract `GeofenceRepository` with an `InMemoryGeofenceRepository` implementation. Default in-memory store for demo/test usage and easy mocking.

- lib/features/wellness/services/geofence_service.dart
  - Monitors device Location using `geolocator` (or optional position stream override), detects enter/exit, SafetyNet outside alerts, Target accumulation, triggers local notifications, and emits `GeofenceEvent`s.
  - Exposes an `events` stream for UI or other feature integration.

- lib/features/wellness/platform/geofence_native.dart
  - Minimal method/event channel wrapper (MethodChannel + EventChannel) to register/unregister native geofences and receive native events where available.

- lib/features/wellness/services/notification_service.dart
  - Wrapper around `flutter_local_notifications` plugin with safe initialization and showNotification call used from the geofence service.

- lib/features/wellness/presentation/maps_page.dart
  - Google Map UI including marker rendering, mission list, mission add/edit flows, and event logging in the UI.

- lib/features/wellness/presentation/maps_page_wrapper.dart
  - Provider wiring for `InMemoryGeofenceRepository`, `GeofenceService`, and sample mission state for demo purposes.

- test/features/wellness/geofence_service_test.dart
  - Tests for basic behavior: target accumulation, safety net outside alert.

Files Removed
-------------
- lib/features/wellness/data/geofence_sql_repository.dart (removed)
- lib/features/wellness/data/geofence_supabase_repository.dart (removed)
  - Removal rationale: The user instructed the feature to be free of Supabase/SQL dependencies. The feature now uses an in-memory repository. Global (app-level) services referencing Supabase/SQL were left untouched by this change (that is a separate PR/cleanup scope).

Files Changed (Non-feature)
---------------------------
- android/app/build.gradle.kts
  - Enabled core library desugaring (isCoreLibraryDesugaringEnabled = true).
  - Added `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")` to the `dependencies {}` block.
  - Why: `flutter_local_notifications` (or other plugin) required usage of newer Java APIs and the AAR metadata check failed; enabling desugaring addresses the AAR metadata issue.

- native geofence plugin integration (non-feature change)
  - Created `lib/features/wellness/platform/native_geofence_wrapper.dart` as a wrapper to `native_geofence` plugin for Android & iOS usage.
  - Updated `lib/features/wellness/platform/geofence_native.dart` to prefer the plugin wrapper for registration/unregistration and capture plugin events as a fallback to the custom method channel bridge.

Other Observations & Repository Impact
-------------------------------------
- `pubspec.yaml` contains global dependencies `sqflite` and `supabase_flutter`. These packages were restored globally after a previous temporary removal; the wellness feature remains independent of Supabase/SQL (it uses `InMemoryGeofenceRepository`).
- The feature-level removal should not break existing code unless other features depend on the deleted repository files directly. The `InMemoryGeofenceRepository` is used by the `maps_page_wrapper` and tests.
- The `NotificationService` uses `flutter_local_notifications`, which required Android desugaring to compile correctly. The plugin was added to `pubspec.yaml` and may require platform setup (AndroidManifest, iOS entitlements) for full behavior.

Design & Runtime Notes
-----------------------
- Mission Type Behavior:
  - Target: accumulates distance while the mission is active. When the sum reaches the target distance, a targetReached event and optional local notification are issued; mission optionally deactivates itself.
  - Sanctuary: acts as a radius-based safe area; enter/leave events are emitted for the UI.
  - Safety Net: if device is outside the specified radius while active, an outsideAlert event is emitted and a local notification is sent (best-effort).

- Events: `GeofenceEvent` contains `missionId`, `type`, `position`, and an optional `value` (e.g., progress). `GeofenceEventType`s: entered, exited, targetReached, outsideAlert.

- Native Bridge: `GeofenceNative` is a minimal adapter; register/unregister method channel messages are handled on the Flutter side and forwarded to native code when available.

- JSON schema for `GeofenceMission` (fields used in code & serialization):
  - id: String
  - title: String
  - description: String | null
  - latitude: double
  - longitude: double
  - radius: double (meters)
  - type: String representing MissionType (target | sanctuary | safetyNet)
  - isActive: bool
  - targetDistance: double | null (meters; only for target missions)
  - status: String representing GeofenceStatus (unknown | inside | outside)

Testing & Running
-----------------
1) Run the feature's tests:
```powershell
flutter test test/features/wellness/geofence_service_test.dart
```

2) Run the app and open the Maps UI (if you have a Google Maps API key and proper platform setup):
```powershell
flutter pub get
flutter run -t lib/main.dart
```

3) Run the watch/wear app (watch-specific entrypoint):
```powershell
flutter run -d <watch-device-id> -t lib/main_wear.dart
```

Notes for future developers and LLM prompts
-----------------------------------------
- If you want to convert the `InMemoryGeofenceRepository` to a persisted repository:
  - Implement a repository using your persistence of choice (Supabase local mapping, sqlite via `sqflite`, or Hive). Map to/from `GeofenceMission` JSON.
  - Replace instantiation in `maps_page_wrapper.dart` with the persisted repository provider.
  - Persist the `isActive` flag and `status` if you want to resume state across restarts.
  - Continue to register active missions with `GeofenceNative.register` for background processing.

- Testing:
  - The test uses a `positionStreamOverride` to feed custom Position objects into the `GeofenceService`. Keep this pattern for deterministic unit testing.
  - Add tests for: `activateMission`, `deactivateMission`, `enter/exit behavior`, native event handling, and notifications (which may need mocking in tests).

- Platform notes:
  - Android: `isCoreLibraryDesugaringEnabled` and `coreLibraryDesugaring` dependency added to support `flutter_local_notifications` plugin AAR compatibility.
  - Native background geofence: Currently only a SCaffold (MethodChannel & EventChannel). Implement native logic in Android `MainActivity` / `HealthTrackingManager` or a background service to register geofence with the OS.
  - iOS: you may need `UserNotifications` permission logic and configure `DarwinInitializationSettings` in `notification_service.dart`.

Commit notes
------------
- Feature-level Supabase/SQL deletion commit (example):
  - "feat(wellness): remove feature-level supabase/sql repo files and use in-memory GeofenceRepository"
  - Result: `lib/features/wellness/data/geofence_sql_repository.dart` and `lib/features/wellness/data/geofence_supabase_repository.dart` removed.

- Android build fix for notifications (example):
  - "fix(android): enable core library desugaring for plugin compatibility"
  - Result: `isCoreLibraryDesugaringEnabled = true` and `coreLibraryDesugaring` dependency added to `android/app/build.gradle.kts`.

Potential Follow-up Tasks
-------------------------
1. If you want to remove all Supabase and SQL references across the repo, follow these steps:
  - Replace `SupabaseService`/`DatabaseService` usages with in-memory/no-op services. Update provider wiring and repository implementations to avoid global dependency removal regressions.
  - Remove `supabase_flutter` and `sqflite` from `pubspec.yaml` and run `flutter pub get`.
  - Update documentation and README files to reflect the removal.
  - Run `flutter analyze` and `flutter test` and fix failing tests.

2. Implement native background geofence registration/unregistration for Android/iOS for robust OS-level geofencing.

3. Consider a persisted, optional `GeofenceRepository` implementation (Hive or SQLite) to store missions and resume state after restarts.

4. Add UI tests or integration tests for map interactions and mission triggers.

-------------------------
End of wellness mission engine change log — use this doc to answer future LLM prompts or for onboarding new contributors.
