# Onboarding Survey Flow

## Survey Steps

The onboarding survey consists of 5 screens (0-4):

### Step 0: Survey Intro (`survey_intro_screen.dart`)

- **Route**: `/survey_intro`
- **Purpose**: Welcome screen explaining the survey
- **Features**:
  - Animated heart icon
  - Feature preview cards
  - Progress indicator (0/4)
  - Skip option to dashboard
- **Next**: `/survey_basic_info`

### Step 1: Basic Info (`survey_basic_info_screen.dart`)

- **Route**: `/survey_basic_info`
- **Purpose**: Collect age and gender
- **Data Collected**:
  - Age (13-120)
  - Gender (Male/Female/Other)
- **Backend**: Saves to `surveyNotifierProvider`
- **Validation**: `validateBasicInfo()`
- **Next**: `/survey_body_measurements`

### Step 2: Body Measurements (`survey_body_measurements_screen.dart`)

- **Route**: `/survey_body_measurements`
- **Purpose**: Collect height and weight
- **Data Collected**:
  - Height (cm/ft)
  - Weight (kg/lbs)
- **Backend**: Saves to `surveyNotifierProvider`
- **Validation**: `validateBodyMeasurements()`
- **Next**: `/survey_activity_goals`

### Step 3: Activity & Goals (`survey_activity_goals_screen.dart`)

- **Route**: `/survey_activity_goals`
- **Purpose**: Collect activity level and fitness goals
- **Data Collected**:
  - Activity Level (Sedentary/Moderately Active/Very Active)
  - Goals (Lose Weight/Maintain/Build Muscle/Improve Cardio)
- **Backend**: Saves to `surveyNotifierProvider`
- **Validation**: `validateActivityGoals()`
- **Next**: `/survey_daily_targets`

### Step 4: Daily Targets (`survey_daily_targets_screen.dart`)

- **Route**: `/survey_daily_targets`
- **Purpose**: Set daily calorie and macro targets
- **Data Collected**:
  - Daily calorie target
  - Macro split (Protein/Carbs/Fats)
- **Backend**: Saves to `surveyNotifierProvider` and Supabase
- **Validation**: `validateDailyTargets()`
- **Next**: `/onboarding1` or `/dashboard`

## Reusable Components

### `SurveyAppBar` (`lib/widgets/survey_app_bar.dart`)

- Consistent back button
- Custom color (#314158)
- Reusable across all survey screens

### `SurveyProgressIndicator` (`lib/widgets/survey_app_bar.dart`)

- Shows current step (1-4)
- Filled segments for completed steps
- Gray segments for remaining steps

## Backend Integration

All survey screens use **Riverpod** for state management:

```dart
// Save data
ref.read(surveyNotifierProvider.notifier).updateSurveyData('key', value);

// Validate
final error = ref.read(surveyNotifierProvider.notifier).validateBasicInfo();

// Access data
final surveyState = ref.watch(surveyNotifierProvider);
final age = surveyState.surveyData['age'];
```

## Navigation Flow

```
/survey_intro (Step 0)
    ↓
/survey_basic_info (Step 1)
    ↓
/survey_body_measurements (Step 2)
    ↓
/survey_activity_goals (Step 3)
    ↓
/survey_daily_targets (Step 4)
    ↓
/onboarding1 or /dashboard
```

## Design Consistency

All screens follow the same design pattern:

- ✅ Custom colors (#314158 for text, #01060C for black, #F2F7FD for white)
- ✅ Reusable AppBar with back button
- ✅ Progress indicator showing current step
- ✅ Consistent button styling
- ✅ Form validation
- ✅ Error handling with SnackBars
- ✅ Disabled state for Continue button

## Files Removed

The following duplicate files were removed (2024-11-27):

- ❌ `survey_screen_1.dart` (replaced by `survey_basic_info_screen.dart`)
- ❌ `survey_screen_2.dart` (replaced by `survey_body_measurements_screen.dart`)
- ❌ `survey_screen_3.dart` (replaced by `survey_activity_goals_screen.dart`)

These files had no backend integration and were standalone implementations.
