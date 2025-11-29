# Implementation Plan

- [x] 1. Set up Buddy data models and database schema

  - Create `BuddyProfile` model class with JSON serialization
  - Create `BuddyOnboardingState` model class with copyWith method
  - Write Supabase migration for `buddy_profiles` table with RLS policies
  - Add optional `nickname` and `is_kids_mode` columns to `user_profiles` table
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 2. Create reusable Buddy widgets

  - [x] 2.1 Implement `BuddyCharacterWidget` with blob shape rendering

    - Use CustomPaint or Container with BorderRadius for blob shape
    - Add dot eyes (8x8 circles), small beak/smile, and rosy cheeks (12x12 circles)
    - Support color prop and size prop
    - Add showFace toggle for future use
    - _Requirements: 10.1, 10.2, 7.2, 7.3_

  - [x] 2.2 Implement `BuddyEggWidget` for color selection

    - Create egg shape (oval with rounded bottom)
    - Add spotted pattern (3-4 darker spots)
    - Implement selection state with border/glow
    - Add tap animation (scale bounce)
    - _Requirements: 2.3_

  - [x] 2.3 Create `OnboardingButton` widget

    - Implement primary and secondary button styles
    - Use Primary Blue (#3B82F6) or green (#4CAF50) for primary
    - Set border radius to 12px, height to 56px
    - Add disabled state styling
    - _Requirements: 6.1, 10.5, 11.1_

- [x] 3. Implement Buddy animations

  - [x] 3.1 Create `BuddyIdleAnimation` widget

    - Implement 2-second loop with gentle bobbing motion
    - Use Transform.translate with 8px vertical movement
    - Apply easeInOut curve
    - Properly dispose animation controller
    - _Requirements: 9.1, 9.2, 9.3, 9.5_

  - [x] 3.2 Create `BuddyCelebrationAnimation` widget

    - Implement 1-second jump animation with scale and rotation
    - Use TweenSequence for jump (-50px up, back to 0)
    - Add scale animation (1.0 → 1.2 → 1.0)
    - Add subtle rotation with elasticOut curve
    - _Requirements: 5.1, 9.1, 9.2, 9.3, 9.5_

  - [x] 3.3 Add egg selection tap animation

    - Implement 200ms scale bounce on tap
    - Add haptic feedback (lightImpact)
    - Ensure smooth animation performance
    - _Requirements: 9.1, 9.2, 9.3_

- [x] 4. Set up state management

  - Create `BuddyOnboardingNotifier` extending StateNotifier
  - Implement `selectColor`, `setBuddyName`, `setUserInfo` methods
  - Add `validateBuddyName` method (1-20 characters, not empty)
  - Implement `completeOnboarding` method to save to Supabase
  - Create `buddyOnboardingProvider` StateNotifierProvider
  - _Requirements: 8.1, 8.2, 8.3, 3.4, 3.5_

- [ ] 5. Implement BuddyWelcomeScreen

  - Create stateless screen with centered layout
  - Add BuddyCharacterWidget in Ocean Blue with idle animation
  - Display large heading "Buddy" or "Meet Your Buddy!"
  - Add friendly tagline "Your new fitness best friend"
  - Include FlowFit logo in header
  - Add primary button "Meet Your Buddy" navigating to color selection
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 10.3, 10.4_

- [x] 6. Implement BuddyColorSelectionScreen

  - [x] 6.1 Create screen layout with heading and subtitle

    - Add heading "Choose your Buddy!"
    - Add descriptive subtitle about Buddy's personality
    - Use clean white background with ample whitespace
    - _Requirements: 2.1, 10.3, 10.4_

  - [x] 6.2 Implement color options layout

    - Create 8 BuddyEggWidget instances for colors (blue, teal, green, purple, yellow, orange, pink, gray)
    - Arrange in circular or scattered pattern around center
    - Add 16px minimum spacing between eggs
    - _Requirements: 2.2, 7.4, 11.2_

  - [x] 6.3 Add central Buddy preview

    - Display BuddyCharacterWidget in neutral/gray color
    - Update preview color when egg is selected
    - Add smooth color transition animation
    - _Requirements: 2.4_

  - [x] 6.4 Implement selection logic

    - Connect to buddyOnboardingProvider
    - Call selectColor on egg tap
    - Highlight selected egg with border/glow
    - _Requirements: 2.5, 8.1_

  - [x] 6.5 Add confirmation button

    - Create green button labeled "Hatch egg"
    - Enable only when color is selected
    - Navigate to naming screen on tap
    - _Requirements: 2.6, 2.7_

-

- [x] 7. Implement BuddyNamingScreen

  - [x] 7.1 Create screen layout

    - Display BuddyCharacterWidget in selected color
    - Add prompt "What will you call your buddy?"
    - Use clean layout with centered elements
    - _Requirements: 3.1, 10.3_

  - [x] 7.2 Add name input field

    - Create large, friendly text input field
    - Set max length to 20 characters
    - Add placeholder text
    - Style with rounded border and padding
    - _Requirements: 3.2, 3.4, 11.5_

  - [x] 7.3 Display name suggestions

    - Show suggestions: "Sparky", "Flash", "Star", "Buddy", "Ace"
    - Make suggestions tappable to auto-fill
    - Style as chips or small buttons
    - _Requirements: 3.3_

  - [x] 7.4 Implement validation and confirmation

    - Validate name on input (1-20 characters, not empty)
    - Show validation errors in friendly language
    - Add "THAT'S PERFECT!" button
    - Save name to buddyOnboardingProvider
    - Navigate to profile setup screen
    - _Requirements: 3.4, 3.5, 3.6, 8.1_

- [ ] 8. Implement QuickProfileSetupScreen

  - [ ] 8.1 Create screen layout

    - Display Buddy with name in selected color
    - Add prompt "Tell [Buddy Name] about yourself!"
    - Use consistent spacing and layout
    - _Requirements: 4.1, 10.3_

  - [ ] 8.2 Add nickname input field

    - Create text input labeled "Your Nickname"
    - Make field optional
    - Style consistently with naming screen
    - _Requirements: 4.2, 11.5_

  - [ ] 8.3 Implement age selection

    - Create 6 age buttons for ages 7-12 (or adjust for general audience)
    - Style as rounded buttons in a row or grid
    - Highlight selected age
    - Make age optional
    - _Requirements: 4.3, 4.4, 11.1_

  - [ ] 8.4 Add navigation buttons
    - Create "SKIP" button (secondary style)
    - Create "CONTINUE" button (primary style)
    - Save data to buddyOnboardingProvider
    - Navigate to completion screen
    - _Requirements: 4.5, 4.6, 4.7, 8.2_

- [ ] 9. Implement BuddyCompletionScreen

  - Display Buddy with celebration animation
  - Show personalized message "[Buddy Name] wants to play!"
  - Add motivational text "Let's do your first challenge!"
  - Create "START FIRST MISSION" button
  - Call completeOnboarding on buddyOnboardingProvider
  - Navigate to dashboard or first activity
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 8.3_

- [ ] 10. Integrate with existing app

  - [ ] 10.1 Update route definitions in main.dart

    - Replace `/survey_intro` with BuddyWelcomeScreen
    - Add routes for all Buddy onboarding screens
    - Update navigation from signup to Buddy welcome
    - _Requirements: Integration_

  - [ ] 10.2 Create Supabase repository methods

    - Implement `saveBuddyProfile` method
    - Implement `getBuddyProfile` method
    - Implement `updateBuddyProfile` method
    - Add error handling for network failures
    - _Requirements: 8.3_

  - [ ] 10.3 Update user profile service
    - Add method to update nickname and is_kids_mode
    - Integrate with existing profile notifier
    - Ensure data consistency
    - _Requirements: 8.3_

- [ ] 11. Add error handling and validation

  - Implement friendly error messages for validation failures
  - Add network error handling with retry logic
  - Create offline mode support (save locally, sync later)
  - Add loading states for async operations
  - _Requirements: Error Handling section_

- [ ] 12. Implement accessibility features

  - Add Semantics labels to all interactive elements
  - Verify touch targets are minimum 48x48 pixels
  - Test color contrast ratios (minimum 4.5:1)
  - Add alternative text for Buddy character
  - Test with screen reader
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ] 13. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
