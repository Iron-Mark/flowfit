# Profile-Onboarding Integration Spec Summary

## Overview

This spec defines a comprehensive solution for integrating onboarding survey data with the user profile system, implementing an offline-first architecture with local storage fallback and backend synchronization.

---

## Key Features

### 1. Offline-First Architecture

- Local storage (SharedPreferences) as primary data source
- Backend (Supabase) for cloud sync and backup
- Automatic sync when connectivity restored
- Works seamlessly offline

### 2. Data Flow

```
Survey → Local Storage → Backend → Profile Screen
         (immediate)     (async)    (reactive)
```

### 3. Profile Management

- View all onboarding data in profile screen
- Edit profile fields with validation
- Real-time updates across all screens
- Persistent storage across app restarts

### 4. Sync Strategy

- Save locally first (fast, reliable)
- Sync to backend asynchronously
- Queue changes when offline
- Last-write-wins conflict resolution

---

## Requirements Summary

| Category        | Requirements                                            | Status     |
| --------------- | ------------------------------------------------------- | ---------- |
| Local Storage   | Save data locally, load on startup, handle errors       | ✅ Defined |
| Backend Sync    | Sync to Supabase, retry on failure, conflict resolution | ✅ Defined |
| Profile Display | Show all data, loading states, error handling           | ✅ Defined |
| Profile Editing | Edit fields, validate, save locally + backend           | ✅ Defined |
| Data Migration  | Survey → Profile conversion, handle schema changes      | ✅ Defined |
| Offline Support | Work offline, queue sync, auto-sync when online         | ✅ Defined |
| Consistency     | Single source of truth, reactive updates                | ✅ Defined |

---

## Architecture Components

### Core Models

- **UserProfile**: Unified data model with all profile fields
- **SyncStatus**: Enum for sync state (synced, syncing, pending, error)

### Repositories

- **ProfileRepository**: Abstract interface for data operations
- **ProfileRepositoryImpl**: Concrete implementation with local + backend

### State Management

- **ProfileNotifier**: Riverpod notifier for profile state
- **Providers**: Riverpod providers for dependency injection

### Services

- **SurveyCompletionHandler**: Migrates survey data to profile
- **SyncQueueService**: Manages offline sync queue

### UI Components

- **ProfileTab**: Updated to display profile data
- **ProfileView**: Widget to show profile information
- **EditProfileScreen**: Screen for editing profile fields

---

## Data Schema

### UserProfile Fields

```dart
{
  userId: String (UUID)
  fullName: String?
  age: int?
  gender: String? (male|female|other)
  height: double?
  weight: double?
  heightUnit: String? (cm|ft)
  weightUnit: String? (kg|lbs)
  activityLevel: String?
  goals: List<String>?
  dailyCalorieTarget: int?
  dailyStepsTarget: int?
  dailyActiveMinutesTarget: int?
  dailyWaterTarget: double?
  profileImagePath: String?
  createdAt: DateTime
  updatedAt: DateTime
  isSynced: bool
}
```

### Supabase Table

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  full_name TEXT,
  age INTEGER CHECK (age >= 13 AND age <= 120),
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  height DECIMAL(5,2),
  weight DECIMAL(5,2),
  height_unit TEXT,
  weight_unit TEXT,
  activity_level TEXT,
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
```

---

## Implementation Phases

### Phase 1: Core Infrastructure (Tasks 1-4)

- Create UserProfile model
- Implement ProfileRepository
- Create ProfileNotifier
- Set up Riverpod providers

**Deliverable**: Working local storage for profile data

### Phase 2: Survey Integration (Tasks 5-6)

- Implement survey completion handler
- Update survey screens to save data
- Add incremental saves

**Deliverable**: Onboarding data saved to profile

### Phase 3: Profile Screen (Tasks 7)

- Update ProfileTab to use ProfileNotifier
- Display all profile fields
- Add loading/error states

**Deliverable**: Profile screen shows onboarding data

### Phase 4: Profile Editing (Task 8)

- Create edit profile screen
- Implement save logic
- Add edit buttons

**Deliverable**: Users can edit their profile

### Phase 5: Backend Integration (Tasks 9-11)

- Create Supabase table
- Implement backend sync
- Add sync status indicators

**Deliverable**: Data synced to cloud

### Phase 6: Polish & Testing (Tasks 12-16)

- Add data consistency checks
- Implement error handling
- Write tests
- Manual testing

**Deliverable**: Production-ready feature

---

## Key Design Decisions

### 1. Why Offline-First?

- **Better UX**: No loading spinners, instant feedback
- **Reliability**: Works without internet
- **Performance**: Faster perceived speed
- **Resilience**: Handles network issues gracefully

### 2. Why SharedPreferences?

- **Simple**: Key-value storage, easy to use
- **Fast**: Quick read/write operations
- **Built-in**: No external dependencies
- **Sufficient**: Profile data is small

### 3. Why Last-Write-Wins?

- **Simple**: Easy to implement and understand
- **Practical**: Rare conflicts in single-user app
- **User-friendly**: Matches user expectations
- **Extensible**: Can enhance later if needed

### 4. Why Separate Profile from Auth?

- **Separation of Concerns**: Auth handles authentication, Profile handles data
- **Testability**: Easier to test independently
- **Maintainability**: Clear boundaries
- **Flexibility**: Can change one without affecting the other

---

## Testing Strategy

### Unit Tests

- UserProfile model (serialization, validation)
- ProfileRepository (local, backend, sync)
- ProfileNotifier (state transitions)
- SurveyCompletionHandler (data migration)

### Integration Tests

- Onboarding → Profile flow
- Profile editing flow
- Offline mode behavior
- Sync on connectivity restore

### Manual Tests

- Complete user journey
- Edit profile fields
- Offline scenarios
- Error handling
- Data persistence

---

## Success Criteria

✅ **Functional**

- Onboarding data saved locally
- Data synced to backend
- Profile screen displays data
- Users can edit profile
- Works offline

✅ **Non-Functional**

- Fast (< 100ms local operations)
- Reliable (no data loss)
- Consistent (single source of truth)
- Maintainable (clean architecture)
- Testable (good test coverage)

---

## Future Enhancements

1. **Profile Image Upload**: Store images in Supabase Storage
2. **Profile History**: Track changes over time
3. **Data Export**: Allow users to download their data
4. **Profile Sharing**: Share profile with friends/trainers
5. **Advanced Sync**: Operational transformation for conflicts
6. **Profile Completion**: Track and show completion percentage
7. **Profile Badges**: Achievements based on profile data
8. **Profile Analytics**: Insights from profile data

---

## Dependencies

### Existing

- `flutter_riverpod`: State management
- `shared_preferences`: Local storage
- `supabase_flutter`: Backend integration

### New (if needed)

- `connectivity_plus`: Network connectivity monitoring
- `hive`: Alternative to SharedPreferences (if needed)

---

## Risks & Mitigation

| Risk                       | Impact | Mitigation                            |
| -------------------------- | ------ | ------------------------------------- |
| Data loss during migration | High   | Comprehensive error handling, logging |
| Sync conflicts             | Medium | Last-write-wins, timestamp comparison |
| Backend unavailable        | Medium | Offline-first architecture, queue     |
| Schema changes             | Medium | Migration logic, versioning           |
| Performance issues         | Low    | Local-first, async operations         |

---

## Timeline Estimate

- **Phase 1**: 2-3 days (Core infrastructure)
- **Phase 2**: 1-2 days (Survey integration)
- **Phase 3**: 1-2 days (Profile display)
- **Phase 4**: 2-3 days (Profile editing)
- **Phase 5**: 2-3 days (Backend integration)
- **Phase 6**: 2-3 days (Testing & polish)

**Total**: 10-16 days (2-3 weeks)

---

## Next Steps

1. Review and approve this spec
2. Start with Phase 1 (Core Infrastructure)
3. Implement tasks sequentially
4. Test after each phase
5. Iterate based on feedback

---

## Documentation

All documentation is in `.kiro/specs/profile-onboarding-integration/`:

- `requirements.md`: Detailed requirements with acceptance criteria
- `design.md`: Architecture, components, and implementation details
- `tasks.md`: Step-by-step implementation plan
- `SPEC_SUMMARY.md`: This document

---

**Spec Created**: November 27, 2025  
**Status**: ✅ READY FOR IMPLEMENTATION  
**Approach**: Spec-Driven Development
