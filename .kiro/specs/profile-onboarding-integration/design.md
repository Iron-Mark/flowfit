# Design Document

## Overview

This design document outlines the architecture for integrating onboarding survey data with the user profile system. The solution implements an offline-first architecture with local storage as the primary data source and Supabase as the backend sync target.

## Architecture

### Data Flow

```
Onboarding Survey
    ↓
Survey Notifier (Riverpod)
    ↓
Profile Repository
    ├→ Local Storage (SharedPreferences) [Primary]
    └→ Backend (Supabase) [Sync]
    ↓
Profile Notifier (Riverpod)
    ↓
Profile Screen (UI)
```

### Offline-First Strategy

1. **Write**: Save to local storage first, then queue for backend sync
2. **Read**: Load from local storage, then fetch from backend in background
3. **Sync**: Automatic background sync when online
4. **Conflict Resolution**: Last-write-wins with timestamp comparison

## Components and Interfaces

### 1. UserProfile Model

**Purpose**: Unified data model for user profile information

```dart
class UserProfile {
  final String userId;
  final String? fullName;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? heightUnit;
  final String? weightUnit;
  final String? activityLevel;
  final List<String>? goals;
  final int? dailyCalorieTarget;
  final int? dailyStepsTarget;
  final int? dailyActiveMinutesTarget;
  final double? dailyWaterTarget;
  final String? profileImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  // Factory methods
  factory UserProfile.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  factory UserProfile.fromSurveyData(String userId, Map<String, dynamic> surveyData);
  UserProfile copyWith({...});
}
```

### 2. ProfileRepository

**Purpose**: Abstract interface for profile data operations

```dart
abstract class ProfileRepository {
  // Local operations
  Future<UserProfile?> getLocalProfile(String userId);
  Future<void> saveLocalProfile(UserProfile profile);
  Future<void> deleteLocalProfile(String userId);

  // Backend operations
  Future<UserProfile?> getBackendProfile(String userId);
  Future<void> saveBackendProfile(UserProfile profile);

  // Sync operations
  Future<void> syncProfile(String userId);
  Future<bool> hasPendingSync(String userId);
  Stream<SyncStatus> watchSyncStatus(String userId);
}
```

### 3. ProfileRepositoryImpl

**Purpose**: Concrete implementation with local + backend storage

```dart
class ProfileRepositoryImpl implements ProfileRepository {
  final SharedPreferences _prefs;
  final SupabaseClient _supabase;
  final Connectivity _connectivity;

  // Local storage keys
  static const String _profileKey = 'user_profile_';
  static const String _syncQueueKey = 'sync_queue_';

  @override
  Future<UserProfile?> getLocalProfile(String userId) async {
    final json = _prefs.getString('$_profileKey$userId');
    if (json == null) return null;
    return UserProfile.fromJson(jsonDecode(json));
  }

  @override
  Future<void> saveLocalProfile(UserProfile profile) async {
    await _prefs.setString(
      '$_profileKey${profile.userId}',
      jsonEncode(profile.toJson()),
    );
  }

  @override
  Future<UserProfile?> getBackendProfile(String userId) async {
    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .single();
    return UserProfile.fromJson(response);
  }

  @override
  Future<void> saveBackendProfile(UserProfile profile) async {
    await _supabase
        .from('user_profiles')
        .upsert(profile.toJson());
  }

  @override
  Future<void> syncProfile(String userId) async {
    // Implementation details...
  }
}
```

### 4. ProfileNotifier

**Purpose**: Riverpod state notifier for profile management

```dart
class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileRepository _repository;
  final String userId;

  ProfileNotifier(this._repository, this.userId) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      // Load from local first
      final localProfile = await _repository.getLocalProfile(userId);
      if (localProfile != null) {
        state = AsyncValue.data(localProfile);
      }

      // Fetch from backend in background
      final backendProfile = await _repository.getBackendProfile(userId);
      if (backendProfile != null) {
        await _repository.saveLocalProfile(backendProfile);
        state = AsyncValue.data(backendProfile);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    // Save locally first
    await _repository.saveLocalProfile(profile);
    state = AsyncValue.data(profile);

    // Sync to backend
    try {
      await _repository.saveBackendProfile(profile);
      final updated = profile.copyWith(isSynced: true);
      await _repository.saveLocalProfile(updated);
      state = AsyncValue.data(updated);
    } catch (e) {
      // Keep local data, queue for sync
      // Error handling...
    }
  }

  Future<void> updateField(String field, dynamic value) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      // Update specific field
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await updateProfile(updated);
  }
}
```

### 5. Survey Completion Handler

**Purpose**: Migrate survey data to profile on completion

```dart
class SurveyCompletionHandler {
  final ProfileRepository _profileRepository;
  final SurveyNotifier _surveyNotifier;

  Future<void> completeSurvey(String userId) async {
    // Get survey data
    final surveyData = _surveyNotifier.surveyData;

    // Create profile from survey data
    final profile = UserProfile.fromSurveyData(userId, surveyData);

    // Save locally first
    await _profileRepository.saveLocalProfile(profile);

    // Attempt backend sync
    try {
      await _profileRepository.saveBackendProfile(profile);
      final synced = profile.copyWith(isSynced: true);
      await _profileRepository.saveLocalProfile(synced);
    } catch (e) {
      // Queue for sync later
      // Log error but don't block user
    }

    // Clear survey state
    _surveyNotifier.clearSurveyData();
  }
}
```

### 6. Profile Screen Updates

**Purpose**: Display and edit profile data

```dart
class ProfileTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return const LoginPrompt();
    }

    final profileAsync = ref.watch(profileNotifierProvider(userId));

    return profileAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, st) => ErrorView(error: e),
      data: (profile) {
        if (profile == null) {
          return const CompleteProfilePrompt();
        }
        return ProfileView(profile: profile);
      },
    );
  }
}
```

## Data Models

### UserProfile Schema

```dart
{
  "userId": "string (UUID)",
  "fullName": "string?",
  "age": "int?",
  "gender": "string? (male|female|other)",
  "height": "double?",
  "weight": "double?",
  "heightUnit": "string? (cm|ft)",
  "weightUnit": "string? (kg|lbs)",
  "activityLevel": "string? (sedentary|moderately_active|very_active)",
  "goals": "List<String>? (lose_weight|maintain_weight|build_muscle|improve_cardio)",
  "dailyCalorieTarget": "int?",
  "dailyStepsTarget": "int?",
  "dailyActiveMinutesTarget": "int?",
  "dailyWaterTarget": "double?",
  "profileImagePath": "string?",
  "createdAt": "DateTime",
  "updatedAt": "DateTime",
  "isSynced": "bool"
}
```

### Supabase Table: user_profiles

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  age INTEGER CHECK (age >= 13 AND age <= 120),
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  height DECIMAL(5,2),
  weight DECIMAL(5,2),
  height_unit TEXT CHECK (height_unit IN ('cm', 'ft')),
  weight_unit TEXT CHECK (weight_unit IN ('kg', 'lbs')),
  activity_level TEXT CHECK (activity_level IN ('sedentary', 'moderately_active', 'very_active')),
  goals TEXT[],
  daily_calorie_target INTEGER,
  daily_steps_target INTEGER,
  daily_active_minutes_target INTEGER,
  daily_water_target DECIMAL(3,1),
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- RLS Policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id);
```

## Error Handling

### Local Storage Errors

```dart
try {
  await _repository.saveLocalProfile(profile);
} catch (e) {
  // Log error
  logger.error('Failed to save profile locally', error: e);
  // Show user-friendly message
  showSnackBar('Failed to save profile. Please try again.');
  // Don't block user flow
}
```

### Backend Sync Errors

```dart
try {
  await _repository.saveBackendProfile(profile);
} catch (e) {
  if (e is NetworkException) {
    // Queue for retry
    await _syncQueue.add(profile);
    showSnackBar('Saved locally. Will sync when online.');
  } else {
    // Log unexpected error
    logger.error('Backend sync failed', error: e);
    showSnackBar('Saved locally. Sync failed.');
  }
}
```

### Data Migration Errors

```dart
try {
  final profile = UserProfile.fromSurveyData(userId, surveyData);
} catch (e) {
  // Log migration error
  logger.error('Survey data migration failed', error: e);
  // Use safe defaults
  final profile = UserProfile.withDefaults(userId);
}
```

## Testing Strategy

### Unit Tests

1. **UserProfile Model**

   - Test JSON serialization/deserialization
   - Test fromSurveyData conversion
   - Test copyWith method
   - Test validation logic

2. **ProfileRepository**

   - Test local storage operations
   - Test backend operations
   - Test sync logic
   - Test error handling

3. **ProfileNotifier**
   - Test state transitions
   - Test load profile flow
   - Test update profile flow
   - Test error states

### Integration Tests

1. **Onboarding to Profile Flow**

   - Complete survey → verify profile created
   - Verify local storage has data
   - Verify backend has data (if online)
   - Navigate to profile → verify data displayed

2. **Offline Scenarios**

   - Complete survey offline → verify local save
   - Go online → verify auto-sync
   - Edit profile offline → verify queued for sync

3. **Profile Editing**
   - Edit field → verify local update
   - Verify backend sync
   - Navigate away and back → verify persistence

### Manual Testing

1. **Happy Path**

   - Complete onboarding
   - View profile
   - Edit profile fields
   - Verify changes persist

2. **Offline Mode**

   - Turn off internet
   - Complete onboarding
   - Turn on internet
   - Verify auto-sync

3. **Error Scenarios**
   - Backend unavailable
   - Invalid data
   - Concurrent edits

## Implementation Notes

### Phase 1: Core Infrastructure

1. Create UserProfile model
2. Implement ProfileRepository with local storage
3. Create ProfileNotifier
4. Add Riverpod providers

### Phase 2: Survey Integration

1. Add survey completion handler
2. Implement data migration
3. Update survey screens to save on completion
4. Test end-to-end flow

### Phase 3: Profile Screen

1. Update ProfileTab to use ProfileNotifier
2. Add loading/error states
3. Display all profile fields
4. Add edit functionality

### Phase 4: Backend Sync

1. Implement Supabase integration
2. Add sync queue
3. Implement auto-sync on connectivity change
4. Add sync status indicators

### Phase 5: Polish

1. Add animations
2. Improve error messages
3. Add retry logic
4. Performance optimization

## Design Decisions

### Why Offline-First?

- Better user experience (no loading spinners)
- Works without internet
- Faster perceived performance
- Resilient to network issues

### Why SharedPreferences for Local Storage?

- Simple key-value storage
- Built-in to Flutter
- Fast read/write
- Sufficient for profile data size

### Why Last-Write-Wins for Conflicts?

- Simple to implement
- Matches user expectations
- Rare conflicts in single-user app
- Can be enhanced later if needed

### Why Separate Profile from Auth?

- Auth handles authentication only
- Profile handles user data
- Clear separation of concerns
- Easier to test and maintain

## Future Enhancements

1. **Profile Image Upload**: Store images in Supabase Storage
2. **Profile History**: Track changes over time
3. **Data Export**: Allow users to download their data
4. **Profile Sharing**: Share profile with friends/trainers
5. **Advanced Sync**: Implement operational transformation for conflicts
