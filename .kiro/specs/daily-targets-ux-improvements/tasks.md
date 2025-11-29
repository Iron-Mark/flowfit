# Implementation Plan

- [x] 1. Update header styling to use primary blue color

  - Update Daily Targets Screen header title to use AppTheme.primaryBlue instead of Color(0xFF314158)
  - Update Body Measurements Screen header title to use AppTheme.primaryBlue instead of Color(0xFF314158)
  - Verify icon badge styling is consistent (primary blue background with 10% opacity)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 2. Create discrete slider helper methods

  - [x] 2.1 Implement \_findNearestOption helper method for snap-to-value logic

    - Create generic method that accepts value and list of options
    - Return the option closest to the given value
    - Support both int and double types
    - _Requirements: 1.4_

  - [x] 2.2 Implement \_buildDiscreteSliderSection for integer values

    - Accept icon, color, title, value, options, formatters, and callback parameters
    - Display section header with icon and title
    - Show large formatted value display
    - Render Flutter Slider with discrete divisions
    - Display tick mark labels below slider
    - Apply color theming to active track and thumb
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 2.3, 2.4, 2.5_

  - [x] 2.3 Implement \_buildDiscreteSliderSectionDouble for double values

    - Create variant that handles double values instead of integers
    - Use same visual design as integer version
    - Support decimal formatting in labels
    - _Requirements: 1.3, 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 3. Replace Steps Target section with discrete slider

  - Remove existing Row with icon and title
  - Remove \_buildProgressBar widget call
  - Remove Wrap widget with chip buttons
  - Replace with \_buildDiscreteSliderSection call
  - Pass stepsOptions [5000, 10000, 12000, 15000]
  - Format labels as "5K", "10K", "12K", "15K"
  - Format value display with comma separators
  - Use green color theme
  - _Requirements: 1.1, 4.1, 4.4, 5.1_

- [x] 4. Replace Active Minutes section with discrete slider

  - Remove existing Row with icon and title
  - Remove \_buildProgressBar widget call
  - Remove Wrap widget with chip buttons
  - Replace with \_buildDiscreteSliderSection call
  - Pass minutesOptions [20, 30, 45, 60]
  - Format labels as plain numbers
  - Format value display as "X minutes"
  - Use purple color theme
  - _Requirements: 1.2, 4.2, 4.4, 5.1_

- [x] 5. Replace Water Intake section with discrete slider

  - Remove existing Row with icon and title
  - Remove \_buildProgressBar widget call
  - Remove Wrap widget with chip buttons
  - Replace with \_buildDiscreteSliderSectionDouble call
  - Pass waterOptions [1.5, 2.0, 2.5, 3.0]
  - Format labels as "1.5L", "2.0L", "2.5L", "3.0L"
  - Format value display as "X.X liters"
  - Use blue color theme
  - _Requirements: 1.3, 4.3, 4.4, 5.1_

- [x] 6. Clean up unused helper methods

  - Remove \_buildProgressBar method (no longer used)
  - Remove \_buildQuickSelectChip method (no longer used)
  - Verify no other code references these methods
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 7. Verify functionality and navigation

  - Test slider interaction for all three sections
  - Verify values snap to predefined options
  - Confirm state updates immediately on slider change
  - Test back button navigation preserves values
  - Test forward navigation and submission
  - Verify calorie target card still works with adjust button
  - Confirm all values save correctly to survey state
  - Test complete submission flow to backend
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 8. Visual consistency verification

  - Compare header styling across all survey screens
  - Verify primary blue color is consistent
  - Check spacing and alignment
  - Test on different screen sizes
  - Validate touch targets are adequate
  - Confirm color theming for each section
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
