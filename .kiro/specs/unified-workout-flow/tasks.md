# Implementation Plan - Unified Workout Flow

- [x] 1. Set up core data models and database schema


  - Create MoodRating model with value (1-5), emoji, and timestamp
  - Create base WorkoutSession model with common fields (id, userId, type, startTime, endTime, duration, mood data, HR metrics, calories, status)
  - Create RunningSession extending WorkoutSession with goalType, targetDistance/Duration, currentDistance, avgPace, routePoints, routePolyline, elevationGain
  - Create WalkingSession extending WorkoutSession with mode (free/mission), targetDuration, currentDistance, steps, routePoints, mission, missionCompleted
  - Create Mission model with id, type (target/sanctuary/safetyNet), targetLocation, targetDistance, radius, name, description
  - Create ResistanceSession extending WorkoutSession with split (upper/lower), exercises list, restTimerSeconds, audioCuesEnabled, hrMonitorEnabled, totalVolumeKg, timeUnderTension
  - Create ExerciseProgress model with exerciseName, emoji, totalSets, targetReps, completedSets list
  - Create SetData model with reps, weight, completedAt
  - Enhance RecentActivity model with preMood, postMood, moodChange fields and computed properties (hasMoodData, hadMoodImprovement, moodBoostText, dateLabel)
  - Implement toJson/fromJson serialization for all models
  - Add model validation (mood 1-5, non-negative distances, valid enums)
  - _Requirements: 2.5, 10.3, 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ]* 1.1 Write property test for mood rating model
  - **Property 1: Mood selection persistence**
  - **Validates: Requirements 2.5**

- [ ]* 1.2 Write property test for mood change calculation
  - **Property 2: Mood change calculation**
  - **Validates: Requirements 10.3**

- [ ]* 1.3 Write property test for session data persistence
  - **Property 14: Session data persistence**
  - **Validates: Requirements 11.7, 13.6, 15.6**

- [x] 2. Create Supabase database migration


  - Write SQL migration to create workout_sessions table with all required fields
  - Add constraints: mood values 1-5, valid workout_type enum, non-negative numeric fields
  - Create indexes on user_id, start_time DESC, workout_type, status for query performance
  - Enable Row Level Security (RLS) on workout_sessions table
  - Create RLS policies: users can SELECT/INSERT/UPDATE their own sessions only
  - Create updated_at trigger function and apply to workout_sessions table
  - Test migration locally and verify all constraints work
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7_

- [x] 3. Implement core services layer



  - Create WorkoutSessionService with CRUD operations (create, get, update, save, list recent)
  - Create GPSTrackingService with startTracking, stopTracking, getPositionStream (5 second intervals), calculateDistance methods
  - Create OpenRouteService with encodePolyline, decodePolyline, getMapTile, renderRoute methods using API key 5b3ce35978511000001cf62248
  - Create HeartRateService with startMonitoring, stopMonitoring, getHRStream, calculateZones methods
  - Create CalorieCalculatorService with calculateCalories based on workout type, duration, distance, user profile
  - Create TimerService with start, pause, resume, stop, getElapsedSeconds methods
  - Add error handling for GPS permission denied, API failures, network errors
  - _Requirements: 5.3, 7.3, 14.1, 14.2, 14.3, 14.4, 14.6, 15.1, 15.2_

- [ ]* 3.1 Write property test for GPS route recording
  - **Property 7: GPS route recording**
  - **Validates: Requirements 5.3, 7.3**

- [ ]* 3.2 Write property test for timer accuracy
  - **Property 5: Session timer accuracy**
  - **Validates: Requirements 5.1, 7.1, 9.1, 15.1, 15.2**

- [x] 4. Create state management providers


  - Create WorkoutFlowProvider to manage overall workout flow state (currentStep, preMood, selectedType)
  - Create MoodTrackingProvider with selectPreMood, selectPostMood, calculateMoodChange methods
  - Create RunningSessionProvider extending StateNotifier with startSession, updateMetrics, pauseSession, resumeSession, endSession
  - Create WalkingSessionProvider extending StateNotifier with startSession, updateLocation, checkMissionCompletion, endSession
  - Create ResistanceSessionProvider extending StateNotifier with startSession, completeSet, skipSet, startRestTimer, skipRest, advanceToNextExercise, endWorkout
  - Create ActivityHistoryProvider with loadRecentActivities, refreshActivities, deleteActivity methods
  - Wire up providers to services (GPS, HR, Timer, Database)
  - _Requirements: 2.5, 5.7, 9.5, 9.7, 10.3, 12.1, 15.3, 15.4_

- [ ]* 4.1 Write property test for pause and resume state preservation
  - **Property 6: Pause and resume state preservation**
  - **Validates: Requirements 5.7, 15.3, 15.4**

- [ ]* 4.2 Write property test for exercise set progression
  - **Property 9: Exercise set progression**
  - **Validates: Requirements 9.5, 9.7**



- [x] 5. Modify Track Tab with unified entry point



  - Replace existing workout buttons (Log Run, Record Walk, Map Missions) with single "START WORKOUT" button
  - Style button with primary color (#3B82F6), white text, 16px border radius, full-width
  - Wire button tap to show QuickMoodCheckBottomSheet
  - Keep existing Daily Stats section unchanged
  - Update Recent Activity section to use enhanced RecentActivity model with mood badges
  - _Requirements: 1.1, 1.2, 1.4, 1.5_

- [ ]* 5.1 Write property test for navigation responsiveness
  - **Property 3: Navigation responsiveness**


  - **Validates: Requirements 1.2, 1.3, 3.2, 4.5, 5.8, 10.5**

- [x] 6. Create mood tracking UI components





  - Create QuickMoodCheckBottomSheet widget with "How are you feeling?" heading (titleLarge)
  - Implement 5 emoji buttons (😢 😕 😐 🙂 💪) with values 1-5 in horizontal row
  - Style emoji buttons with 56x56 dp touch targets, scale animation on tap
  - Add 10-second auto-dismiss timer that defaults to neutral (3) if no selection
  - Implement onMoodSelected callback that stores mood and navigates to workout type selection
  - Create PostWorkoutMoodCheck widget with "How do you feel now?" heading
  - Add 15-second auto-dismiss timer that defaults to pre-workout mood
  - Create MoodChangeBadge widget showing "pre-emoji → post-emoji"
  - Create MoodTransformationCard widget with gradient background and "+X points improvement!" text
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 10.1, 10.2, 10.4, 11.1, 11.2_



- [ ]* 6.1 Write property test for mood display formatting
  - **Property 12: Mood display formatting**
  - **Validates: Requirements 11.2**



- [x] 7. Create workout type selection screen


  - Create WorkoutTypeSelectionScreen with "Choose Your Workout" header (headlineMedium)
  - Create WorkoutTypeCard widget with gradient background, Solar Icon, type name, metrics row, benefits text
  - Implement Running card with blue-cyan gradient (#3B82F6 to cyan) and running icon
  - Implement Walking card with green-emerald gradient (#10B981 to emerald) and walking icon
  - Implement Resistance card with red-orange gradient (#EF4444 to orange) and dumbbell icon
  - Display estimated duration, calories, and benefits for each card
  - Style cards with 16px border radius, 24px vertical spacing, full-width
  - Wire card taps to navigate to type-specific setup screens



  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [ ]* 7.1 Write property test for workout type card information completeness
  - **Property 4: Workout type card information completeness**
  - **Validates: Requirements 3.6**

- [x] 8. Implement running workout flow




- [x] 8.1 Create RunningSetupScreen

  - Add goal type toggle (Distance / Duration) with segmented control
  - Implement distance slider (1-20 km, 0.5 km steps) when Distance selected
  - Implement duration slider (5-120 min, 5 min steps) when Duration selected
  - Add map preview using OpenRouteService showing current GPS location
  - Display quick stats cards: Est. Pace, Est. Calories, Target HR (calculated from user profile)
  - Add "Start Running" button (primary, full-width) that creates session and navigates to active screen
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 8.2 Create ActiveRunningScreen


  - Display status badge, timer (MM:SS), pause/end buttons in header
  - Show current distance in headlineLarge typography centered on screen

  - Create 2x2 grid for secondary metrics: Duration, Pace, Heart Rate, Calories
  - Add progress bar showing % to goal (distance or duration based)
  - Integrate OpenRouteService map showing current location (blue dot) and route polyline
  - Update all metrics every 1 second (distance, pace, timer, HR, calories)
  - Record GPS coordinates every 5 seconds and redraw route polyline
  - Implement pause button: stops timer and GPS, maintains state
  - Implement end button: shows confirmation dialog, navigates to post-mood check
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_

- [x] 8.3 Create RunningSummaryScreen


  - Display MoodTransformationCard at top with gradient background
  - Show primary metrics: Distance (large), Duration (large) in cards




  - Display secondary metrics grid: Avg Pace, Avg HR, Calories in 3 columns
  - Render full recorded route on OpenRouteService map with viewport fitted to route
  - Add heart rate zones bar chart showing time in each zone
  - Implement "Save to History" button that persists to Supabase and returns to Track Tab
  - Add "Share Achievement" button that opens share sheet with summary image
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.7, 14.5_


- [ ]* 8.4 Write property test for running session completion
  - **Property 11: Workout completion detection**
  - **Validates: Requirements 9.8**
- [ ] 9. Implement walking workout flow




- [ ] 9. Implement walking workout flow

- [x] 9.1 Create WalkingOptionsScreen


  - Create Free Walk card with walking icon, duration slider (10-120 min, 5 min steps)

  - Add "Start Free Walk" button that navigates to active walking screen
  - Create Map Mission card with "NEW" badge (tertiary color background, top-right)
  - Add mission type selector: Target / Sanctuary / Safety Net with descriptions
  - Add "Create Mission" button that shows mission creation interface
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 9.2 Create MissionCreationScreen


  - Display OpenRouteService map for selecting target location
  - Add mission type selector with descriptions (Target: walk X meters, Sanctuary: reach coordinate, Safety Net: stay within radius)
  - Implement distance/radius input based on mission type
  - Add mission name and description text fields
  - Add "Start Mission" button that creates mission and navigates to active walking screen
  - _Requirements: 6.3, 6.5_

- [x] 9.3 Create ActiveWalkingScreen

  - Display timer (MM:SS) and pause/end buttons in header (10% of screen)
  - Allocate top 40% to OpenRouteService map showing current location (blue dot) and route polyline
  - Display distance overlay card on map when mission active
  - Create 2x2 grid for stats (50% of screen): Duration, Distance, Steps, Calories
  - Add mood reminder at bottom: "💪 Remember: You started feeling 😐"
  - Update metrics every 1 second
  - Record GPS coordinates every 5 seconds and redraw route

  - When mission active: display distance to target, progress bar, check completion every update
  - When mission completed: show celebration animation and auto-end workout
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

- [ ]* 9.4 Write property test for mission completion detection
  - **Property 8: Mission completion detection**
  - **Validates: Requirements 7.7**

- [x] 9.5 Create WalkingSummaryScreen


  - Display MoodTransformationCard at top
  - Show primary metrics: Distance, Duration, Steps in cards
  - Display mission completion badge if mission was active
  - Render full recorded route on OpenRouteService map with mission markers
  - Display secondary metrics: Calories, Avg Pace
  - Add "Create Next Mission" button if mission was completed
  - Implement "Save to History" button that persists to Supabase and returns to Track Tab
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.7_

- [x] 10. Implement resistance training workout flow


- [x] 10.1 Create SplitSelectionScreen

  - Create Upper Body card with blue gradient, 💪 icon, "Chest, Back, Shoulders, Arms" focus text
  - Display 6 upper body exercises with sets × reps (e.g., "Bench Press 3×12")
  - Add estimated duration (45-60 min) and calories (400 cal)
  - Create Lower Body card with purple gradient, 🦵 icon, "Quads, Hamstrings, Glutes, Calves" focus text
  - Display 6 lower body exercises with sets × reps
  - Add estimated duration (50-70 min) and calories (500 cal)
  - Implement expandable exercise list when split selected
  - Add workout settings panel: Rest Timer (60/90/120s segmented control), Audio Cues toggle, HR Monitor toggle
  - Add "Pro Tip" callout: "Start with lighter weight to perfect form"
  - Wire "Start Workout" button to navigate to active resistance screen with exercise queue
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [x] 10.2 Create ActiveResistanceScreen

  - Display exercise progress (X/Y) and total timer in header
  - Show progress bar indicating % of exercises completed
  - Display quick stats: HR, Calories in header row
  - Create current exercise card: emoji icon, exercise name (titleLarge), "Set X of Y", target reps
  - Add set progress circles (completed=green filled, remaining=gray outline)
  - Implement "Skip Set" and "Complete ✓" buttons (48x48 dp touch targets)
  - Show exercise queue below: next 3 exercises with emoji, name, sets×reps
  - When set completed: start rest timer with large circular countdown (MM:SS)
  - Display "Get ready for set X of [exercise]" during rest
  - Add "Skip Rest" button during rest timer
  - When rest completes: play audio cue if enabled, advance to next set
  - When all sets of exercise complete: auto-advance to next exercise
  - When all exercises complete: navigate to post-workout mood check
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8_

- [ ]* 10.3 Write property test for rest timer countdown
  - **Property 10: Rest timer countdown**
  - **Validates: Requirements 9.7**

- [x] 10.4 Create ResistanceSummaryScreen

  - Display MoodTransformationCard at top
  - Show primary metrics: Total Duration, Exercises Completed in large cards
  - Create exercise breakdown list: each exercise with sets/reps completed
  - Display total volume: sum of (sets × reps × weight) in kg
  - Show time under tension: total active exercise time
  - Add muscle groups worked visual diagram
  - Display rest time adherence: % of prescribed rest taken
  - Implement "Save to History" button that persists to Supabase and returns to Track Tab
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.6, 11.7_

- [x] 11. Enhance activity history with mood badges

  - Update ActivityCard widget to display mood badges when hasMoodData is true
  - Show "pre-emoji → post-emoji" in top-right corner of card
  - Display "Mood boost: +X points 🚀" text below metrics when hadMoodImprovement is true
  - Use workout-type-specific colors for card accent (Running=blue, Walking=green, Resistance=red)
  - Implement card tap navigation to detailed workout summary view
  - Add swipe-left delete option with confirmation dialog
  - Display empty state when no activities: "No activity yet today" with motivational subtitle
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7_

- [ ]* 11.1 Write property test for activity card information completeness
  - **Property 15: Activity card information completeness**
  - **Validates: Requirements 12.2**

- [ ]* 11.2 Write property test for conditional mood badge display
  - **Property 16: Conditional mood badge display**
  - **Validates: Requirements 12.3, 12.4**

- [ ]* 11.3 Write property test for activity card navigation
  - **Property 17: Activity card navigation**
  - **Validates: Requirements 12.6**

- [x] 12. Implement OpenRouteService integration

  - Create OpenRouteService class with API key constant (5b3ce35978511000001cf62248)
  - Implement encodePolyline method: POST to /v2/directions/foot-walking/geojson with coordinates array
  - Implement decodePolyline method: parse encoded geometry string to LatLng list
  - Implement getMapTile method: fetch tiles from OpenRouteService with caching via flutter_cache_manager
  - Implement renderRoute method: draw polyline on map with 4px blue line
  - Add error handling: catch HTTP 429 (rate limit), network timeouts, invalid responses
  - Display "Map unavailable" message when API fails instead of crashing
  - Implement map viewport fitting: calculate bounds from route points and zoom to fit
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7_

- [ ]* 12.1 Write property test for OpenRouteService error handling
  - **Property 18: OpenRouteService error handling**
  - **Validates: Requirements 14.6**

- [ ]* 12.2 Write property test for map viewport fitting
  - **Property 19: Map viewport fitting**
  - **Validates: Requirements 14.5**

- [x] 13. Implement timer persistence and state management

  - Add timer state persistence to local storage (SharedPreferences)
  - Save timer value, workout session ID, and timestamp every 5 seconds during active workout
  - Implement app lifecycle listener to detect backgrounding and foregrounding
  - On app resume: check for active session in storage, calculate elapsed time from timestamp
  - Restore timer state if app was backgrounded < 5 minutes
  - Handle screen rotation: preserve timer state across configuration changes
  - Store final timer value as duration_seconds in database when workout ends
  - _Requirements: 15.5, 15.6_

- [ ]* 13.1 Write property test for timer state persistence
  - **Property 20: Timer state persistence**
  - **Validates: Requirements 15.5**

- [x] 14. Apply UI consistency and design system

  - Verify all screens use GeneralSans font family from AppTheme
  - Audit all interactive elements for 48x48 dp minimum touch targets
  - Apply 16px border radius to all cards
  - Use white surface color on light gray background (#F1F6FD) for all cards
  - Style all primary action buttons with primary blue (#3B82F6), white text, 12px border radius
  - Apply consistent spacing: 16px horizontal padding, 24px vertical spacing between sections
  - Replace all icons with Solar Icons equivalents
  - Apply workout-type-specific gradients: Running (blue-cyan), Walking (green-emerald), Resistance (red-orange)
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 16.7_

- [x] 15. Implement error handling and edge cases

  - Add GPS permission check before starting GPS-based workouts
  - Show permission request dialog with explanation when GPS denied
  - Display "GPS signal weak - trying to reconnect" banner when no location updates for 30 seconds
  - Continue session with last known location when GPS signal lost, resume when signal returns
  - Handle HR sensor disconnection: show "Heart rate monitor disconnected" banner, continue workout
  - Display "--" for HR metrics when sensor not available
  - Implement Supabase save retry logic: 3 attempts with exponential backoff
  - Queue failed saves to local storage, sync when connection restored
  - Show "Saving workout..." spinner during save operations
  - Handle app crash recovery: detect active session on restart, show "Resume your workout?" dialog
  - Implement timer drift correction: periodically sync with system clock
  - _Requirements: 14.6_

- [ ]* 15.1 Write property test for conditional summary content
  - **Property 13: Conditional summary content**
  - **Validates: Requirements 11.5, 11.6**

- [ ] 16. Final checkpoint - Ensure all tests pass


  - Run all property-based tests and verify 100 iterations pass
  - Run all unit tests and verify coverage
  - Test complete workout flows end-to-end for all three types
  - Verify database migrations applied successfully
  - Test GPS tracking accuracy and route recording
  - Verify OpenRouteService integration works with real API
  - Test mood tracking flow from pre to post to summary
  - Verify activity history displays mood badges correctly
  - Test error scenarios: GPS denied, network offline, API failures
  - Ensure all tests pass, ask the user if questions arise
