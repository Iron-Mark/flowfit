# Requirements Document

## Introduction

This specification defines the integration between onboarding survey data and the user profile screen. The goal is to ensure that data collected during onboarding is properly saved locally (as a fallback), persisted to the backend, and accurately reflected in the profile screen for viewing and editing.

## Glossary

- **Onboarding Survey**: The 4-step survey flow that collects user information (basic info, body measurements, activity goals, daily targets)
- **Profile Screen**: The user profile tab in the dashboard where users can view and edit their information
- **Local Storage**: Device-level data persistence using SharedPreferences or similar
- **Backend Storage**: Server-side data persistence using Supabase
- **Survey State**: Temporary state managed by `surveyNotifierProvider` during the onboarding flow
- **User Profile**: Persistent user data stored in `user_profiles` table
- **Fallback Storage**: Local storage used when backend is unavailable

## Requirements

### Requirement 1: Save Onboarding Data Locally

**User Story:** As a user completing the onboarding survey, I want my data saved locally on my device, so that I don't lose my information if there's a network issue.

#### Acceptance Criteria

1. WHEN the user completes each survey step, THE system SHALL save the data to local storage immediately
2. WHEN the user completes the final survey step, THE system SHALL persist all survey data to local storage before attempting backend sync
3. WHEN local storage save fails, THE system SHALL display an error message to the user
4. WHEN the app restarts, THE system SHALL load user profile data from local storage if available
5. WHEN local data exists, THE system SHALL use it as the source of truth until backend sync completes

### Requirement 2: Sync Onboarding Data to Backend

**User Story:** As a user, I want my profile data synced to the cloud, so that I can access it from any device and it's backed up securely.

#### Acceptance Criteria

1. WHEN the user completes the onboarding survey, THE system SHALL attempt to save all data to Supabase
2. WHEN backend sync succeeds, THE system SHALL update local storage with the backend response
3. WHEN backend sync fails, THE system SHALL keep local data and retry sync on next app launch
4. WHEN the user has internet connectivity, THE system SHALL automatically sync pending local changes to backend
5. WHEN backend data conflicts with local data, THE system SHALL use the most recently updated version

### Requirement 3: Display Profile Data in Profile Screen

**User Story:** As a user, I want to see my profile information in the profile tab, so that I can verify my data is correct.

#### Acceptance Criteria

1. WHEN the user navigates to the profile screen, THE system SHALL display all onboarding data fields
2. WHEN profile data is loading, THE system SHALL show loading indicators
3. WHEN no profile data exists, THE system SHALL show placeholder values or prompt to complete onboarding
4. WHEN profile data loads successfully, THE system SHALL display: name, age, gender, height, weight, activity level, goals, and daily targets
5. WHEN the user's profile image exists, THE system SHALL display it in the profile header

### Requirement 4: Enable Profile Data Editing

**User Story:** As a user, I want to edit my profile information, so that I can keep my data up-to-date as my goals change.

#### Acceptance Criteria

1. WHEN the user taps on an editable profile field, THE system SHALL navigate to an edit screen or show an edit dialog
2. WHEN the user updates a profile field, THE system SHALL validate the new value
3. WHEN validation passes, THE system SHALL save the updated value to local storage immediately
4. WHEN local save succeeds, THE system SHALL attempt to sync the change to backend
5. WHEN the user cancels editing, THE system SHALL discard changes and restore original values

### Requirement 5: Handle Data Migration from Survey to Profile

**User Story:** As a developer, I want a clear data migration path from survey state to profile storage, so that no data is lost during the transition.

#### Acceptance Criteria

1. WHEN the user completes the onboarding survey, THE system SHALL map all survey fields to profile fields
2. WHEN survey data is saved, THE system SHALL include metadata (timestamp, version, source)
3. WHEN profile data is loaded, THE system SHALL handle missing fields gracefully with default values
4. WHEN survey data structure changes, THE system SHALL migrate old data to new structure
5. WHEN data migration fails, THE system SHALL log the error and use safe defaults

### Requirement 6: Implement Offline-First Architecture

**User Story:** As a user with unreliable internet, I want the app to work offline, so that I can use it anywhere without connectivity issues.

#### Acceptance Criteria

1. WHEN the app is offline, THE system SHALL use local storage as the primary data source
2. WHEN the app comes online, THE system SHALL automatically sync local changes to backend
3. WHEN sync conflicts occur, THE system SHALL resolve them using last-write-wins strategy
4. WHEN the user makes changes offline, THE system SHALL queue them for sync when online
5. WHEN sync queue has pending changes, THE system SHALL show a sync status indicator

### Requirement 7: Maintain Data Consistency

**User Story:** As a user, I want my data to be consistent across all screens, so that I don't see conflicting information.

#### Acceptance Criteria

1. WHEN profile data is updated, THE system SHALL update all screens displaying that data
2. WHEN survey data is saved, THE system SHALL immediately reflect in profile screen
3. WHEN backend data is fetched, THE system SHALL update local cache and UI
4. WHEN multiple screens show the same data, THE system SHALL use a single source of truth
5. WHEN data changes, THE system SHALL notify all listeners via Riverpod state management
