# Quick Test Guide - Profile Onboarding Integration

This is a condensed testing guide for quickly verifying the core functionality of the Profile Onboarding Integration feature.

## Prerequisites

1. **Build and Run the App:**

   ```bash
   # For phone app
   flutter run -t lib/main.dart

   # Or use the provided script
   scripts\run_phone.bat
   ```

2. **Prepare Test Environment:**
   - Have a test device or emulator ready
   - Ensure Supabase backend is accessible
   - Have ability to toggle network (airplane mode)

---

## 🚀 Quick Test Scenarios (15-20 minutes)

### 1. Happy Path Test (5 min)

**Goal:** Verify the complete user journey works end-to-end

1. Launch app → Sign up with new account
2. Complete all 4 onboarding survey steps:
   - Basic Info: Enter name, age, gender
   - Body Measurements: Enter height, weight
   - Activity Goals: Select activity level and goals
   - Daily Targets: Review/adjust targets
3. Click "COMPLETE & START APP"
4. Verify success message and navigation to dashboard
5. Go to Profile tab
6. **✅ Verify:** All your onboarding data is displayed correctly

**Expected:** No errors, smooth flow, all data visible in profile

---

### 2. Edit Profile Test (3 min)

**Goal:** Verify profile editing works

1. In Profile tab, click edit icon (top right)
2. Change your name and age
3. Click Save
4. **✅ Verify:** Changes are reflected immediately in profile
5. Close and reopen app
6. **✅ Verify:** Changes persisted

**Expected:** Edits save successfully, data persists

---

### 3. Offline Mode Test (5 min)

**Goal:** Verify offline functionality

1. Enable airplane mode
2. Edit your profile (change weight or height)
3. Save changes
4. **✅ Verify:** "Pending sync" badge appears
5. Navigate away and back to profile
6. **✅ Verify:** Changes are still there (saved locally)
7. Disable airplane mode
8. Wait 5-10 seconds or click "Sync Now" if available
9. **✅ Verify:** "Synced" badge appears

**Expected:** Works offline, auto-syncs when online

---

### 4. Data Persistence Test (2 min)

**Goal:** Verify data survives app restart

1. Complete onboarding (if not already done)
2. Note your profile data
3. Force close the app completely
4. Reopen the app and login
5. Go to Profile tab
6. **✅ Verify:** All data is still there

**Expected:** No data loss after restart

---

### 5. Error Handling Test (3 min)

**Goal:** Verify graceful error handling

1. Try to edit profile with invalid data:
   - Empty name
   - Age = 5 (too young)
   - Negative weight
2. **✅ Verify:** Validation errors are shown
3. **✅ Verify:** Can't save invalid data
4. Correct the data and save
5. **✅ Verify:** Valid data saves successfully

**Expected:** Clear validation messages, no crashes

---

## 🔍 Visual Inspection Checklist (5 min)

Walk through the app and check:

### Profile Screen

- [ ] Profile header shows name and avatar
- [ ] Personal information section displays all fields
- [ ] Fitness goals shown as chips/tags
- [ ] Daily targets section shows all targets with units
- [ ] Sync badge visible (Synced/Pending)
- [ ] Edit button is accessible
- [ ] All text is readable and properly formatted

### Edit Profile Screen

- [ ] All fields are pre-populated
- [ ] Form fields are editable
- [ ] Save and Cancel buttons work
- [ ] Validation messages are clear
- [ ] Success message appears after save

### Survey Screens

- [ ] Progress indicator shows current step
- [ ] All input fields work correctly
- [ ] Navigation between steps works
- [ ] Final "COMPLETE & START APP" button works
- [ ] Loading indicator shows during save

---

## 🐛 Common Issues to Watch For

1. **Data Not Showing:**

   - Check if user completed onboarding
   - Check if profile loaded (loading state)
   - Check console for errors

2. **Sync Issues:**

   - Verify network connectivity
   - Check Supabase configuration
   - Look for sync status indicators

3. **Edit Not Saving:**

   - Check validation errors
   - Verify network for backend sync
   - Check local storage permissions

4. **App Crashes:**
   - Check console logs
   - Note exact steps to reproduce
   - Check for null pointer errors

---

## 📝 Quick Bug Report Template

If you find an issue, document it:

```
**Issue:** [Brief description]
**Severity:** [Critical/High/Medium/Low]
**Steps to Reproduce:**
1.
2.
3.

**Expected:** [What should happen]
**Actual:** [What actually happened]
**Screenshots:** [If applicable]
**Console Errors:** [If any]
```

---

## ✅ Sign-off Criteria

The feature is ready if:

- ✅ Complete user journey works without errors
- ✅ Profile displays all onboarding data correctly
- ✅ Profile editing works and persists
- ✅ Offline mode works (local save + auto-sync)
- ✅ Data persists across app restarts
- ✅ Error handling is graceful (no crashes)
- ✅ UI is polished and consistent
- ✅ No critical bugs found

---

## 🎯 Next Steps After Testing

1. **If all tests pass:**

   - Mark task as complete
   - Document any minor polish items for future
   - Proceed to next feature

2. **If issues found:**

   - Document all issues in detail
   - Prioritize by severity
   - Fix critical/high priority issues
   - Re-test after fixes

3. **For comprehensive testing:**
   - Use the full MANUAL_TESTING_CHECKLIST.md
   - Test all edge cases
   - Test on multiple devices
   - Test with different network conditions

---

## 📞 Need Help?

- Check console logs for errors
- Review implementation files in `lib/`
- Check Supabase dashboard for backend data
- Review requirements in `requirements.md`
- Review design in `design.md`
