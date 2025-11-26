# Design Document - Unified Workout Flow

## Overview

The Unified Workout Flow redesigns FlowFit's Track Tab to eliminate decision paralysis by consolidating four separate workout entry points into a single, intelligent "START WORKOUT" button. The system guides users through a streamlined flow: quick mood check → workout type selection → specialized workout experience → post-workout mood check → summary with mood improvement display.

This design integrates mood tracking as a core motivational feature, showing users the emotional ROI of their workouts. Each workout type (Running, Walking, Resistance Training) receives a specialized UI optimized for its specific use case, while maintaining consistent design patterns and leveraging OpenRouteService for GPS visualization.

### Key Design Principles

1. **Simplicity First**: One button to start any workout
2. **Emotional Intelligence**: Mood tracking creates motivational feedback loops
3. **Specialized Experiences**: Each workout type has optimal UI/UX
4. **Visual Consistency**: Unified design system across all workout types
5. **Real-time Feedback**: Live metrics and GPS tracking during workouts
6. **Celebration of Progress**: Prominent mood improvement display in summaries

## Architecture

### High-Level Flow

```
Track Tab (Modified)
    ↓
[START WORKOUT] Button
    ↓
Pre-Workout Mood Check (Bottom Sheet)
    ↓
Workout Type Selection Screen
    ↓
    ├─→ Running Setup → Active Running → Post-Mood → Running Summary
    ├─→ Walking Options → Active Walking → Post-Mood → Walking Summary
    └─→ Split Selection → Active Resistance → Post-Mood → Resistance Summary
    ↓
Activity History (with mood badges)
```

### Layer Architecture

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, Bottom Sheets)      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         State Management Layer          │
│     (Riverpod Providers & Notifiers)    │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│          Service Layer                  │
│  (Workout, GPS, HR, Calorie Services)   │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│          Data Layer                     │
│    (Supabase, Local Storage, APIs)      │
└─────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Track Tab (Modified)

**Purpose**: Single entry point for all workouts with daily stats and activity history

**UI Components**:
- Daily Stats Section (existing - unchanged)
- Single "START WORKOUT" button (new - replaces 4 buttons)
- Recent Activity Section (enhanced with mood badges)

**State Dependencies**:
- `dailyStatsProvider` - Current day's fitness metrics
- `recentActivitiesProvider` - Recent workout sessions with mood data

**Navigation**:
- Tapping "START WORKOUT" → Opens `QuickMoodCheckBottomSheet`

### 2. Quick Mood Check (Bottom Sheet)

**Purpose**: Capture pre-workout emotional state in <10 seconds

**UI Components**:
- Heading: "How are you feeling?" (titleLarge)
- 5 emoji buttons in horizontal row:
  - 😢 Very Bad (value: 1)
  - 😕 Bad (value: 2)
  - 😐 Neutral (value: 3)
  - 🙂 Good (value: 4)
  - 💪 Energized (value: 5)
- Auto-dismiss timer (10 seconds → defaults to neutral)

**Interface**:
```dart
class QuickMoodCheckBottomSheet extends StatelessWidget {
  final Function(MoodRating) onMoodSelected;
  
  // Displays 5 emoji buttons
  // Auto-dismisses after 10s with neutral default
  // Calls onMoodSelected with user's choice
}
```

**Behavior**:
- Appears with slide-up animation
- Emoji buttons have 56x56 dp touch targets
- Selected emoji scales up briefly before dismissing
- On selection: stores mood and navigates to workout type selection

### 3. Workout Type Selection Screen

**Purpose**: Choose between Running, Walking, or Resistance Training

**UI Components**:
- Header: "Choose Your Workout" (headlineMedium)
- Three large cards (full-width, 24px spacing):
  - Running Card (blue gradient)
  - Walking Card (green gradient)
  - Resistance Card (red gradient)
- Each card shows: Icon, Name, Est. Duration, Est. Calories, Benefits

**Card Design**:
```dart
class WorkoutTypeCard extends StatelessWidget {
  final WorkoutType type;
  final VoidCallback onTap;
  
  // Gradient background based on type
  // Solar Icon at top
  // Type name in titleLarge
  // Metrics row: "45-60 min • 400 cal"
  // Benefits text in bodyMedium
}
```

**Navigation**:
- Running → `RunningSetupScreen`
- Walking → `WalkingOptionsScreen`
- Resistance → `SplitSelectionScreen`

### 4. Running Setup Screen

**Purpose**: Configure run parameters before starting

**UI Components**:
- Goal Type Toggle: Distance / Duration
- Conditional Slider:
  - Distance: 1-20 km (0.5 km steps)
  - Duration: 5-120 min (5 min steps)
- Map Preview (OpenRouteService) showing current location
- Quick Stats Cards: Est. Pace, Est. Calories, Target HR
- "Start Running" button (primary, full-width)

**State Management**:
```dart
class RunningSetupNotifier extends StateNotifier<RunningSetupState> {
  void setGoalType(GoalType type);
  void setTargetDistance(double km);
  void setTargetDuration(int minutes);
  Future<void> startRunning();
}
```

**Data Flow**:
1. User adjusts sliders → State updates
2. Quick stats recalculate based on user profile
3. "Start Running" tapped → Creates `WorkoutSession` with pre-mood
4. Navigates to `ActiveRunningScreen` with session ID

### 5. Active Running Screen

**Purpose**: Real-time tracking with prominent metrics and GPS visualization

**UI Layout**:
```
┌─────────────────────────────────────────┐
│  Status Badge    Timer: 00:00    ⏸ ⏹   │ Header
├─────────────────────────────────────────┤
│                                         │
│           3.24 km                       │ Primary Metric
│         (headlineLarge)                 │
│                                         │
├─────────────────────────────────────────┤
│  Duration    │    Pace                  │
│   25:30      │  7:52 /km                │ Secondary
│──────────────┼──────────────────────────│ Metrics Grid
│  Heart Rate  │  Calories                │
│    142 bpm   │    180 cal               │
├─────────────────────────────────────────┤
│  ▓▓▓▓▓▓▓▓▓░░░░░░░░░░  65%              │ Progress Bar
├─────────────────────────────────────────┤
│                                         │
│        [OpenRouteService Map]           │ Live Map
│        with route polyline              │
│                                         │
└─────────────────────────────────────────┘
```

**Real-time Updates**:
- Timer: Updates every 1 second
- Distance: Updates every 1 second (from GPS)
- Pace: Calculated from distance/time
- Heart Rate: Updates every 1 second (if available)
- GPS: Records coordinates every 5 seconds
- Map: Redraws route polyline every 5 seconds

**State Management**:
```dart
class RunningSessionNotifier extends StateNotifier<RunningSession> {
  final GPSTrackingService _gpsService;
  final HeartRateService _hrService;
  Timer? _updateTimer;
  
  void startSession();
  void pauseSession();
  void resumeSession();
  Future<void> endSession();
  
  // Updates metrics every second
  void _updateMetrics();
}
```

**Controls**:
- Pause Button: Stops timer and GPS, maintains state
- Resume Button: Continues from paused state
- End Button: Shows confirmation dialog → Post-workout mood check

### 6. Walking Options Screen

**Purpose**: Choose between casual walk or mission-based walk

**UI Components**:
- Two large option cards:
  
  **Free Walk Card**:
  - Icon: Walking person (Solar)
  - Title: "Free Walk"
  - Duration slider: 10-120 min
  - Description: "Casual walk with GPS tracking"
  - Button: "Start Free Walk"
  
  **Map Mission Card** (with "NEW" badge):
  - Icon: Map marker (Solar)
  - Title: "Map Mission"
  - Mission type selector: Target / Sanctuary / Safety Net
  - Description: "Walk to a specific location"
  - Button: "Create Mission"

**Mission Types**:
- **Target**: Walk X meters from starting point
- **Sanctuary**: Reach a specific GPS coordinate
- **Safety Net**: Stay within radius (elder care use case)

**Navigation**:
- Free Walk → `ActiveWalkingScreen` (simple mode)
- Map Mission → `MissionCreationScreen` → `ActiveWalkingScreen` (mission mode)

### 7. Active Walking Screen

**Purpose**: Real-time walking tracking with map integration

**UI Layout**:
```
┌─────────────────────────────────────────┐
│  Timer: 00:00              ⏸ ⏹         │ Header (10%)
├─────────────────────────────────────────┤
│                                         │
│                                         │
│      [OpenRouteService Map]             │
│       • Current location (blue dot)     │ Map (40%)
│       • Route polyline                  │
│       • Mission marker (if active)      │
│       • Distance overlay card           │
│                                         │
├─────────────────────────────────────────┤
│  Duration    │    Distance              │
│   18:24      │    1.2 km                │
│──────────────┼──────────────────────────│ Stats Grid
│    Steps     │   Calories               │ (50%)
│    2,450     │    95 cal                │
├─────────────────────────────────────────┤
│  💪 Remember: You started feeling 😐    │ Mood Reminder
└─────────────────────────────────────────┘
```

**Mission Mode Additions**:
- Distance to target overlay on map
- Progress bar showing % to destination
- Auto-completion when within 50m of target
- Celebration animation on mission complete

**State Management**:
```dart
class WalkingSessionNotifier extends StateNotifier<WalkingSession> {
  final GPSTrackingService _gpsService;
  Mission? _activeMission;
  
  void startSession({Mission? mission});
  void updateLocation(LatLng location);
  bool checkMissionCompletion();
  Future<void> endSession();
}
```

### 8. Split Selection Screen (Resistance Training)

**Purpose**: Choose upper or lower body workout split

**UI Components**:
- Two large split cards:
  
  **Upper Body Card** (blue gradient):
  - Icon: 💪 (flexed bicep)
  - Title: "Upper Body"
  - Focus: Chest, Back, Shoulders, Arms
  - 6 exercises listed
  - Est: 45-60 min, 400 cal
  
  **Lower Body Card** (purple gradient):
  - Icon: 🦵 (leg)
  - Title: "Lower Body"
  - Focus: Quads, Hamstrings, Glutes, Calves
  - 6 exercises listed
  - Est: 50-70 min, 500 cal

**Expandable Exercise List**:
When split selected, card expands to show:
- Exercise name with emoji icon
- Sets × Reps (e.g., "3 × 12")
- Rest time (e.g., "90s rest")

**Workout Settings Panel**:
- Rest Timer: 60s / 90s / 120s (segmented control)
- Audio Cues: Toggle switch
- HR Monitor: Toggle switch
- Pro Tip callout: "Start with lighter weight to perfect form"

**Navigation**:
- "Start Workout" → `ActiveResistanceScreen` with exercise queue

### 9. Active Resistance Screen

**Purpose**: Guide through exercises with set tracking and rest timers

**UI Layout - Active Exercise State**:
```
┌─────────────────────────────────────────┐
│  Exercise 2/6        Timer: 12:34       │ Header
├─────────────────────────────────────────┤
│  ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░  33%             │ Progress Bar
├─────────────────────────────────────────┤
│  HR: 128 bpm  │  Calories: 145          │ Quick Stats
├─────────────────────────────────────────┤
│                                         │
│              💪                         │
│         Bench Press                     │ Current
│                                         │ Exercise
│         Set 2 of 3                      │ Card
│          12 reps                        │
│                                         │
│         ● ● ○                           │ Set Progress
│                                         │
│      [  Skip Set  ] [ Complete ✓ ]     │ Actions
│                                         │
├─────────────────────────────────────────┤
│  Next Up:                               │
│  🏋️ Incline Press  3×10                 │ Exercise
│  💪 Shoulder Press  3×12                │ Queue
│  🔥 Lateral Raises  3×15                │
└─────────────────────────────────────────┘
```

**UI Layout - Rest State**:
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│              01:30                      │
│         (circular countdown)            │ Rest Timer
│                                         │
│           Rest Time                     │
│                                         │
│   Get ready for set 3 of Bench Press   │
│                                         │
│         [  Skip Rest  ]                 │
│                                         │
└─────────────────────────────────────────┘
```

**State Management**:
```dart
class ResistanceSessionNotifier extends StateNotifier<ResistanceSession> {
  List<Exercise> _exercises;
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  Timer? _restTimer;
  
  void completeSet();
  void skipSet();
  void startRestTimer();
  void skipRest();
  void advanceToNextExercise();
  Future<void> endWorkout();
}
```

**Exercise Progression**:
1. Display exercise with set/rep target
2. User completes set → Taps "Complete"
3. System starts rest timer (60/90/120s based on settings)
4. Rest timer counts down with large display
5. Timer completes → Audio cue (if enabled) → Next set
6. All sets complete → Auto-advance to next exercise
7. All exercises complete → Post-workout mood check

### 10. Post-Workout Mood Check

**Purpose**: Capture post-workout emotional state

**UI Components**:
- Same as pre-workout mood check
- Heading: "How do you feel now?" (titleLarge)
- 5 emoji buttons (same scale)
- Auto-select after 15s (defaults to pre-workout mood)

**Behavior**:
- Calculates mood change: `post - pre`
- Stores both values in workout session
- Navigates to workout-specific summary screen

### 11. Workout Summary Screens

**Purpose**: Celebrate achievement and show mood improvement

**Common Elements** (all workout types):

**Mood Transformation Card** (top, gradient background):
```
┌─────────────────────────────────────────┐
│   Mood Transformation 🚀                │
│                                         │
│   😐 Neutral → 💪 Energized             │
│   +2 points improvement!                │
└─────────────────────────────────────────┘
```

**Running Summary Specific**:
- Primary Metrics: Distance (large), Duration (large)
- Secondary Grid: Avg Pace, Avg HR, Calories
- Route Map: Full recorded path on OpenRouteService
- Heart Rate Zones: Bar chart showing time in each zone
- Action Buttons: "Save to History", "Share Achievement"

**Walking Summary Specific**:
- Primary Metrics: Distance, Duration, Steps
- Mission Completion Badge (if applicable)
- Route Map with mission markers
- Calories and avg pace
- Option: "Create Next Mission"

**Resistance Summary Specific**:
- Primary Metrics: Total Duration, Exercises Completed
- Exercise Breakdown: List with sets/reps completed per exercise
- Total Volume: Sum of (sets × reps × weight)
- Time Under Tension: Total active exercise time
- Muscle Groups Worked: Visual diagram
- Rest Time Adherence: % of prescribed rest taken

**Action Buttons**:
- "Save to History": Persists to Supabase, returns to Track Tab
- "Share Achievement": Opens share sheet with summary image

### 12. Activity History (Enhanced)

**Purpose**: Display recent workouts with mood badges

**Activity Card Design**:

**Standard Card** (no mood data):
```
┌─────────────────────────────────────────┐
│  🏃  Morning Run                        │
│      3.2 km • 25 min • 180 cal         │
│      Today, 8:45 AM                     │
└─────────────────────────────────────────┘
```

**Enhanced Card** (with mood data):
```
┌─────────────────────────────────────────┐
│  🏃  Morning Run          😐 → 💪      │
│      3.2 km • 25 min • 180 cal         │
│      Mood boost: +2 points 🚀          │
│      Today, 8:45 AM                     │
└─────────────────────────────────────────┘
```

**Card Components**:
- Workout type icon (colored circle, Solar Icons)
- Workout name (titleMedium)
- Metrics row (bodySmall, gray text)
- Mood badges (if available) - top right
- Mood boost text (if positive change)
- Timestamp (bodySmall, gray text)

**Interaction**:
- Tap card → Navigate to detailed summary view
- Swipe left → Delete option (with confirmation)

## Data Models

### MoodRating

```dart
class MoodRating {
  final int value; // 1-5
  final String emoji; // 😢 😕 😐 🙂 💪
  final DateTime timestamp;
  final String? notes;
  
  MoodRating({
    required this.value,
    required this.emoji,
    required this.timestamp,
    this.notes,
  }) : assert(value >= 1 && value <= 5);
  
  factory MoodRating.fromValue(int value) {
    final emojiMap = {
      1: '😢',
      2: '😕',
      3: '😐',
      4: '🙂',
      5: '💪',
    };
    return MoodRating(
      value: value,
      emoji: emojiMap[value]!,
      timestamp: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson();
  factory MoodRating.fromJson(Map<String, dynamic> json);
}
```

### WorkoutSession (Base)

```dart
abstract class WorkoutSession {
  final String id;
  final String userId;
  final WorkoutType type;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  
  final MoodRating? preMood;
  final MoodRating? postMood;
  final int? moodChange; // post - pre
  
  final int? avgHeartRate;
  final int? maxHeartRate;
  final Map<String, int>? heartRateZones; // zone -> seconds
  final int? caloriesBurned;
  
  final WorkoutStatus status; // active, paused, completed, cancelled
  
  WorkoutSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.preMood,
    this.postMood,
    this.moodChange,
    this.avgHeartRate,
    this.maxHeartRate,
    this.heartRateZones,
    this.caloriesBurned,
    this.status = WorkoutStatus.active,
  });
  
  Map<String, dynamic> toJson();
  factory WorkoutSession.fromJson(Map<String, dynamic> json);
}

enum WorkoutType { running, walking, resistance, cycling, yoga }
enum WorkoutStatus { active, paused, completed, cancelled }
```

### RunningSession (extends WorkoutSession)

```dart
class RunningSession extends WorkoutSession {
  final GoalType goalType; // distance or duration
  final double? targetDistance; // km
  final int? targetDuration; // minutes
  
  final double currentDistance; // km
  final double? avgPace; // min/km
  final List<LatLng> routePoints;
  final String? routePolyline; // encoded for storage
  final int? elevationGain; // meters
  
  RunningSession({
    required super.id,
    required super.userId,
    required super.startTime,
    required this.goalType,
    this.targetDistance,
    this.targetDuration,
    this.currentDistance = 0.0,
    this.avgPace,
    this.routePoints = const [],
    this.routePolyline,
    this.elevationGain,
    super.endTime,
    super.durationSeconds,
    super.preMood,
    super.postMood,
    super.moodChange,
    super.avgHeartRate,
    super.maxHeartRate,
    super.heartRateZones,
    super.caloriesBurned,
    super.status,
  }) : super(type: WorkoutType.running);
  
  double get progressPercentage {
    if (goalType == GoalType.distance && targetDistance != null) {
      return (currentDistance / targetDistance!).clamp(0.0, 1.0);
    } else if (goalType == GoalType.duration && targetDuration != null && durationSeconds != null) {
      return (durationSeconds! / (targetDuration! * 60)).clamp(0.0, 1.0);
    }
    return 0.0;
  }
  
  @override
  Map<String, dynamic> toJson();
  factory RunningSession.fromJson(Map<String, dynamic> json);
}

enum GoalType { distance, duration }
```

### WalkingSession (extends WorkoutSession)

```dart
class WalkingSession extends WorkoutSession {
  final WalkingMode mode; // free or mission
  final int? targetDuration; // minutes (for free walk)
  
  final double currentDistance; // km
  final int steps;
  final List<LatLng> routePoints;
  final String? routePolyline;
  
  final Mission? mission;
  final bool missionCompleted;
  
  WalkingSession({
    required super.id,
    required super.userId,
    required super.startTime,
    required this.mode,
    this.targetDuration,
    this.currentDistance = 0.0,
    this.steps = 0,
    this.routePoints = const [],
    this.routePolyline,
    this.mission,
    this.missionCompleted = false,
    super.endTime,
    super.durationSeconds,
    super.preMood,
    super.postMood,
    super.moodChange,
    super.avgHeartRate,
    super.maxHeartRate,
    super.heartRateZones,
    super.caloriesBurned,
    super.status,
  }) : super(type: WorkoutType.walking);
  
  double? get distanceToTarget {
    if (mission != null && routePoints.isNotEmpty) {
      return _calculateDistance(routePoints.last, mission!.targetLocation);
    }
    return null;
  }
  
  @override
  Map<String, dynamic> toJson();
  factory WalkingSession.fromJson(Map<String, dynamic> json);
}

enum WalkingMode { free, mission }
```

### Mission

```dart
class Mission {
  final String id;
  final MissionType type;
  final LatLng targetLocation;
  final double? targetDistance; // meters (for target missions)
  final double? radius; // meters (for safety net missions)
  final String name;
  final String? description;
  
  Mission({
    required this.id,
    required this.type,
    required this.targetLocation,
    this.targetDistance,
    this.radius,
    required this.name,
    this.description,
  });
  
  bool isCompleted(LatLng currentLocation) {
    final distance = _calculateDistance(currentLocation, targetLocation);
    switch (type) {
      case MissionType.target:
        return targetDistance != null && distance >= targetDistance!;
      case MissionType.sanctuary:
        return distance <= 50; // within 50m
      case MissionType.safetyNet:
        return radius != null && distance <= radius!;
    }
  }
  
  Map<String, dynamic> toJson();
  factory Mission.fromJson(Map<String, dynamic> json);
}

enum MissionType { target, sanctuary, safetyNet }
```

### ResistanceSession (extends WorkoutSession)

```dart
class ResistanceSession extends WorkoutSession {
  final BodySplit split; // upper or lower
  final List<ExerciseProgress> exercises;
  final int restTimerSeconds; // 60, 90, or 120
  final bool audioCuesEnabled;
  final bool hrMonitorEnabled;
  
  final double? totalVolumeKg; // sum of sets × reps × weight
  final int? timeUnderTension; // seconds of active exercise
  
  ResistanceSession({
    required super.id,
    required super.userId,
    required super.startTime,
    required this.split,
    required this.exercises,
    this.restTimerSeconds = 90,
    this.audioCuesEnabled = true,
    this.hrMonitorEnabled = false,
    this.totalVolumeKg,
    this.timeUnderTension,
    super.endTime,
    super.durationSeconds,
    super.preMood,
    super.postMood,
    super.moodChange,
    super.avgHeartRate,
    super.maxHeartRate,
    super.heartRateZones,
    super.caloriesBurned,
    super.status,
  }) : super(type: WorkoutType.resistance);
  
  int get completedExercises => exercises.where((e) => e.isComplete).length;
  int get totalExercises => exercises.length;
  
  double get progressPercentage => completedExercises / totalExercises;
  
  @override
  Map<String, dynamic> toJson();
  factory ResistanceSession.fromJson(Map<String, dynamic> json);
}

enum BodySplit { upper, lower }
```

### ExerciseProgress

```dart
class ExerciseProgress {
  final String exerciseName;
  final String emoji; // 💪 🏋️ 🔥 etc
  final int totalSets;
  final int targetReps;
  final List<SetData> completedSets;
  
  ExerciseProgress({
    required this.exerciseName,
    required this.emoji,
    required this.totalSets,
    required this.targetReps,
    this.completedSets = const [],
  });
  
  int get currentSet => completedSets.length + 1;
  bool get isComplete => completedSets.length >= totalSets;
  
  void completeSet({int? reps, double? weight}) {
    completedSets.add(SetData(
      reps: reps ?? targetReps,
      weight: weight,
      completedAt: DateTime.now(),
    ));
  }
  
  Map<String, dynamic> toJson();
  factory ExerciseProgress.fromJson(Map<String, dynamic> json);
}

class SetData {
  final int reps;
  final double? weight; // kg
  final DateTime completedAt;
  
  SetData({
    required this.reps,
    this.weight,
    required this.completedAt,
  });
  
  Map<String, dynamic> toJson();
  factory SetData.fromJson(Map<String, dynamic> json);
}
```

### RecentActivity (Enhanced)

```dart
class RecentActivity {
  final String id;
  final String name;
  final String type; // 'running', 'walking', 'resistance'
  final String details; // "3.2 km • 25 min • 180 cal"
  final DateTime date;
  
  // New mood fields
  final MoodRating? preMood;
  final MoodRating? postMood;
  final int? moodChange;
  
  RecentActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
    required this.date,
    this.preMood,
    this.postMood,
    this.moodChange,
  });
  
  bool get hasMoodData => preMood != null && postMood != null;
  bool get hadMoodImprovement => moodChange != null && moodChange! > 0;
  
  String get moodBoostText {
    if (moodChange == null || moodChange! <= 0) return '';
    return 'Mood boost: +$moodChange points 🚀';
  }
  
  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(activityDay).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference <= 7) return '$difference days ago';
    return DateFormat('MMM d').format(date);
  }
  
  @override
  Map<String, dynamic> toJson();
  factory RecentActivity.fromJson(Map<String, dynamic> json);
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property Reflection

After analyzing all acceptance criteria, I've identified several areas where properties can be consolidated:

**Redundancy Analysis**:
1. Timer properties (5.1, 7.1, 9.1, 15.1, 15.2) all test the same core timer behavior - consolidated into one comprehensive timer property
2. Navigation timing properties (1.2, 1.3, 3.2, 4.5, 5.8, 10.5) all test navigation responsiveness - consolidated into one navigation property
3. Pause/resume properties (5.7, 15.3, 15.4) test the same pause/resume behavior - consolidated into one property
4. Mood display properties (11.2, 12.3, 12.4) all test mood visualization - consolidated into one property
5. Session persistence properties (2.5, 13.6, 15.6) all test data saving - consolidated into one property

**Properties to Keep**:
- Core workout flow properties (mood tracking, type selection, session management)
- GPS and mapping properties (route recording, distance calculation)
- Exercise progression properties (set tracking, rest timers)
- Data persistence and retrieval properties
- Error handling properties

### Correctness Properties

Property 1: Mood selection persistence
*For any* mood rating selected (1-5), when stored in a workout session, retrieving that session should return the same mood rating and corresponding emoji
**Validates: Requirements 2.5**

Property 2: Mood change calculation
*For any* pre-workout mood value and post-workout mood value, the calculated mood change should equal (post - pre)
**Validates: Requirements 10.3**

Property 3: Navigation responsiveness
*For any* user action that triggers navigation (START WORKOUT tap, workout type selection, end workout), the system should navigate to the target screen within the specified time limit (300-500ms)
**Validates: Requirements 1.2, 1.3, 3.2, 4.5, 5.8, 10.5**

Property 4: Workout type card information completeness
*For any* workout type card (Running, Walking, Resistance), the card should display estimated duration, calories, and benefits text
**Validates: Requirements 3.6**

Property 5: Session timer accuracy
*For any* active workout session, the elapsed timer should increment by 1 second every second and display in MM:SS format starting from 00:00
**Validates: Requirements 5.1, 7.1, 9.1, 15.1, 15.2**

Property 6: Pause and resume state preservation
*For any* active workout session, pausing should stop the timer while maintaining all session data, and resuming should continue the timer from the paused value
**Validates: Requirements 5.7, 15.3, 15.4**

Property 7: GPS route recording
*For any* running or walking session with GPS tracking active, the recorded route points should form a continuous path where each point is recorded approximately 5 seconds apart
**Validates: Requirements 5.3, 7.3**

Property 8: Mission completion detection
*For any* walking session with an active mission, when the current location is within 50 meters of the target location, the mission should be marked as completed
**Validates: Requirements 7.7**

Property 9: Exercise set progression
*For any* resistance training session, completing a set should increment the completed sets count and advance to the next set (or next exercise if all sets complete)
**Validates: Requirements 9.5, 9.7**

Property 10: Rest timer countdown
*For any* resistance training session with rest timer active, the timer should count down from the configured rest time (60/90/120s) to zero, then auto-advance to the next set
**Validates: Requirements 9.7**

Property 11: Workout completion detection
*For any* workout session (running, walking, or resistance), when all completion criteria are met (goal reached or all exercises done), the system should navigate to post-workout mood check
**Validates: Requirements 9.8**

Property 12: Mood display formatting
*For any* workout session with both pre and post mood data, the mood transformation display should show "pre-emoji → post-emoji" with "+X points improvement!" where X is the mood change
**Validates: Requirements 11.2**

Property 13: Conditional summary content
*For any* completed workout, the summary screen should display workout-type-specific content: route map for running/walking, exercise breakdown for resistance
**Validates: Requirements 11.5, 11.6**

Property 14: Session data persistence
*For any* completed workout session, saving to the database should persist all session fields (type, duration, mood data, metrics) and be retrievable by session ID
**Validates: Requirements 11.7, 13.6, 15.6**

Property 15: Activity card information completeness
*For any* recent activity, the activity card should display workout type icon, name, primary metrics, and timestamp
**Validates: Requirements 12.2**

Property 16: Conditional mood badge display
*For any* recent activity with mood data, the activity card should display pre-mood emoji → post-mood emoji, and if mood improved (positive change), should display "Mood boost: +X points 🚀"
**Validates: Requirements 12.3, 12.4**

Property 17: Activity card navigation
*For any* activity card tap, the system should navigate to the detailed workout summary view for that activity
**Validates: Requirements 12.6**

Property 18: OpenRouteService error handling
*For any* map rendering request, if the OpenRouteService API fails, the system should display "Map unavailable" message instead of crashing
**Validates: Requirements 14.6**

Property 19: Map viewport fitting
*For any* workout summary with a recorded route, the map should be zoomed to fit the entire route within the viewport
**Validates: Requirements 14.5**

Property 20: Timer state persistence
*For any* active workout session, the timer value should persist across screen rotations and brief app backgrounding (up to 5 minutes)
**Validates: Requirements 15.5**

## Error Handling

### GPS Tracking Errors

**Scenario**: GPS signal lost during workout
- **Detection**: No location updates for 30 seconds
- **User Feedback**: Banner message "GPS signal weak - trying to reconnect"
- **Recovery**: Continue session with last known location, resume tracking when signal returns
- **Data Impact**: Route polyline may have gaps, but session continues

**Scenario**: GPS permission denied
- **Detection**: Location permission check fails
- **User Feedback**: Alert dialog explaining GPS is required for running/walking
- **Recovery**: Prompt user to grant permission in settings
- **Data Impact**: Cannot start GPS-based workouts until permission granted

### OpenRouteService API Errors

**Scenario**: API rate limit exceeded
- **Detection**: HTTP 429 response from OpenRouteService
- **User Feedback**: "Map temporarily unavailable" message
- **Recovery**: Use cached map tiles if available, retry after cooldown
- **Data Impact**: Route visualization may be delayed but GPS recording continues

**Scenario**: Network connectivity lost
- **Detection**: Network request timeout or no internet connection
- **User Feedback**: "Offline mode - map will sync when connected"
- **Recovery**: Store route points locally, sync to map when connection restored
- **Data Impact**: No real-time map visualization, but data preserved

### Heart Rate Monitor Errors

**Scenario**: HR sensor disconnected during workout
- **Detection**: No HR data for 10 seconds
- **User Feedback**: "Heart rate monitor disconnected" banner
- **Recovery**: Continue workout without HR data, allow reconnection
- **Data Impact**: HR metrics show "N/A" for disconnected period

**Scenario**: HR sensor not available
- **Detection**: No HR sensor detected at session start
- **User Feedback**: HR fields show "--" instead of values
- **Recovery**: Workout continues normally without HR tracking
- **Data Impact**: HR metrics not recorded for this session

### Database Persistence Errors

**Scenario**: Supabase connection fails during save
- **Detection**: Network error or Supabase timeout
- **User Feedback**: "Saving workout..." with retry spinner
- **Recovery**: Queue save operation, retry up to 3 times with exponential backoff
- **Data Impact**: Session saved to local storage as backup, synced when connection restored

**Scenario**: Database constraint violation
- **Detection**: Supabase returns constraint error
- **User Feedback**: "Error saving workout - please try again"
- **Recovery**: Log error details, prompt user to retry
- **Data Impact**: Session data preserved locally, user can manually retry save

### Session State Errors

**Scenario**: App crashes during active workout
- **Detection**: App restart with active session in local storage
- **User Feedback**: "Resume your workout?" dialog on app launch
- **Recovery**: Offer to resume from last known state or discard session
- **Data Impact**: Timer and metrics resume from last saved state (may lose up to 5 seconds)

**Scenario**: Timer drift or inaccuracy
- **Detection**: Compare elapsed time with system clock
- **User Feedback**: None (silent correction)
- **Recovery**: Periodically sync timer with system clock
- **Data Impact**: Ensure duration_seconds matches actual elapsed time

### Mood Tracking Errors

**Scenario**: User dismisses mood check without selection
- **Detection**: Bottom sheet dismissed via swipe or back button
- **User Feedback**: None (use default)
- **Recovery**: Auto-select neutral mood (value 3)
- **Data Impact**: Session continues with default mood value

**Scenario**: Mood check timeout
- **Detection**: 10 seconds (pre) or 15 seconds (post) elapsed without selection
- **User Feedback**: Bottom sheet auto-dismisses
- **Recovery**: Use default mood (neutral for pre, same as pre for post)
- **Data Impact**: Session continues with default mood value

## Testing Strategy

### Unit Testing

**Models Testing**:
- Test all data model constructors, fromJson, and toJson methods
- Test model validation (e.g., mood value 1-5, non-negative distances)
- Test computed properties (e.g., progressPercentage, moodBoostText)
- Test equality and hashCode implementations

**Services Testing**:
- Mock GPS service to test location updates and route recording
- Mock OpenRouteService API to test map rendering and error handling
- Mock Supabase to test database operations
- Test calorie calculation algorithms with known inputs
- Test heart rate zone calculations

**Providers Testing**:
- Test state transitions (active → paused → resumed → completed)
- Test timer increment logic
- Test exercise progression logic
- Test mission completion detection
- Test mood change calculations

**Widget Testing**:
- Test mood emoji selector displays 5 options
- Test workout type cards display correct information
- Test timer display formats correctly (MM:SS)
- Test activity cards show mood badges when data present
- Test empty states display correctly

### Property-Based Testing

**Framework**: Use `dart_check` package for property-based testing in Dart

**Configuration**: Each property test should run minimum 100 iterations

**Test Tagging**: Each property test must include a comment with format:
```dart
// Feature: unified-workout-flow, Property X: [property description]
// Validates: Requirements Y.Z
```

**Property Test Examples**:

```dart
// Feature: unified-workout-flow, Property 2: Mood change calculation
// Validates: Requirements 10.3
test('mood change equals post minus pre for all mood values', () {
  check(
    forAll(
      integers(min: 1, max: 5), // pre-mood
      integers(min: 1, max: 5), // post-mood
      (pre, post) {
        final preMood = MoodRating.fromValue(pre);
        final postMood = MoodRating.fromValue(post);
        final session = WorkoutSession(
          preMood: preMood,
          postMood: postMood,
        );
        return session.moodChange == (post - pre);
      },
    ),
  );
});

// Feature: unified-workout-flow, Property 5: Session timer accuracy
// Validates: Requirements 5.1, 7.1, 9.1, 15.1, 15.2
test('timer increments by 1 second for all workout types', () {
  check(
    forAll(
      enums(WorkoutType.values),
      (workoutType) {
        final session = createSession(workoutType);
        final initialTime = session.elapsedSeconds;
        
        // Simulate 1 second passing
        session.tick();
        
        return session.elapsedSeconds == initialTime + 1;
      },
    ),
  );
});

// Feature: unified-workout-flow, Property 8: Mission completion detection
// Validates: Requirements 7.7
test('mission completes when within 50m of target for all locations', () {
  check(
    forAll(
      latLngs(), // random target locations
      doubles(min: 0, max: 100), // random distances
      (target, distance) {
        final mission = Mission(
          type: MissionType.sanctuary,
          targetLocation: target,
        );
        final currentLocation = offsetLocation(target, distance);
        final shouldComplete = distance <= 50;
        
        return mission.isCompleted(currentLocation) == shouldComplete;
      },
    ),
  );
});

// Feature: unified-workout-flow, Property 14: Session data persistence
// Validates: Requirements 11.7, 13.6, 15.6
test('saved session data round-trips correctly for all workout types', () {
  check(
    forAll(
      workoutSessions(), // generator for random workout sessions
      (session) async {
        await saveSession(session);
        final retrieved = await getSession(session.id);
        
        return retrieved != null &&
               retrieved.type == session.type &&
               retrieved.durationSeconds == session.durationSeconds &&
               retrieved.preMood?.value == session.preMood?.value &&
               retrieved.postMood?.value == session.postMood?.value;
      },
    ),
  );
});
```

**Custom Generators**:
```dart
// Generator for random LatLng coordinates
Generator<LatLng> latLngs() => combine2(
  doubles(min: -90, max: 90),  // latitude
  doubles(min: -180, max: 180), // longitude
  (lat, lng) => LatLng(lat, lng),
);

// Generator for random workout sessions
Generator<WorkoutSession> workoutSessions() => combine3(
  enums(WorkoutType.values),
  integers(min: 60, max: 7200), // duration 1min - 2hrs
  integers(min: 1, max: 5), // mood values
  (type, duration, mood) {
    switch (type) {
      case WorkoutType.running:
        return RunningSession(
          id: uuid(),
          userId: 'test-user',
          startTime: DateTime.now(),
          durationSeconds: duration,
          preMood: MoodRating.fromValue(mood),
          currentDistance: random.nextDouble() * 20,
          goalType: GoalType.distance,
        );
      // ... other workout types
    }
  },
);
```

### Integration Testing

**End-to-End Workout Flows**:
1. Complete running workout flow (mood → setup → active → mood → summary → save)
2. Complete walking workout flow with mission
3. Complete resistance workout flow with all exercises
4. Test pause/resume during active workout
5. Test app backgrounding and recovery
6. Test GPS tracking throughout workout
7. Test offline mode and sync when reconnected

**Database Integration**:
1. Test workout session CRUD operations
2. Test activity history retrieval with pagination
3. Test mood data filtering and aggregation
4. Test concurrent session saves
5. Test database migration and schema validation

**API Integration**:
1. Test OpenRouteService map rendering with real API
2. Test API error handling and fallbacks
3. Test rate limiting behavior
4. Test map tile caching

**Performance Testing**:
1. Test GPS update frequency (5 second intervals)
2. Test timer update frequency (1 second intervals)
3. Test UI responsiveness during active workout
4. Test memory usage during long workouts (2+ hours)
5. Test battery consumption during GPS tracking

### Manual Testing Checklist

**Visual Design**:
- [ ] All workout type cards use correct gradient colors
- [ ] Mood emojis display correctly and are easily tappable
- [ ] Timer displays in MM:SS format consistently
- [ ] Activity cards show mood badges in correct position
- [ ] Maps render correctly with route polylines
- [ ] All icons are from Solar Icons library
- [ ] Font is GeneralSans throughout
- [ ] Touch targets are minimum 48x48 dp

**User Experience**:
- [ ] Mood check completes in <10 seconds
- [ ] Navigation feels instant (<500ms)
- [ ] No UI lag during active workouts
- [ ] Pause/resume works smoothly
- [ ] Rest timer countdown is clear and prominent
- [ ] Workout summary feels celebratory
- [ ] Activity history loads quickly

**Edge Cases**:
- [ ] Test with GPS disabled
- [ ] Test with no internet connection
- [ ] Test with HR monitor disconnected
- [ ] Test app backgrounding during workout
- [ ] Test device rotation during workout
- [ ] Test with very long workout (3+ hours)
- [ ] Test with zero mood change
- [ ] Test with negative mood change

## Implementation Notes

### Technology Stack

**State Management**: Riverpod 2.x
- Use `StateNotifierProvider` for workout session state
- Use `FutureProvider` for async data loading
- Use `StreamProvider` for real-time GPS updates

**Database**: Supabase
- PostgreSQL for workout_sessions table
- Row Level Security (RLS) for user data isolation
- Real-time subscriptions for activity updates

**Maps**: OpenRouteService
- API Key: 5b3ce35978511000001cf62248
- Use Directions V2 endpoint for route visualization
- Cache tiles using `flutter_cache_manager`

**GPS**: `geolocator` package
- Request location permissions at workout start
- Use `getPositionStream()` for continuous tracking
- Set `distanceFilter: 10` meters to reduce battery usage

**Icons**: `solar_icons` package
- Use outlined style for consistency
- Size: 24dp for cards, 20dp for buttons

**Fonts**: GeneralSans (already configured in AppTheme)

### File Structure

```
lib/
├── models/
│   ├── mood_rating.dart
│   ├── workout_session.dart
│   ├── running_session.dart
│   ├── walking_session.dart
│   ├── resistance_session.dart
│   ├── mission.dart
│   ├── exercise_progress.dart
│   └── recent_activity.dart (enhanced)
│
├── providers/
│   ├── workout_flow_provider.dart
│   ├── running_session_provider.dart
│   ├── walking_session_provider.dart
│   ├── resistance_session_provider.dart
│   ├── mood_tracking_provider.dart
│   └── activity_history_provider.dart (enhanced)
│
├── services/
│   ├── workout_session_service.dart
│   ├── gps_tracking_service.dart
│   ├── openroute_service.dart
│   ├── heart_rate_service.dart
│   ├── calorie_calculator_service.dart
│   └── timer_service.dart
│
├── screens/
│   ├── track_tab.dart (modified)
│   ├── workout_type_selection_screen.dart
│   │
│   ├── running/
│   │   ├── running_setup_screen.dart
│   │   ├── active_running_screen.dart
│   │   └── running_summary_screen.dart
│   │
│   ├── walking/
│   │   ├── walking_options_screen.dart
│   │   ├── mission_creation_screen.dart
│   │   ├── active_walking_screen.dart
│   │   └── walking_summary_screen.dart
│   │
│   └── resistance/
│       ├── split_selection_screen.dart
│       ├── active_resistance_screen.dart
│       └── resistance_summary_screen.dart
│
└── widgets/
    ├── mood_emoji_selector.dart
    ├── workout_type_card.dart
    ├── activity_card_with_mood.dart
    ├── mood_change_badge.dart
    ├── workout_timer.dart
    ├── gps_map_widget.dart
    ├── exercise_card.dart
    ├── rest_timer_widget.dart
    └── mood_transformation_card.dart
```

### Navigation Routes

```dart
// Unified workout flow routes
GoRoute(
  path: '/workout/start',
  builder: (context, state) => QuickMoodCheckBottomSheet(),
),
GoRoute(
  path: '/workout/select-type',
  builder: (context, state) => WorkoutTypeSelectionScreen(
    preMood: int.parse(state.queryParams['mood'] ?? '3'),
  ),
),

// Running routes
GoRoute(
  path: '/workout/running/setup',
  builder: (context, state) => RunningSetupScreen(),
),
GoRoute(
  path: '/workout/running/active/:sessionId',
  builder: (context, state) => ActiveRunningScreen(
    sessionId: state.pathParams['sessionId']!,
  ),
),
GoRoute(
  path: '/workout/running/summary/:sessionId',
  builder: (context, state) => RunningSummaryScreen(
    sessionId: state.pathParams['sessionId']!,
  ),
),

// Walking routes
GoRoute(
  path: '/workout/walking/options',
  builder: (context, state) => WalkingOptionsScreen(),
),
GoRoute(
  path: '/workout/walking/active/:sessionId',
  builder: (context, state) => ActiveWalkingScreen(
    sessionId: state.pathParams['sessionId']!,
  ),
),

// Resistance routes
GoRoute(
  path: '/workout/resistance/select-split',
  builder: (context, state) => SplitSelectionScreen(),
),
GoRoute(
  path: '/workout/resistance/active/:sessionId',
  builder: (context, state) => ActiveResistanceScreen(
    sessionId: state.pathParams['sessionId']!,
  ),
),

// Universal post-workout
GoRoute(
  path: '/workout/post-mood/:sessionId',
  builder: (context, state) => PostWorkoutMoodCheck(
    sessionId: state.pathParams['sessionId']!,
  ),
),
```

### Database Migration

```sql
-- Create workout_sessions table
CREATE TABLE workout_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  -- Session metadata
  workout_type TEXT NOT NULL CHECK (workout_type IN ('running', 'walking', 'resistance', 'cycling', 'yoga')),
  workout_subtype TEXT, -- 'upper', 'lower', 'free_walk', 'map_mission'
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  duration_seconds INTEGER,
  
  -- Mood tracking
  pre_workout_mood INTEGER CHECK (pre_workout_mood BETWEEN 1 AND 5),
  pre_workout_mood_emoji TEXT,
  pre_workout_notes TEXT,
  post_workout_mood INTEGER CHECK (post_workout_mood BETWEEN 1 AND 5),
  post_workout_mood_emoji TEXT,
  post_workout_notes TEXT,
  mood_change INTEGER, -- post - pre
  
  -- Running/Walking specific
  distance_km DECIMAL(10,2),
  avg_pace DECIMAL(5,2), -- min/km
  route_polyline TEXT, -- encoded GPS route
  steps INTEGER,
  elevation_gain_m INTEGER,
  
  -- Resistance specific
  exercises_completed JSONB, -- [{name, sets: [{reps, weight}]}]
  total_volume_kg DECIMAL(10,2),
  rest_times_seconds INTEGER[],
  
  -- General metrics
  avg_heart_rate INTEGER,
  max_heart_rate INTEGER,
  heart_rate_zones JSONB, -- {zone1: 300, zone2: 600, ...} seconds
  calories_burned INTEGER,
  
  -- Map Mission specific
  mission_id UUID,
  mission_completed BOOLEAN DEFAULT false,
  
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_start_time ON workout_sessions(start_time DESC);
CREATE INDEX idx_workout_sessions_type ON workout_sessions(workout_type);
CREATE INDEX idx_workout_sessions_status ON workout_sessions(status);

-- Enable Row Level Security
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own workout sessions"
  ON workout_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout sessions"
  ON workout_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workout sessions"
  ON workout_sessions FOR UPDATE
  USING (auth.uid() = user_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_workout_sessions_updated_at
  BEFORE UPDATE ON workout_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### OpenRouteService Integration

```dart
class OpenRouteService {
  static const String apiKey = '5b3ce35978511000001cf62248';
  static const String baseUrl = 'https://api.openrouteservice.org';
  
  Future<String> encodePolyline(List<LatLng> points) async {
    // Use OpenRouteService Directions API to encode route
    final response = await http.post(
      Uri.parse('$baseUrl/v2/directions/foot-walking/geojson'),
      headers: {
        'Authorization': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'coordinates': points.map((p) => [p.longitude, p.latitude]).toList(),
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['routes'][0]['geometry'];
    } else {
      throw OpenRouteServiceException('Failed to encode polyline');
    }
  }
  
  Future<List<LatLng>> decodePolyline(String encoded) async {
    // Decode polyline string to list of coordinates
    // Implementation depends on encoding format
  }
  
  Future<MapTile> getMapTile(int x, int y, int zoom) async {
    // Fetch map tile from OpenRouteService
    // Cache using flutter_cache_manager
  }
}
```

## Summary

This design provides a comprehensive blueprint for implementing the Unified Workout Flow in FlowFit. The key innovations are:

1. **Single Entry Point**: Eliminates decision paralysis with one "START WORKOUT" button
2. **Mood Tracking Integration**: Creates motivational feedback loops by showing emotional ROI
3. **Specialized Experiences**: Each workout type gets optimal UI while maintaining consistency
4. **Real-time Feedback**: Live metrics, GPS tracking, and timers keep users engaged
5. **Celebration of Progress**: Prominent mood improvement displays motivate continued use

The architecture is built on solid foundations (Riverpod, Supabase, OpenRouteService) with comprehensive error handling, property-based testing, and clear separation of concerns. The implementation can proceed incrementally, starting with core infrastructure and building up to specialized workout experiences.
