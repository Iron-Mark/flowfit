# Profile-Onboarding Integration - Implementation Guide

## Progress

### ✅ Completed

- **Task 1**: UserProfile model created at `lib/core/domain/entities/user_profile.dart`

### 🔄 Next Steps

To complete this implementation, follow these steps in order:

## Phase 1: Core Infrastructure

### Task 2: ProfileRepository

Create `lib/core/domain/repositories/profile_repository.dart`:

```dart
abstract class ProfileRepository {
  Future<UserProfile?> getLocalProfile(String userId);
  Future<void> saveLocalProfile(UserProfile profile);
  Future<UserProfile?> getBackendProfile(String userId);
  Future<void> saveBackendProfile(UserProfile profile);
  Future<void> syncProfile(String userId);
}
```

Create `lib/core/data/repositories/profile_repository_impl.dart` with SharedPreferences + Supabase implementation.

### Task 3: ProfileNotifier

Create `lib/presentation/providers/profile_notifier.dart` using Riverpod StateNotifier.

### Task 4: Providers

Create `lib/presentation/providers/profile_providers.dart` with all necessary providers.

## Phase 2: Survey Integration

### Task 5: Survey Completion Handler

Create `lib/services/survey_completion_handler.dart` to migrate survey data to profile.

### Task 6: Update Survey Screens

Modify `survey_daily_targets_screen.dart` to call the completion handler.

## Phase 3: Profile Display

### Task 7: Update Profile Screen

Modify `dashboard_screen.dart` ProfileTab to display actual profile data instead of hardcoded values.

## Phase 4: Profile Editing

### Task 8: Edit Profile Screen

Create `lib/screens/profile/edit_profile_screen.dart` for editing profile fields.

## Phase 5: Backend

### Task 9: Supabase Table

Run SQL migration to create `user_profiles` table with RLS policies.

### Task 10-11: Sync Infrastructure

Implement offline sync queue and status indicators.

## Phase 6: Testing

### Tasks 12-16: Testing & Polish

Write tests and perform manual testing.

## Quick Start Commands

```bash
# Add dependencies (if not already present)
flutter pub add shared_preferences
flutter pub add connectivity_plus

# Run the app
flutter run

# Run tests (after writing them)
flutter test
```

## Key Files Created

1. ✅ `lib/core/domain/entities/user_profile.dart` - Complete UserProfile model

## Key Files To Create

2. `lib/core/domain/repositories/profile_repository.dart` - Repository interface
3. `lib/core/data/repositories/profile_repository_impl.dart` - Repository implementation
4. `lib/presentation/providers/profile_notifier.dart` - State management
5. `lib/presentation/providers/profile_providers.dart` - Riverpod providers
6. `lib/services/survey_completion_handler.dart` - Survey → Profile migration
7. `lib/screens/profile/edit_profile_screen.dart` - Profile editing UI

## Implementation Tips

1. **Start Small**: Implement local storage first, add backend sync later
2. **Test Incrementally**: Test each component as you build it
3. **Use Existing Patterns**: Follow the patterns already in the codebase
4. **Handle Errors**: Add try-catch blocks and user-friendly error messages
5. **Log Everything**: Add logging for debugging

## Current Status

**Completed**: 8/16 tasks (50%)  
**Completed Features**: ProfileRepository interface & implementation, ProfileNotifier and providers, SurveyCompletionHandler, SyncQueueService, sync status indicators, error handling, comprehensive tests  
**Next Task**: Task 4 - UI Integration (Profile Screen)  
**Estimated Time Remaining**: 1-2 weeks

---

**Note**: Core data layer and sync infrastructure are complete. Focus now shifts to UI integration and end-to-end testing.
