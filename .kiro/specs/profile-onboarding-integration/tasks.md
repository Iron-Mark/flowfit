# Implementation Plan

- [x] 1. Create UserProfile model and data structures

  - Create `lib/core/domain/entities/user_profile.dart` with all profile fields
  - Implement `fromJson()` and `toJson()` methods for serialization
  - Implement `fromSurveyData()` factory method to convert survey data
  - Implement `copyWith()` method for immutable updates
  - Add validation methods for profile fields
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 2. Create ProfileRepository interface and implementation

  - [x] 2.1 Create repository interface

    - Create `lib/core/domain/repositories/profile_repository.dart` interface
    - Define methods for local operations (get, save, delete)
    - Define methods for backend operations (get, save)
    - Define methods for sync operations (sync, hasPendingSync, watchSyncStatus)
    - _Requirements: 1.1, 2.1, 6.1_

  - [x] 2.2 Implement local storage operations

    - Create `lib/core/data/repositories/profile_repository_impl.dart`
    - Implement `getLocalProfile()` using SharedPreferences
    - Implement `saveLocalProfile()` with error handling
    - Implement `deleteLocalProfile()` for cleanup
    - Add local storage key constants
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 2.3 Implement backend operations

    - Implement `getBackendProfile()` using Supabase client
    - Implement `saveBackendProfile()` with upsert logic
    - Add error handling for network failures
    - Add timeout handling for slow connections
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 2.4 Implement sync operations

    - Implement `syncProfile()` with conflict resolution
    - Implement `hasPendingSync()` to check sync queue
    - Implement `watchSyncStatus()` stream for real-time updates
    - Add last-write-wins conflict resolution logic
    - _Requirements: 2.4, 2.5, 6.2, 6.3_

- [x] 3. Create ProfileNotifier for state management

  - Create `lib/presentation/providers/profile_notifier.dart`
  - Implement `loadProfile()` with local-first strategy
  - Implement `updateProfile()` with local save + backend sync
  - Implement `updateField()` for single field updates
  - Add error state handling
  - Add loading state handling
  - _Requirements: 1.4, 1.5, 2.2, 2.3, 7.1, 7.2, 7.5_

- [x] 4. Create Riverpod providers

  - Create `lib/presentation/providers/profile_providers.dart`
  - Add `profileRepositoryProvider` for repository instance
  - Add `profileNotifierProvider` family for user-specific state
  - Add `syncStatusProvider` for sync status monitoring
  - Wire up dependencies (SharedPreferences, Supabase)
  - _Requirements: 7.4, 7.5_

-

- [x] 5. Implement survey completion handler

  - Create `lib/services/survey_completion_handler.dart`
  - Implement `completeSurvey()` method
  - Add survey data to profile conversion logic
  - Implement local save on survey completion
  - Implement backend sync attempt
  - Add error handling for sync failures
  - Clear survey state after successful save
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 6. Update survey screens to save data

  - [x] 6.1 Update survey_daily_targets_screen.dart

    - Import survey completion handler
    - Call handler on "COMPLETE & START APP" button
    - Show loading indicator during save
    - Handle save errors gracefully
    - Navigate to dashboard only after successful save
    - _Requirements: 1.1, 1.2, 2.1_

  - [x] 6.2 Add incremental saves to survey screens

    - Update survey_basic_info_screen.dart to save on continue
    - Update survey_body_measurements_screen.dart to save on continue
    - Update survey_activity_goals_screen.dart to save on continue
    - Ensure data persists if user navigates away
    - _Requirements: 1.1, 1.2_

-

- [x] 7. Update Profile Screen to display onboarding data

  - [x] 7.1 Update ProfileTab widget

    - Import ProfileNotifier and watch profile state
    - Add loading state UI (skeleton or spinner)
    - Add error state UI with retry button
    - Add empty state UI prompting to complete onboarding
    - _Requirements: 3.1, 3.2, 3.3_

  - [x] 7.2 Create ProfileView widget

    - Display user name in header
    - Display age (calculated from birthday or direct)
    - Display gender
    - Display height with unit
    - Display weight with unit
    - Display activity level
    - Display fitness goals as chips/tags
    - Display daily targets (calories, steps, minutes, water)
    - _Requirements: 3.4, 3.5_

  - [x] 7.3 Update profile info items

    - Replace hardcoded values with profile data
    - Update \_buildInfoItem to show actual data
    - Add "Not set" placeholder for missing fields
    - Format values appropriately (units, decimals)
    - _Requirements: 3.4_

- [x] 8. Implement profile editing functionality

  - [x] 8.1 Create edit profile screen

    - Create `lib/screens/profile/edit_profile_screen.dart`
    - Add form fields for all editable profile data
    - Pre-populate fields with current values
    - Add validation for each field
    - _Requirements: 4.1, 4.2_

- - [x] 8.2 Implement save logic

    - Save to local storage on form submit
    - Attempt backend sync after local save
    - Show success message on save
    - Show error message if save fails
    - Navigate back to profile on success
    - _Requirements: 4.3, 4.4_

  - [x] 8.3 Add edit buttons to profile screen

    - Add edit icon button to profile header
    - Add edit buttons to individual sections
    - Navigate to edit screen on tap
    - Pass current profile data to edit screen
    - _Requirements: 4.1, 4.5_

- [x] 9. Create Supabase table and RLS policies

  - Create migration file for user_profiles table
  - Add all profile columns with appropriate types
  - Add constraints (age range, enum values)
  - Create RLS policies for select, insert, update
  - Test policies with different user scenarios
  - _Requirements: 2.1, 2.2_

- [x] 10. Implement offline sync queue

  - Create `lib/services/sync_queue_service.dart`
  - Implement queue for pending profile updates
  - Add connectivity listener to trigger sync
  - Implement retry logic with exponential backoff
  - Persist queue to local storage
  - _Requirements: 6.2, 6.3, 6.4_

- [x] 11. Add sync status indicators

  - Add sync status badge to profile screen
  - Show "Synced" when data is up-to-date
  - Show "Syncing..." when sync in progress
  - Show "Pending sync" when offline
  - Add manual sync button
  - _Requirements: 6.5_

- [x] 12. Implement data consistency checks

  - Add listener to profile notifier in all relevant screens
  - Update UI when profile data changes
  - Ensure survey screens reflect profile data if returning
  - Add refresh mechanism for profile screen
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 13. Add error handling and logging

  - Add try-catch blocks to all async operations
  - Log errors to console/analytics
  - Show user-friendly error messages
  - Add retry mechanisms for transient errors
  - Handle edge cases (null data, invalid formats)
  - _Requirements: 1.3, 2.3, 5.5_

- [x] 14. Write unit tests

  - Test UserProfile model serialization
  - Test ProfileRepository local operations
  - Test ProfileRepository backend operations
  - Test ProfileNotifier state transitions
  - Test survey completion handler
  - _Requirements: All_

- [x] 15. Write integration tests

  - Test complete onboarding flow → profile creation
  - Test profile data display in profile screen
  - Test profile editing flow
  - Test offline mode behavior
  - Test sync on connectivity restore
  - _Requirements: All_

-

- [x] 16. Manual testing and polish

  - Test complete user journey (signup → onboarding → profile)
  - Test editing profile fields
  - Test offline mode
  - Test error scenarios
  - Verify data persistence across app restarts
  - Polish UI/UX based on testing feedback
  - _Requirements: All_
