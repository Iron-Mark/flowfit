# Manual Testing Checklist - Profile Onboarding Integration

This document provides a comprehensive testing checklist for the Profile Onboarding Integration feature. Follow each test scenario to verify the implementation meets all requirements.

## Test Environment Setup

Before starting, ensure:

- [ ] Flutter app is built and running on a test device/emulator
- [ ] Supabase backend is configured and accessible
- [ ] Test user accounts are available
- [ ] Network connectivity can be toggled (airplane mode or network settings)

---

## 1. Complete User Journey (Signup → Onboarding → Profile)

### Test Case 1.1: New User Complete Flow

**Requirements: 1.1, 1.2, 2.1, 5.1, 5.2, 5.3, 5.4**

**Steps:**

1. [ ] Launch the app
2. [ ] Navigate to signup screen
3. [ ] Create a new account with email and password
4. [ ] Verify email if required
5. [ ] Complete onboarding survey:
   - [ ] Step 1: Basic Info (name, age, gender)
   - [ ] Step 2: Body Measurements (height, weight, units)
   - [ ] Step 3: Activity Goals (activity level, fitness goals)
   - [ ] Step 4: Daily Targets (calories, steps, minutes, water)
6. [ ] Click "COMPLETE & START APP" button
7. [ ] Verify loading indicator appears during save
8. [ ] Verify success message: "✅ Profile saved successfully!"
9. [ ] Verify navigation to dashboard
10. [ ] Navigate to Profile tab
11. [ ] Verify all onboarding data is displayed correctly

**Expected Results:**

- ✅ All survey data is saved locally
- ✅ All survey data is synced to backend
- ✅ Profile screen displays all entered information
- ✅ No data loss during the flow
- ✅ Smooth transitions between screens

**Notes:**
_Record any issues, unexpected behavior, or UI/UX improvements needed_

---

### Test Case 1.2: Returning User Flow

**Requirements: 7.3**

**Steps:**

1. [ ] Complete Test Case 1.1 first
2. [ ] Close the app completely
3. [ ] Reopen the app
4. [ ] Login with the same credentials
5. [ ] Navigate to Profile tab
6. [ ] Verify all profile data is still present

**Expected Results:**

- ✅ Profile data persists across app restarts
- ✅ No need to re-enter onboarding data
- ✅ Data loads quickly from local storage

---

## 2. Profile Data Display

### Test Case 2.1: Profile Screen Data Verification

**Requirements: 3.1, 3.2, 3.3, 3.4, 3.5**

**Steps:**

1. [ ] Navigate to Profile tab
2. [ ] Verify the following sections are displayed:
   - [ ] Profile Header with avatar and name
   - [ ] Personal Information section
   - [ ] Fitness Goals section (if goals were selected)
   - [ ] Daily Targets section
   - [ ] Account section
3. [ ] Verify each field displays correct data:
   - [ ] Full Name
   - [ ] Age (calculated or direct)
   - [ ] Gender
   - [ ] Height with unit (cm/ft)
   - [ ] Weight with unit (kg/lbs)
   - [ ] Activity Level
   - [ ] Fitness Goals (as chips/tags)
   - [ ] Daily Calorie Target
   - [ ] Daily Steps Target
   - [ ] Daily Active Minutes Target
   - [ ] Daily Water Target
4. [ ] Verify "Not set" placeholder for any missing fields
5. [ ] Verify sync status badge (Synced/Pending)

**Expected Results:**

- ✅ All data displays correctly formatted
- ✅ Units are shown appropriately
- ✅ Missing fields show "Not set"
- ✅ UI is clean and readable

---

### Test Case 2.2: Loading States

**Requirements: 3.2**

**Steps:**

1. [ ] Clear app data/cache
2. [ ] Login to the app
3. [ ] Navigate to Profile tab immediately
4. [ ] Observe loading state
5. [ ] Wait for profile to load

**Expected Results:**

- ✅ Loading indicator appears while fetching data
- ✅ Loading message is displayed
- ✅ No blank screen or errors during load
- ✅ Smooth transition from loading to data display

---

### Test Case 2.3: Empty State

**Requirements: 3.3**

**Steps:**

1. [ ] Create a new account
2. [ ] Skip onboarding (if possible) or login before completing onboarding
3. [ ] Navigate to Profile tab
4. [ ] Observe empty state

**Expected Results:**

- ✅ Empty state message displayed
- ✅ Prompt to complete onboarding shown
- ✅ Button to start onboarding is present
- ✅ No crash or error

---

## 3. Profile Editing Functionality

### Test Case 3.1: Edit Profile - Basic Fields

**Requirements: 4.1, 4.2, 4.3, 4.4, 4.5**

**Steps:**

1. [ ] Navigate to Profile tab
2. [ ] Click edit icon button in profile header
3. [ ] Verify navigation to Edit Profile screen
4. [ ] Verify all fields are pre-populated with current values
5. [ ] Edit the following fields:
   - [ ] Full Name
   - [ ] Age
   - [ ] Gender
   - [ ] Height
   - [ ] Weight
6. [ ] Click Save button
7. [ ] Verify success message appears
8. [ ] Verify navigation back to Profile screen
9. [ ] Verify updated values are displayed

**Expected Results:**

- ✅ Edit screen opens correctly
- ✅ All fields are editable
- ✅ Validation works for each field
- ✅ Changes are saved locally immediately
- ✅ Changes are synced to backend
- ✅ Profile screen reflects updates

---

### Test Case 3.2: Edit Profile - Daily Targets

**Requirements: 4.1, 4.2, 4.3, 4.4**

**Steps:**

1. [ ] Navigate to Profile tab
2. [ ] Click edit button in Daily Targets section
3. [ ] Edit daily targets:
   - [ ] Calorie target
   - [ ] Steps target
   - [ ] Active minutes target
   - [ ] Water target
4. [ ] Save changes
5. [ ] Verify updates are reflected

**Expected Results:**

- ✅ Daily targets can be edited
- ✅ Changes save successfully
- ✅ Profile displays updated targets

---

### Test Case 3.3: Edit Profile - Cancel Changes

**Requirements: 4.5**

**Steps:**

1. [ ] Navigate to Edit Profile screen
2. [ ] Make changes to several fields
3. [ ] Click Cancel or Back button
4. [ ] Return to Profile screen
5. [ ] Verify original values are still displayed

**Expected Results:**

- ✅ Changes are discarded
- ✅ Original values remain unchanged
- ✅ No data corruption

---

### Test Case 3.4: Edit Profile - Validation

**Requirements: 4.2**

**Steps:**

1. [ ] Navigate to Edit Profile screen
2. [ ] Try to enter invalid data:
   - [ ] Empty name
   - [ ] Age < 13 or > 120
   - [ ] Negative height/weight
   - [ ] Invalid units
3. [ ] Attempt to save
4. [ ] Verify validation errors are shown

**Expected Results:**

- ✅ Validation prevents invalid data
- ✅ Clear error messages displayed
- ✅ Save button disabled or shows error
- ✅ User can correct and retry

---

## 4. Offline Mode Testing

### Test Case 4.1: Complete Onboarding Offline

**Requirements: 1.1, 1.2, 1.3, 6.1, 6.2, 6.4**

**Steps:**

1. [ ] Enable airplane mode or disable network
2. [ ] Create a new account (may need to do this online first)
3. [ ] Complete onboarding survey
4. [ ] Click "COMPLETE & START APP"
5. [ ] Verify appropriate message about offline save
6. [ ] Navigate to Profile tab
7. [ ] Verify data is displayed (from local storage)
8. [ ] Verify "Pending sync" badge is shown
9. [ ] Re-enable network connection
10. [ ] Wait for auto-sync or trigger manual sync
11. [ ] Verify "Synced" badge appears

**Expected Results:**

- ✅ Onboarding completes successfully offline
- ✅ Data is saved to local storage
- ✅ User-friendly message about offline mode
- ✅ Profile displays local data
- ✅ Auto-sync occurs when online
- ✅ Sync status updates correctly

---

### Test Case 4.2: Edit Profile Offline

**Requirements: 6.1, 6.2, 6.3, 6.4**

**Steps:**

1. [ ] Navigate to Profile tab while online
2. [ ] Enable airplane mode
3. [ ] Edit profile fields
4. [ ] Save changes
5. [ ] Verify changes are saved locally
6. [ ] Verify "Pending sync" indicator appears
7. [ ] Re-enable network
8. [ ] Verify auto-sync occurs
9. [ ] Verify sync status updates to "Synced"

**Expected Results:**

- ✅ Edits work offline
- ✅ Local save succeeds
- ✅ Pending sync indicator shown
- ✅ Auto-sync on reconnection
- ✅ No data loss

---

### Test Case 4.3: Manual Sync

**Requirements: 6.5**

**Steps:**

1. [ ] Make profile changes offline
2. [ ] Verify "Pending sync" status
3. [ ] Re-enable network
4. [ ] Click "Sync Now" button (if available)
5. [ ] Observe sync progress
6. [ ] Verify sync completes successfully

**Expected Results:**

- ✅ Manual sync button is visible when needed
- ✅ Sync progress is indicated
- ✅ Success feedback is shown
- ✅ Status updates to "Synced"

---

### Test Case 4.4: Sync Queue Persistence

**Requirements: 6.2, 6.3, 6.4**

**Steps:**

1. [ ] Make multiple profile edits offline
2. [ ] Close the app completely
3. [ ] Reopen the app (still offline)
4. [ ] Verify pending sync indicator
5. [ ] Re-enable network
6. [ ] Verify all changes sync

**Expected Results:**

- ✅ Sync queue persists across app restarts
- ✅ All pending changes are synced
- ✅ No data loss

---

## 5. Error Scenarios

### Test Case 5.1: Backend Unavailable During Onboarding

**Requirements: 1.3, 2.3, 5.5**

**Steps:**

1. [ ] Simulate backend unavailability (disconnect Supabase or use invalid URL)
2. [ ] Complete onboarding survey
3. [ ] Click "COMPLETE & START APP"
4. [ ] Observe error handling
5. [ ] Verify user-friendly error message
6. [ ] Verify data is saved locally
7. [ ] Verify user can still access the app

**Expected Results:**

- ✅ Graceful error handling
- ✅ User-friendly error message
- ✅ Local save succeeds
- ✅ App doesn't crash
- ✅ User can continue using app

---

### Test Case 5.2: Network Timeout

**Requirements: 2.3, 5.5**

**Steps:**

1. [ ] Simulate slow network (use network throttling)
2. [ ] Complete onboarding or edit profile
3. [ ] Observe timeout handling
4. [ ] Verify appropriate timeout message
5. [ ] Verify retry option is available

**Expected Results:**

- ✅ Timeout is handled gracefully
- ✅ Clear timeout message shown
- ✅ Retry option available
- ✅ Local data is preserved

---

### Test Case 5.3: Invalid Data Format

**Requirements: 5.5**

**Steps:**

1. [ ] (This may require developer tools to inject invalid data)
2. [ ] Attempt to load profile with corrupted local data
3. [ ] Observe error handling
4. [ ] Verify app doesn't crash
5. [ ] Verify user can recover (re-enter data or fetch from backend)

**Expected Results:**

- ✅ Invalid data is detected
- ✅ Error is logged
- ✅ App doesn't crash
- ✅ Recovery path exists

---

### Test Case 5.4: Concurrent Edits (Conflict Resolution)

**Requirements: 2.4, 2.5**

**Steps:**

1. [ ] Login on Device A
2. [ ] Login on Device B with same account
3. [ ] Edit profile on Device A, save
4. [ ] Edit different fields on Device B, save
5. [ ] Verify both devices sync
6. [ ] Verify last-write-wins conflict resolution

**Expected Results:**

- ✅ Both edits are saved locally
- ✅ Last edit wins on backend
- ✅ Devices eventually sync to same state
- ✅ No data corruption

---

## 6. Data Persistence Across App Restarts

### Test Case 6.1: Profile Data Persistence

**Requirements: 1.4, 7.3**

**Steps:**

1. [ ] Complete onboarding
2. [ ] Close app completely (force stop)
3. [ ] Reopen app
4. [ ] Navigate to Profile tab
5. [ ] Verify all data is present

**Expected Results:**

- ✅ All profile data persists
- ✅ Data loads from local storage
- ✅ No re-fetch required

---

### Test Case 6.2: Sync Queue Persistence

**Requirements: 6.2, 6.3**

**Steps:**

1. [ ] Make edits offline
2. [ ] Verify pending sync
3. [ ] Close app
4. [ ] Reopen app (still offline)
5. [ ] Verify pending sync indicator still shows
6. [ ] Go online
7. [ ] Verify sync completes

**Expected Results:**

- ✅ Sync queue persists
- ✅ Pending changes are not lost
- ✅ Sync completes after restart

---

## 7. UI/UX Polish

### Test Case 7.1: Visual Consistency

**Steps:**

1. [ ] Review all screens in the flow:
   - [ ] Survey screens
   - [ ] Profile screen
   - [ ] Edit profile screen
2. [ ] Check for:
   - [ ] Consistent colors
   - [ ] Consistent fonts
   - [ ] Consistent spacing
   - [ ] Consistent button styles
   - [ ] Consistent icons

**Expected Results:**

- ✅ Visual consistency across all screens
- ✅ Follows app design system
- ✅ Professional appearance

---

### Test Case 7.2: Animations and Transitions

**Steps:**

1. [ ] Navigate through the complete flow
2. [ ] Observe all transitions:
   - [ ] Screen transitions
   - [ ] Loading states
   - [ ] Success/error messages
   - [ ] Button press feedback
3. [ ] Check for smooth animations

**Expected Results:**

- ✅ Smooth transitions
- ✅ No jarring animations
- ✅ Appropriate loading indicators
- ✅ Good user feedback

---

### Test Case 7.3: Accessibility

**Steps:**

1. [ ] Enable screen reader
2. [ ] Navigate through profile screens
3. [ ] Verify all elements are accessible
4. [ ] Check touch target sizes (minimum 48x48dp)
5. [ ] Test with different font sizes

**Expected Results:**

- ✅ All elements have proper labels
- ✅ Touch targets are adequate
- ✅ Works with screen reader
- ✅ Scales with font size

---

### Test Case 7.4: Error Messages

**Steps:**

1. [ ] Trigger various error scenarios
2. [ ] Review all error messages for:
   - [ ] Clarity
   - [ ] Helpfulness
   - [ ] Tone (friendly, not technical)
   - [ ] Actionability (what can user do?)

**Expected Results:**

- ✅ Error messages are user-friendly
- ✅ Messages provide clear guidance
- ✅ Technical jargon is avoided
- ✅ Recovery actions are suggested

---

### Test Case 7.5: Performance

**Steps:**

1. [ ] Complete onboarding flow
2. [ ] Measure time for:
   - [ ] Profile load time
   - [ ] Save operation time
   - [ ] Screen transitions
3. [ ] Test on low-end device if possible
4. [ ] Monitor for any lag or stuttering

**Expected Results:**

- ✅ Profile loads in < 1 second (from local)
- ✅ Save operations feel instant
- ✅ No noticeable lag
- ✅ Smooth on low-end devices

---

## 8. Edge Cases

### Test Case 8.1: Very Long Names

**Steps:**

1. [ ] Enter a very long name (50+ characters)
2. [ ] Save and view in profile
3. [ ] Verify text doesn't overflow
4. [ ] Verify ellipsis or wrapping works

**Expected Results:**

- ✅ Long names are handled gracefully
- ✅ No UI breaking
- ✅ Text is readable

---

### Test Case 8.2: Special Characters

**Steps:**

1. [ ] Enter names with special characters (é, ñ, 中文, etc.)
2. [ ] Save and verify display
3. [ ] Verify sync to backend works

**Expected Results:**

- ✅ Special characters are supported
- ✅ Display correctly
- ✅ Sync correctly

---

### Test Case 8.3: Extreme Values

**Steps:**

1. [ ] Enter extreme but valid values:
   - [ ] Age: 13 (minimum)
   - [ ] Age: 120 (maximum)
   - [ ] Height: very tall/short
   - [ ] Weight: very heavy/light
2. [ ] Verify calculations still work
3. [ ] Verify display is correct

**Expected Results:**

- ✅ Extreme values are handled
- ✅ Calculations are correct
- ✅ No crashes or errors

---

## 9. Integration Points

### Test Case 9.1: Profile Data in Home Screen

**Requirements: 7.1, 7.2**

**Steps:**

1. [ ] Complete onboarding
2. [ ] Navigate to Home tab
3. [ ] Verify user name appears in greeting
4. [ ] Edit profile name
5. [ ] Return to Home tab
6. [ ] Verify name is updated

**Expected Results:**

- ✅ Profile data is used in Home screen
- ✅ Updates reflect immediately
- ✅ Data consistency across tabs

---

### Test Case 9.2: Daily Targets Integration

**Steps:**

1. [ ] Set daily targets in onboarding
2. [ ] Navigate to Track/Progress tabs
3. [ ] Verify targets are used for progress calculations
4. [ ] Edit targets in profile
5. [ ] Verify updates reflect in other tabs

**Expected Results:**

- ✅ Daily targets are used app-wide
- ✅ Updates propagate correctly
- ✅ Calculations use correct values

---

## 10. Final Polish Checklist

### UI/UX Improvements Needed

- [ ] List any visual inconsistencies found
- [ ] List any confusing UI elements
- [ ] List any missing feedback/indicators
- [ ] List any performance issues

### Bug Fixes Required

- [ ] List all bugs found during testing
- [ ] Prioritize by severity (Critical/High/Medium/Low)
- [ ] Document steps to reproduce

### Feature Enhancements

- [ ] List any "nice to have" improvements
- [ ] List any missing features discovered during testing
- [ ] List any user experience improvements

---

## Test Summary

### Overall Assessment

- [ ] All critical paths work correctly
- [ ] No data loss scenarios
- [ ] Offline mode works as expected
- [ ] Error handling is robust
- [ ] UI/UX is polished and consistent
- [ ] Performance is acceptable
- [ ] Ready for production release

### Sign-off

- **Tester Name:** ******\_\_\_******
- **Date:** ******\_\_\_******
- **Status:** [ ] PASS [ ] FAIL [ ] NEEDS WORK
- **Notes:** ******\_\_\_******

---

## Next Steps

Based on testing results:

1. Document all issues found
2. Prioritize fixes
3. Implement fixes
4. Re-test affected areas
5. Final sign-off
