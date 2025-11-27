# Requirements Document - Unified Workout Flow

## Introduction

The Unified Workout Flow redesigns FlowFit's Track Tab to provide a streamlined, user-centric workout experience. The current implementation has multiple confusing entry points (Start Workout, Log Run, Record Walk, Map Missions) that create decision paralysis. This feature consolidates all workout types into a single, intelligent entry point with mood tracking integration, providing users with specialized experiences for running, walking, and resistance training while maintaining consistent UI patterns and leveraging GPS tracking via OpenRouteService API.

## Glossary

- **Track Tab**: The main fitness tracking screen in FlowFit where users view daily stats and start workouts
- **Workout Session**: A timed fitness activity with pre/post mood tracking and real-time metrics
- **Mood Tracking**: Emotional state capture before and after workouts using a 5-point emoji scale
- **OpenRouteService**: Third-party API service for GPS route visualization and mapping (API Key: 5b3ce35978511000001cf62248)
- **Map Mission**: Location-based fitness challenge where users walk to specific GPS coordinates
- **Activity History**: Chronological list of completed workout sessions with mood badges
- **Resistance Training**: Strength workout with upper/lower body split and set/rep tracking
- **GPS Tracking**: Real-time location recording during running and walking workouts
- **Session Timer**: Continuous elapsed time display during active workout sessions
- **Solar Icons**: Icon library used throughout FlowFit for consistent visual design

## Requirements

### Requirement 1: Unified Workout Entry Point

**User Story:** As a FlowFit user, I want a single clear button to start any workout, so that I can quickly begin exercising without decision paralysis.

#### Acceptance Criteria

1. WHEN a user views the Track Tab THEN the system SHALL display exactly one primary action button labeled "START WORKOUT"
2. WHEN a user taps "START WORKOUT" THEN the system SHALL immediately present a mood check bottom sheet within 500 milliseconds
3. WHEN the mood check completes THEN the system SHALL automatically navigate to workout type selection within 300 milliseconds
4. THE Track Tab SHALL remove all previous workout entry buttons (Log Run, Record Walk, Map Missions standalone buttons)
5. THE "START WORKOUT" button SHALL use the primary theme color (#3B82F6) with white text and 16px border radius

### Requirement 2: Pre-Workout Mood Tracking

**User Story:** As a user, I want to quickly log my mood before starting a workout, so that I can track how exercise affects my emotional state.

#### Acceptance Criteria

1. WHEN the mood check bottom sheet appears THEN the system SHALL display 5 emoji options representing mood states (1=😢 Very Bad, 2=😕 Bad, 3=😐 Neutral, 4=🙂 Good, 5=💪 Energized)
2. WHEN a user selects a mood emoji THEN the system SHALL record the selection and auto-dismiss the sheet within 200 milliseconds
3. THE mood check bottom sheet SHALL include the heading "How are you feeling?" in titleLarge typography
4. THE mood check SHALL complete within 10 seconds or auto-select neutral (3) if no interaction occurs
5. WHEN a mood is selected THEN the system SHALL store the preMoodRating and preMoodEmoji in the workout session

### Requirement 3: Workout Type Selection

**User Story:** As a user, I want to choose from different workout types with clear visual distinction, so that I can select the activity that matches my current intention.

#### Acceptance Criteria

1. WHEN the workout type selection screen loads THEN the system SHALL display cards for Running, Walking, and Resistance Training workout types
2. WHEN a user taps a workout type card THEN the system SHALL navigate to the type-specific setup screen within 300 milliseconds
3. THE Running card SHALL use blue gradient (#3B82F6 to cyan) with running icon from Solar Icons
4. THE Walking card SHALL use green gradient (#10B981 to emerald) with walking icon from Solar Icons
5. THE Resistance card SHALL use red gradient (#EF4444 to orange) with dumbbell icon from Solar Icons
6. EACH workout type card SHALL display estimated duration, calories, and primary benefits text
7. THE workout type cards SHALL have 16px border radius and 24px vertical spacing between them

### Requirement 4: Running Workout Setup

**User Story:** As a runner, I want to configure my run parameters before starting, so that I can set appropriate goals for my workout.

#### Acceptance Criteria

1. WHEN the running setup screen loads THEN the system SHALL display toggle options for Distance Goal and Duration Goal
2. WHEN Distance Goal is selected THEN the system SHALL display a slider for 1-20 km with 0.5 km increments
3. WHEN Duration Goal is selected THEN the system SHALL display a slider for 5-120 minutes with 5-minute increments
4. THE running setup screen SHALL display a map preview using OpenRouteService with current GPS location centered
5. WHEN a user taps "Start Running" THEN the system SHALL create a workout session and navigate to active running screen within 500 milliseconds
6. THE setup screen SHALL display estimated pace, calories, and target heart rate based on selected goal

### Requirement 5: Active Running Session with GPS Tracking

**User Story:** As a runner, I want to see real-time metrics and my route during my run, so that I can monitor my performance and navigate effectively.

#### Acceptance Criteria

1. WHEN the active running session starts THEN the system SHALL display a continuously updating timer showing elapsed time in MM:SS format
2. THE active running screen SHALL update distance, pace, and duration metrics every 1 second
3. THE system SHALL record GPS coordinates every 5 seconds and display the route on an OpenRouteService map
4. WHEN GPS tracking is active THEN the system SHALL display current distance in large typography (headlineLarge) centered on screen
5. THE active running screen SHALL display secondary metrics (duration, pace, heart rate, calories) in a 2x2 grid below primary distance
6. THE system SHALL display pause and end workout buttons at the bottom with 48x48 dp minimum touch targets
7. WHEN a user taps pause THEN the system SHALL stop timer and GPS recording while maintaining session state
8. WHEN a user taps end workout THEN the system SHALL navigate to post-workout mood check within 300 milliseconds

### Requirement 6: Walking Workout Options

**User Story:** As a walker, I want to choose between casual walking and mission-based walking, so that I can match my workout to my current motivation level.

#### Acceptance Criteria

1. WHEN the walking options screen loads THEN the system SHALL display two cards: "Free Walk" and "Map Mission"
2. THE Free Walk card SHALL allow time-based goal selection (10-120 minutes) with 5-minute increments
3. THE Map Mission card SHALL display "Create Mission" button and show mission types (Target, Sanctuary, Safety Net)
4. WHEN a user selects Free Walk THEN the system SHALL navigate to active walking screen with timer and GPS tracking
5. WHEN a user selects Map Mission THEN the system SHALL display mission creation interface with OpenRouteService map
6. THE Map Mission card SHALL include a "NEW" badge in the top-right corner with tertiary color background

### Requirement 7: Active Walking Session with Map Integration

**User Story:** As a walker, I want to see my walking route and progress in real-time, so that I can track my movement and complete missions.

#### Acceptance Criteria

1. WHEN the active walking session starts THEN the system SHALL display a continuously updating timer showing elapsed time in MM:SS format
2. THE active walking screen SHALL allocate top 40% of screen to OpenRouteService map showing current location and route
3. THE system SHALL record GPS coordinates every 5 seconds and render the walking path on the map
4. THE active walking screen SHALL display duration, distance, steps, and calories in a 2x2 grid in bottom 60% of screen
5. WHEN a Map Mission is active THEN the system SHALL display distance remaining to target as an overlay on the map
6. THE system SHALL display pause and end workout buttons with 48x48 dp minimum touch targets
7. WHEN mission target is reached THEN the system SHALL display completion animation and auto-end the workout

### Requirement 8: Resistance Training Split Selection

**User Story:** As a strength trainer, I want to choose between upper and lower body workouts, so that I can follow a structured training split.

#### Acceptance Criteria

1. WHEN the split selection screen loads THEN the system SHALL display two cards: "Upper Body" and "Lower Body"
2. THE Upper Body card SHALL display 6 exercises (Chest, Back, Shoulders, Arms focus) with estimated 45-60 min duration
3. THE Lower Body card SHALL display 6 exercises (Quads, Hamstrings, Glutes, Calves focus) with estimated 50-70 min duration
4. WHEN a split is selected THEN the system SHALL expand to show exercise list with sets × reps for each exercise
5. THE split selection SHALL include workout settings: rest timer (60/90/120 seconds), audio cues toggle, HR monitor toggle
6. WHEN "Start Workout" is tapped THEN the system SHALL navigate to active resistance screen with first exercise loaded

### Requirement 9: Active Resistance Training Session

**User Story:** As a strength trainer, I want guided exercise tracking with set completion and rest timers, so that I can maintain proper workout structure.

#### Acceptance Criteria

1. WHEN the active resistance session starts THEN the system SHALL display a continuously updating timer showing total workout elapsed time in MM:SS format
2. THE active resistance screen SHALL display current exercise name in titleLarge typography with corresponding Solar Icon emoji
3. THE system SHALL display "Set X of Y" progress with Z target reps prominently below exercise name
4. THE active resistance screen SHALL show set progress circles (completed sets in green, remaining in gray)
5. WHEN a user taps "Complete Set" THEN the system SHALL mark set as complete and start rest timer countdown
6. THE rest timer SHALL display large circular countdown in MM:SS format with "Skip Rest" button
7. WHEN rest timer completes THEN the system SHALL auto-advance to next set with audio cue (if enabled)
8. WHEN all exercises complete THEN the system SHALL navigate to post-workout mood check within 300 milliseconds

### Requirement 10: Post-Workout Mood Tracking

**User Story:** As a user, I want to log my mood after completing a workout, so that I can see how exercise improved my emotional state.

#### Acceptance Criteria

1. WHEN the post-workout mood check appears THEN the system SHALL display the same 5 emoji options as pre-workout
2. THE post-workout mood check SHALL include heading "How do you feel now?" in titleLarge typography
3. WHEN a user selects post-workout mood THEN the system SHALL calculate mood change (post - pre) and store in session
4. THE post-workout mood check SHALL auto-select same as pre-workout mood if no interaction within 15 seconds
5. WHEN post-workout mood is recorded THEN the system SHALL navigate to workout summary screen within 300 milliseconds

### Requirement 11: Workout Summary with Mood Display

**User Story:** As a user, I want to see my workout achievements and mood improvement, so that I feel motivated and validated for my effort.

#### Acceptance Criteria

1. WHEN the workout summary screen loads THEN the system SHALL display mood transformation card at the top with gradient background
2. THE mood transformation card SHALL show pre-workout emoji → post-workout emoji with arrow and "+X points improvement!" text
3. THE workout summary SHALL display primary metrics (distance/duration) in large cards with headlineMedium typography
4. THE workout summary SHALL display secondary metrics (pace, avg HR, calories) in 3-column grid below primary metrics
5. WHEN workout type is Running or Walking THEN the system SHALL display recorded route on OpenRouteService map
6. WHEN workout type is Resistance THEN the system SHALL display exercise completion breakdown with sets/reps completed
7. THE workout summary SHALL include "Save to History" button that persists session to database and returns to Track Tab

### Requirement 12: Activity History with Mood Badges

**User Story:** As a user, I want to see my past workouts with mood improvements, so that I can track my emotional fitness journey over time.

#### Acceptance Criteria

1. WHEN the Track Tab loads THEN the system SHALL display "Recent Activity" section with chronological list of workout sessions
2. EACH activity card SHALL display workout type icon, name, primary metrics, and timestamp
3. WHEN a workout session has mood data THEN the activity card SHALL display pre-mood emoji → post-mood emoji in top-right corner
4. WHEN mood improved (positive change) THEN the activity card SHALL display "Mood boost: +X points 🚀" text below metrics
5. THE activity cards SHALL use workout-type-specific colors (Running=blue, Walking=green, Resistance=red)
6. WHEN a user taps an activity card THEN the system SHALL navigate to detailed workout summary view
7. WHEN no activities exist THEN the system SHALL display empty state with "No activity yet today" message and motivational subtitle

### Requirement 13: Database Persistence

**User Story:** As a system administrator, I want all workout sessions stored in Supabase, so that user data is persisted and accessible across devices.

#### Acceptance Criteria

1. THE system SHALL create a workout_sessions table with fields: id, user_id, workout_type, start_time, end_time, duration_seconds
2. THE workout_sessions table SHALL include mood fields: pre_workout_mood, pre_workout_mood_emoji, post_workout_mood, post_workout_mood_emoji, mood_change
3. THE workout_sessions table SHALL include running/walking fields: distance_km, avg_pace, route_polyline, steps, elevation_gain_m
4. THE workout_sessions table SHALL include resistance fields: exercises_completed (JSONB), total_volume_kg, rest_times_seconds (array)
5. THE workout_sessions table SHALL include general metrics: avg_heart_rate, max_heart_rate, heart_rate_zones (JSONB), calories_burned
6. WHEN a workout is saved THEN the system SHALL persist all session data to Supabase within 3 seconds
7. THE system SHALL create indexes on user_id, start_time, and workout_type for query performance

### Requirement 14: OpenRouteService GPS Integration

**User Story:** As a runner or walker, I want my route visualized on a map, so that I can see where I've been and share my path.

#### Acceptance Criteria

1. THE system SHALL use OpenRouteService API with key "5b3ce35978511000001cf62248" for all map rendering
2. WHEN GPS tracking is active THEN the system SHALL send coordinates to OpenRouteService every 5 seconds to update route polyline
3. THE system SHALL display user's current location as a blue pulsing dot on the map
4. THE system SHALL render the recorded route as a blue line with 4px width on the map
5. WHEN a workout summary displays a map THEN the system SHALL fit the entire route within the map viewport
6. THE system SHALL handle OpenRouteService API errors gracefully and display "Map unavailable" message if service fails
7. THE system SHALL cache map tiles locally to reduce API calls and improve performance

### Requirement 15: Session Timer Requirements

**User Story:** As a user, I want to see elapsed time during all workout types, so that I can track how long I've been exercising.

#### Acceptance Criteria

1. WHEN any workout session starts THEN the system SHALL display a timer starting at 00:00 in MM:SS format
2. THE timer SHALL update every 1 second and display in titleMedium typography in the header area
3. WHEN a workout is paused THEN the timer SHALL stop incrementing but remain visible
4. WHEN a workout is resumed THEN the timer SHALL continue from the paused time
5. THE timer SHALL persist across screen rotations and brief app backgrounding (up to 5 minutes)
6. WHEN a workout ends THEN the final timer value SHALL be stored as duration_seconds in the database

### Requirement 16: UI Consistency and Design System

**User Story:** As a user, I want all workout screens to feel cohesive and familiar, so that I can navigate confidently without relearning interfaces.

#### Acceptance Criteria

1. ALL workout screens SHALL use the GeneralSans font family as defined in AppTheme
2. ALL interactive elements SHALL have minimum 48x48 dp touch targets for accessibility
3. ALL cards SHALL use 16px border radius and white surface color on light gray background (#F1F6FD)
4. ALL primary action buttons SHALL use primary blue (#3B82F6) with white text and 12px border radius
5. ALL workout type screens SHALL use consistent spacing: 16px horizontal padding, 24px vertical spacing between sections
6. ALL icons SHALL be sourced from Solar Icons library for visual consistency
7. THE system SHALL use workout-type-specific gradient colors as defined in design system (Running=blue-cyan, Walking=green-emerald, Resistance=red-orange)
