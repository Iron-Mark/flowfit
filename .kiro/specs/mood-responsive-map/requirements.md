# Mood-Responsive Map Page - Functional Specification

## 1. Executive Summary

### 1.1 Goal
Create a dedicated "Wellness Tracker" page that processes real-time smartwatch data (Heart Rate + Accelerometer) to detect the user's current wellness state and automatically respond with contextual UI changes and map-based recommendations.

### 1.2 Key Differentiator
Unlike the existing Mission page (which is location-based gamification), this new page acts as a **background wellness monitor** that:
- Continuously analyzes biometric + motion data
- Detects stress vs. active exercise vs. calm states
- Automatically triggers UI/map responses without user intervention
- Provides proactive wellness recommendations

---

## 2. Data Inputs

### 2.1 Heart Rate (BPM)
**Source**: Samsung Galaxy Watch via `WatchBridgeService`
- **Stream**: `watchBridge.heartRateStream`
- **Data Model**: `HeartRateData`
  ```dart
  {
    bpm: int,              // Beats per minute
    ibiValues: List<int>,  // Inter-beat intervals (ms)
    timestamp: DateTime,
    status: SensorStatus   // active, inactive, error
  }
  ```
- **Sampling Rate**: Real-time stream (approximately every 1-2 seconds when active)
- **Range**: 40-220 BPM (typical human range)

### 2.2 Accelerometer (Motion Data)
**Source**: Samsung Galaxy Watch via `PhoneDataListener`
- **Stream**: `phoneListener.sensorBatchStream`
- **Data Model**: `SensorBatch`
  ```dart
  {
    samples: List<List<double>>,  // Each sample: [accX, accY, accZ, bpm]
    timestamp: DateTime
  }
  ```
- **Sampling Rate**: ~32Hz (32 samples per second)
- **Window Size**: 320 samples (10 seconds of data)
- **Motion Detection**: Calculate magnitude of acceleration vector to determine activity level

---

## 3. State Detection Logic ("The Brain")

### 3.1 State Classification System

The system SHALL implement a background service that continuously analyzes inputs to determine one of three wellness states:

#### State A: STRESS/ANXIETY
**Condition Logic**:
```
IF (Heart Rate > 100 BPM) AND (Accelerometer Activity < LOW_THRESHOLD)
THEN State = STRESS
```

**Detailed Criteria**:
- Heart Rate: > 100 BPM sustained for at least 30 seconds
- Accelerometer: Movement magnitude < 0.5 m/s² (essentially stationary/sitting)
- Duration: Must persist for 30+ seconds to avoid false positives
- Exclusion: If user was recently in CARDIO state (within 5 minutes), delay stress detection

**Rationale**: High heart rate while stationary indicates stress/anxiety, not exercise.

---

#### State B: CARDIO/ACTIVE
**Condition Logic**:
```
IF (Heart Rate > 100 BPM) AND (Accelerometer Activity > HIGH_THRESHOLD)
THEN State = CARDIO
```

**Detailed Criteria**:
- Heart Rate: > 100 BPM
- Accelerometer: Movement magnitude > 2.0 m/s² (active movement/running)
- Duration: Immediate detection (no delay needed)
- Confidence: High confidence when both signals align

**Rationale**: High heart rate with high movement indicates intentional exercise.

---

#### State C: CALM
**Condition Logic**:
```
IF (Heart Rate < 90 BPM)
THEN State = CALM
```

**Detailed Criteria**:
- Heart Rate: < 90 BPM
- Accelerometer: Any level (not used for calm detection)
- Duration: Immediate detection
- Default State: System defaults to CALM when no other conditions met

**Rationale**: Normal resting heart rate indicates relaxed state.

---

### 3.2 State Transition Rules

**Hysteresis Implementation**:
To prevent rapid state flickering, implement the following transition delays:

| From State | To State | Required Duration | Reason |
|------------|----------|-------------------|---------|
| CALM | STRESS | 30 seconds | Avoid false stress alerts |
| CALM | CARDIO | Immediate | Quick response to exercise |
| CARDIO | STRESS | 5 minutes | Allow cooldown period |
| CARDIO | CALM | 2 minutes | Gradual heart rate recovery |
| STRESS | CALM | 1 minute | Confirm stress relief |
| STRESS | CARDIO | Immediate | User started moving |

**State Priority**:
1. CARDIO (highest priority - clear exercise signal)
2. STRESS (medium priority - requires intervention)
3. CALM (default/fallback state)

---

### 3.3 Background Service Architecture

**Service Name**: `WellnessStateService`

**Responsibilities**:
1. Subscribe to heart rate and accelerometer streams
2. Maintain a rolling 10-second window of sensor data
3. Calculate motion magnitude from accelerometer data
4. Apply state detection logic with hysteresis
5. Emit state change events via `StateNotifier` or `StreamController`
6. Persist state history for analytics

**Lifecycle**:
- **Start**: When Wellness Tracker page is opened OR when user enables background monitoring
- **Stop**: When user explicitly disables OR app is terminated
- **Persistence**: Service should survive page navigation (run in background)

**Data Processing Pipeline**:
```
Watch Sensors → WatchBridgeService → WellnessStateService → State Detection → UI Update
                                    ↓
                              SensorBatch Buffer (10s window)
                                    ↓
                              Motion Magnitude Calculation
                                    ↓
                              State Classification Logic
                                    ↓
                              Hysteresis Filter
                                    ↓
                              State Change Event
```

---

## 4. UI & Map Behavior ("The Response")

### 4.1 State A (STRESS) - Automatic Response

When STRESS state is detected, the system SHALL automatically trigger:

#### 4.1.1 Notification Alert
**Type**: Non-intrusive in-app banner (NOT system notification)
- **Position**: Top of screen, slides down smoothly
- **Duration**: Persistent until user dismisses or state changes
- **Message**: "High stress levels detected. Recommendation: Take a walk to clear your mind."
- **Icon**: Calming icon (e.g., meditation symbol, leaf)
- **Color**: Soft amber/orange (attention without alarm)
- **Actions**:
  - "Show Routes" button → Triggers map update
  - "Dismiss" button → Hides banner but keeps state active
  - "Not Now" button → Snoozes for 30 minutes

#### 4.1.2 Map Update - Calming Route Suggestions
**Automatic Behavior**:
1. **Map Context Switch**: Map automatically pans to user's current location
2. **Route Overlay**: Display 2-3 suggested walking routes:
   - **Short Route** (10-15 min walk, ~1km)
   - **Medium Route** (20-30 min walk, ~2km)
   - **Long Route** (30-45 min walk, ~3km)
3. **Route Characteristics**:
   - Prioritize routes through parks, green spaces, waterfronts
   - Avoid busy streets, highways, industrial areas
   - Circular routes (return to starting point)
   - Well-lit paths (if evening/night)
4. **Visual Styling**:
   - Route lines: Soft green/blue gradient
   - Waypoint markers: Nature icons (trees, benches, water)
   - Highlight nearby parks with green overlay

**Map Data Source**:
- **Primary**: OpenRouteService API (already integrated)
- **POI Data**: Query for nearby parks, gardens, trails
- **Route Generation**: Use pedestrian profile with "green" preference

#### 4.1.3 Visual Feedback - Mood Enhancement Mode
**UI Theme Changes**:
1. **Color Palette Shift**:
   - Primary color → Calming blue (#4A90E2)
   - Background → Soft green tint (#F0F8F5)
   - Accent → Muted teal (#5DADE2)
2. **Animation**:
   - Smooth 1-second transition to new colors
   - Subtle breathing animation on stress indicator
3. **Typography**:
   - Slightly larger, more readable fonts
   - Increased line spacing for calmness
4. **Icons**:
   - Replace sharp icons with rounded variants
   - Add nature-themed decorative elements

**Persistent Indicators**:
- **Status Badge**: "Wellness Mode Active" in top-right corner
- **Heart Rate Display**: Show current BPM with calming pulse animation
- **Stress Timer**: "Detected 5 minutes ago" to track duration

---

### 4.2 State B (CARDIO) - Active Exercise Mode

When CARDIO state is detected:

#### 4.2.1 UI Response
- **Banner**: "Exercise detected! Keep it up! 💪"
- **Color Theme**: Energetic orange/red (#FF6B35)
- **Map Behavior**: Show current route being traveled
- **Metrics Display**: Show real-time pace, distance, calories
- **No Intervention**: System does NOT interrupt workout

#### 4.2.2 Integration with Existing Workout Tracking
- **Auto-Link**: If user is NOT in an active workout session, prompt:
  - "Start tracking this workout?"
  - Quick-start buttons for Run/Walk/Cycle
- **Seamless Transition**: If user accepts, navigate to existing workout tracker
- **Data Continuity**: Pass detected activity type and start time

---

### 4.3 State C (CALM) - Standard View

When CALM state is active:

#### 4.3.1 UI Response
- **Default Theme**: Standard app colors
- **Map View**: Normal mission/exploration view
- **No Alerts**: No proactive notifications
- **Status Display**: "Wellness: Calm ✓" in subtle text

#### 4.3.2 Historical Insights
- **Daily Summary**: "You've been calm for 6 hours today"
- **Stress Patterns**: "Stress typically occurs at 3 PM"
- **Recommendations**: "Consider a walk at 3 PM tomorrow"

---

## 5. Page Structure & Navigation

### 5.1 New Page: "Wellness Tracker"

**Page Name**: `WellnessTrackerPage` (or `MoodResponsiveMapPage`)
**Route**: `/wellness-tracker`

**Access Point**: 
- **Primary**: New button in Track Tab (as requested)
- **Secondary**: Bottom navigation bar (optional)
- **Quick Access**: Widget on dashboard (future enhancement)

**Layout Structure**:
```
┌─────────────────────────────────────┐
│  [Back] Wellness Tracker    [•••]   │  ← Header
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Current State: CALM ✓      │   │  ← State Card
│  │  Heart Rate: 72 BPM         │   │
│  │  Activity: Low              │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │      MAP VIEW               │   │  ← Interactive Map
│  │   (OpenRouteService)        │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Stress Alert Banner - if active]  │  ← Conditional Alert
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Today's Wellness Summary   │   │  ← Stats Section
│  │  Calm: 5h 30m               │   │
│  │  Active: 1h 15m             │   │
│  │  Stress: 20m                │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

### 5.2 Track Tab Integration

**Modification Required**: Update Track Tab to add new button

**Button Placement**: In the "CTA Section - Ready to move?" area

**New Button Specification**:
- **Label**: "Wellness Tracker" or "Mood Monitor"
- **Icon**: Heart with pulse line icon
- **Style**: Secondary outlined button (same as "Map Missions")
- **Position**: After "Map Missions" button
- **Action**: Navigate to `/wellness-tracker`

**Updated Button Order**:
1. Start a Workout (Primary)
2. Log a Run (Secondary)
3. Record a Walk (Secondary)
4. Map Missions (Secondary)
5. **Wellness Tracker** (Secondary) ← NEW

---

## 6. Technical Architecture

### 6.1 Data Flow Diagram

```
┌──────────────────┐
│  Galaxy Watch    │
│  - Heart Rate    │
│  - Accelerometer │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────┐
│  WatchBridgeService      │
│  - heartRateStream       │
│  - PhoneDataListener     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  WellnessStateService    │
│  - Buffer sensor data    │
│  - Calculate motion      │
│  - Detect state          │
│  - Apply hysteresis      │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  WellnessStateNotifier   │
│  (Riverpod StateNotifier)│
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  WellnessTrackerPage     │
│  - Listen to state       │
│  - Update UI/Map         │
│  - Show notifications    │
└──────────────────────────┘
```

---

### 6.2 Key Components

#### 6.2.1 WellnessStateService
**File**: `lib/services/wellness_state_service.dart`

**Responsibilities**:
- Subscribe to `WatchBridgeService.heartRateStream`
- Subscribe to `PhoneDataListener.sensorBatchStream`
- Maintain 10-second rolling buffer of sensor data
- Calculate motion magnitude from accelerometer
- Implement state detection logic
- Emit state changes via `StreamController<WellnessState>`

**Public API**:
```dart
class WellnessStateService {
  Stream<WellnessState> get stateStream;
  WellnessState get currentState;
  
  Future<void> startMonitoring();
  Future<void> stopMonitoring();
  
  // For testing/debugging
  void setMockState(WellnessState state);
}

enum WellnessState {
  calm,
  stress,
  cardio,
  unknown
}
```

---

#### 6.2.2 WellnessStateNotifier
**File**: `lib/providers/wellness_state_provider.dart`

**Responsibilities**:
- Wrap `WellnessStateService` in Riverpod provider
- Expose current state to UI
- Manage service lifecycle
- Persist state history

**Provider Definition**:
```dart
final wellnessStateProvider = StateNotifierProvider<WellnessStateNotifier, WellnessState>((ref) {
  return WellnessStateNotifier(ref.read(wellnessStateServiceProvider));
});
```

---

#### 6.2.3 WellnessTrackerPage
**File**: `lib/screens/wellness/wellness_tracker_page.dart`

**Responsibilities**:
- Display current wellness state
- Render interactive map
- Show stress alerts when needed
- Display wellness statistics
- Handle user interactions

**State Management**:
```dart
class WellnessTrackerPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wellnessState = ref.watch(wellnessStateProvider);
    
    // React to state changes
    ref.listen(wellnessStateProvider, (previous, next) {
      if (next == WellnessState.stress) {
        _showStressAlert(context);
        _updateMapForStress();
      }
    });
    
    return Scaffold(...);
  }
}
```

---

#### 6.2.4 Map Component Integration
**File**: `lib/widgets/wellness_map_widget.dart`

**Responsibilities**:
- Render OpenRouteService map
- Display calming route suggestions
- Highlight nearby parks/green spaces
- Handle map interactions

**Map Behavior**:
```dart
class WellnessMapWidget extends StatefulWidget {
  final WellnessState currentState;
  final LatLng userLocation;
  
  @override
  Widget build(BuildContext context) {
    if (currentState == WellnessState.stress) {
      return _buildStressMap();  // Show calming routes
    } else if (currentState == WellnessState.cardio) {
      return _buildCardioMap();  // Show current route
    } else {
      return _buildDefaultMap(); // Standard view
    }
  }
}
```

---

### 6.3 Route Generation Logic

**Service**: `CalmingRouteService`
**File**: `lib/services/calming_route_service.dart`

**Algorithm**:
1. Get user's current location
2. Query OpenRouteService for nearby POIs:
   - Parks (leisure=park)
   - Gardens (leisure=garden)
   - Waterfront (natural=water)
   - Trails (highway=path)
3. Generate 3 circular routes of varying lengths
4. Score routes based on:
   - Green space coverage (40% weight)
   - Low traffic (30% weight)
   - Safety/lighting (20% weight)
   - Scenic value (10% weight)
5. Return top 3 routes

**API Integration**:
```dart
class CalmingRouteService {
  Future<List<WalkingRoute>> generateCalmingRoutes(LatLng location) async {
    // 1. Find nearby parks
    final parks = await _findNearbyParks(location);
    
    // 2. Generate routes through parks
    final routes = await _generateRoutesViaParks(location, parks);
    
    // 3. Score and rank routes
    final rankedRoutes = _rankRoutesByCalmnessScore(routes);
    
    return rankedRoutes.take(3).toList();
  }
}
```

---

## 7. Integration with Existing Features

### 7.1 Reuse Existing Components

**From Activity Classifier (tracker_page.dart)**:
- ✅ Heart rate stream subscription logic
- ✅ Accelerometer data buffering (320-sample window)
- ✅ Motion magnitude calculation
- ✅ Sensor source selection (Watch/Phone/Simulation)

**From Mission Page (mission_bottom_sheet.dart)**:
- ✅ Map rendering with flutter_map
- ✅ Location marker system
- ✅ Bottom sheet UI pattern
- ✅ Mission list display

**From Workout Tracking (workout_session_service.dart)**:
- ✅ GPS tracking service
- ✅ Real-time metrics display
- ✅ Session persistence to Supabase

---

### 7.2 Differences from Mission Page

| Feature | Mission Page | Wellness Tracker Page |
|---------|--------------|----------------------|
| **Purpose** | Location-based gamification | Biometric wellness monitoring |
| **Trigger** | User creates missions manually | Automatic state detection |
| **Map Focus** | Mission markers & geofences | Calming routes & green spaces |
| **Interaction** | User-initiated actions | System-initiated recommendations |
| **Data Source** | GPS location only | Heart rate + accelerometer |
| **Persistence** | Missions saved to database | State history logged |

---

### 7.3 Differences from Activity Tracker

| Feature | Activity Tracker | Wellness Tracker |
|---------|------------------|------------------|
| **Purpose** | Activity classification (ML model) | Wellness state detection (rule-based) |
| **Output** | Stress/Cardio/Strength probabilities | Calm/Stress/Cardio state |
| **UI Focus** | Debug view with sliders | Production-ready wellness UI |
| **Map** | No map integration | Central map component |
| **Recommendations** | None | Proactive calming routes |

---

## 8. User Experience Flow

### 8.1 First-Time User Flow

1. **Discovery**: User taps "Wellness Tracker" button in Track Tab
2. **Onboarding**: Brief explanation screen:
   - "We'll monitor your heart rate and movement"
   - "Get personalized wellness recommendations"
   - "Your data stays private on your device"
3. **Permission Check**: Verify body sensor permission
4. **Watch Connection**: Ensure watch is connected
5. **Initial State**: Show CALM state with default map view
6. **Background Monitoring**: Service starts automatically

---

### 8.2 Stress Detection Flow

1. **Detection**: User is sitting at desk, heart rate rises to 110 BPM
2. **Validation**: System waits 30 seconds to confirm sustained high HR
3. **State Change**: WellnessState changes from CALM → STRESS
4. **UI Update**: 
   - Banner slides down: "High stress detected..."
   - Map pans to user location
   - Calming routes appear on map
   - Color theme shifts to calming blue/green
5. **User Action Options**:
   - **Option A**: Tap "Show Routes" → Map zooms to route details
   - **Option B**: Tap "Start Walk" → Begin GPS tracking
   - **Option C**: Tap "Dismiss" → Banner hides, monitoring continues
   - **Option D**: Ignore → Banner persists, state remains STRESS

---

### 8.3 Exercise Detection Flow

1. **Detection**: User starts jogging, HR rises to 140 BPM, high movement
2. **Immediate State Change**: CALM → CARDIO (no delay)
3. **UI Update**:
   - Banner: "Exercise detected! 💪"
   - Map shows current route
   - Prompt: "Track this workout?"
4. **User Action**:
   - **Option A**: Tap "Track Workout" → Navigate to workout tracker
   - **Option B**: Tap "No Thanks" → Continue monitoring only

---

### 8.4 Recovery Flow

1. **Post-Exercise**: User finishes run, HR drops to 95 BPM
2. **Cooldown Period**: System waits 2 minutes before state change
3. **State Change**: CARDIO → CALM
4. **UI Update**:
   - Banner: "Great workout! You're back to calm."
   - Map returns to default view
   - Show workout summary (if tracked)

---

## 9. Data Privacy & Security

### 9.1 Data Storage
- **Local Only**: All biometric data processed on-device
- **No Cloud Sync**: Heart rate and accelerometer data NOT sent to servers
- **State History**: Only state changes (CALM/STRESS/CARDIO) logged locally
- **Opt-In Analytics**: User can choose to share anonymized state patterns

### 9.2 User Control
- **Toggle Monitoring**: User can enable/disable wellness monitoring
- **Notification Settings**: Control alert frequency and style
- **Data Deletion**: Clear all wellness history from settings
- **Transparency**: Show what data is collected and how it's used

---

## 10. Performance Requirements

### 10.1 Responsiveness
- **State Detection Latency**: < 2 seconds from sensor data to state change
- **UI Update Latency**: < 500ms from state change to UI update
- **Map Rendering**: < 1 second to load calming routes
- **Battery Impact**: < 5% additional battery drain per hour

### 10.2 Reliability
- **Sensor Connection**: Auto-reconnect if watch disconnects
- **Graceful Degradation**: If no watch data, show manual mood input
- **Error Handling**: Clear error messages for sensor failures
- **Offline Support**: Core functionality works without internet (except map tiles)

---

## 11. Testing Strategy

### 11.1 Unit Tests
- State detection logic with various HR/accel combinations
- Hysteresis filter behavior
- Motion magnitude calculation
- Route scoring algorithm

### 11.2 Integration Tests
- Watch data stream → State service → UI update flow
- Map route generation with OpenRouteService API
- State persistence and retrieval

### 11.3 Manual Testing Scenarios
- **Scenario 1**: Simulate stress (high HR, low movement)
- **Scenario 2**: Simulate exercise (high HR, high movement)
- **Scenario 3**: Rapid state transitions
- **Scenario 4**: Watch disconnection during monitoring
- **Scenario 5**: Background monitoring while app in background

---

## 12. Future Enhancements

### 12.1 Phase 2 Features
- **Breathing Exercises**: Guided breathing when stress detected
- **Meditation Integration**: Link to meditation app/content
- **Social Support**: "Call a friend" quick action
- **Stress Triggers**: ML-based pattern recognition
- **Wearable Haptics**: Gentle vibration on watch for stress alert

### 12.2 Phase 3 Features
- **Multi-User**: Compare wellness patterns with friends
- **Workplace Integration**: Team wellness dashboard
- **Insurance Integration**: Share wellness data for premium discounts
- **Voice Assistant**: "Hey FlowFit, how's my stress today?"

---

## 13. Success Metrics

### 13.1 Engagement Metrics
- **Daily Active Users**: % of users who open Wellness Tracker daily
- **Stress Alerts**: Average number of stress detections per user per day
- **Route Acceptance**: % of users who follow suggested calming routes
- **Session Duration**: Average time spent on Wellness Tracker page

### 13.2 Wellness Outcomes
- **Stress Reduction**: Average time from stress detection to calm state
- **Proactive Walks**: % of stress alerts that lead to walking activity
- **User Satisfaction**: NPS score for wellness feature
- **Retention**: % of users still using feature after 30 days

---

## 14. Implementation Priority

### 14.1 MVP (Minimum Viable Product)
**Timeline**: 2-3 weeks

**Must-Have Features**:
1. ✅ Basic state detection (CALM/STRESS/CARDIO)
2. ✅ Heart rate + accelerometer integration
3. ✅ Simple stress alert banner
4. ✅ Map with calming route suggestions
5. ✅ Track Tab button integration

**Deferred**:
- Advanced hysteresis tuning
- Detailed wellness analytics
- Breathing exercises
- Social features

---

### 14.2 Phase 1 Enhancements
**Timeline**: 1-2 weeks after MVP

**Features**:
1. Color theme transitions
2. Wellness history/statistics
3. Customizable alert thresholds
4. Improved route scoring algorithm
5. Background monitoring optimization

---

### 14.3 Phase 2 Enhancements
**Timeline**: 1-2 months after MVP

**Features**:
1. Breathing exercise integration
2. Stress pattern analytics
3. Personalized recommendations
4. Integration with workout tracker
5. Wearable haptic feedback

---

## 15. Open Questions & Decisions Needed

### 15.1 Design Decisions
- [ ] Should stress alerts be dismissible or persistent?
- [ ] Should we show heart rate number prominently or hide it?
- [ ] What's the ideal map zoom level for route suggestions?
- [ ] Should we use system notifications or only in-app alerts?

### 15.2 Technical Decisions
- [ ] Should wellness monitoring run as a foreground service?
- [ ] How long should we retain state history (7 days? 30 days?)?
- [ ] Should we cache map tiles for offline use?
- [ ] What's the fallback if OpenRouteService API is down?

### 15.3 Product Decisions
- [ ] Should this feature be free or premium?
- [ ] Should we require watch connection or allow phone-only mode?
- [ ] Should we integrate with Apple Watch (future)?
- [ ] Should we partner with mental health apps?

---

## 16. Appendix

### 16.1 Related Existing Files
- `lib/features/activity_classifier/presentation/tracker_page.dart` - Activity classification logic
- `lib/features/wellness/presentation/widgets/mission_bottom_sheet.dart` - Map UI patterns
- `lib/services/watch_bridge.dart` - Watch data integration
- `lib/services/phone_data_listener.dart` - Sensor batch processing
- `docs/TRACK_TAB_USAGE.md` - Track Tab documentation

### 16.2 New Files to Create
- `lib/services/wellness_state_service.dart`
- `lib/providers/wellness_state_provider.dart`
- `lib/screens/wellness/wellness_tracker_page.dart`
- `lib/widgets/wellness_map_widget.dart`
- `lib/services/calming_route_service.dart`
- `lib/models/wellness_state.dart`
- `lib/models/walking_route.dart`

### 16.3 Files to Modify
- Track Tab screen (add new button)
- App router (add `/wellness-tracker` route)
- Main navigation (optional bottom nav item)

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-27  
**Status**: Draft - Ready for Review
