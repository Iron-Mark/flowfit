# Design Document

## Overview

The Buddy Onboarding Flow transforms the existing FlowFit survey-based onboarding into an engaging, kid-friendly experience centered around a customizable companion pet called "Buddy". The design leverages Flutter's animation capabilities, maintains the existing Riverpod state management architecture, and integrates seamlessly with the current Supabase backend while introducing new data models for pet customization.

The flow consists of 5 screens that guide users through selecting a Buddy color (via an egg-hatching metaphor), naming their companion, and completing a minimal profile setup. The design prioritizes simplicity, gender-neutrality, and visual appeal inspired by successful self-care apps like Finch, while maintaining FlowFit's brand identity.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Welcome    │→ │Color Select  │→ │    Naming    │     │
│  │   Screen     │  │   Screen     │  │    Screen    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         ↓                  ↓                  ↓              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Profile    │→ │  Completion  │→ │  Dashboard   │     │
│  │   Setup      │  │   Screen     │  │              │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         BuddyOnboardingNotifier (Riverpod)           │  │
│  │  - Manages onboarding state                          │  │
│  │  - Validates user input                              │  │
│  │  - Coordinates data persistence                      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │  Survey State    │  │  Buddy Profile   │               │
│  │  (Temporary)     │  │  (Persistent)    │               │
│  └──────────────────┘  └──────────────────┘               │
│           ↓                      ↓                          │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │ SharedPreferences│  │    Supabase      │               │
│  └──────────────────┘  └──────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

### Integration with Existing Architecture

The Buddy onboarding flow integrates with FlowFit's existing architecture:

1. **State Management**: Uses existing `surveyNotifierProvider` pattern
2. **Navigation**: Replaces routes `/survey_intro` through `/survey_daily_targets`
3. **Data Persistence**: Extends existing profile system with Buddy-specific fields
4. **Theme**: Uses existing `AppTheme` constants for brand consistency

## Components and Interfaces

### Screen Components

#### 1. BuddyWelcomeScreen

**Purpose**: Initial welcome screen introducing the Buddy concept

**Key Elements**:

- Animated Buddy character (blob shape with simple features)
- Large heading with Buddy name
- Friendly tagline
- Primary action button ("Meet Your Buddy")
- FlowFit logo in header

**State**: Stateless (no user input)

**Navigation**: → BuddyColorSelectionScreen

#### 2. BuddyColorSelectionScreen

**Purpose**: Allow users to choose their Buddy's starting color via egg selection

**Key Elements**:

- Heading: "Choose your Buddy!"
- Descriptive subtitle about Buddy's personality
- 6-8 egg-shaped color options in circular/scattered layout
- Central Buddy preview (neutral/gray)
- Selection indicator (highlight/border)
- "Hatch egg" confirmation button

**State**:

- `selectedColor`: String (color key)
- `isAnimating`: bool (for selection feedback)

**Navigation**: → BuddyNamingScreen

**Color Options**:

```dart
{
  'blue': Color(0xFF4ECDC4),    // Ocean Blue (default)
  'teal': Color(0xFF26A69A),    // Calm Teal
  'green': Color(0xFF66BB6A),   // Fresh Green
  'purple': Color(0xFF9575CD),  // Soft Purple
  'yellow': Color(0xFFFFD54F),  // Gentle Yellow
  'orange': Color(0xFFFFB74D),  // Warm Orange
  'pink': Color(0xFFF06292),    // Happy Pink
  'gray': Color(0xFF90A4AE),    // Cool Gray
}
```

#### 3. BuddyNamingScreen

**Purpose**: Allow users to name their Buddy companion

**Key Elements**:

- Buddy character in selected color
- Prompt: "What will you call your buddy?"
- Large text input field
- Name suggestions (Sparky, Flash, Star, etc.)
- "THAT'S PERFECT!" confirmation button

**State**:

- `buddyName`: String
- `isValid`: bool

**Validation**:

- Length: 1-20 characters
- No special characters (optional)
- Not empty

**Navigation**: → QuickProfileSetupScreen

#### 4. QuickProfileSetupScreen

**Purpose**: Collect minimal user information (nickname and age)

**Key Elements**:

- Buddy character with name
- Prompt: "Tell [Buddy Name] about yourself!"
- Nickname input field
- Age selection buttons (7-12 for kids mode, or 13+ for general)
- "SKIP" and "CONTINUE" buttons

**State**:

- `userNickname`: String?
- `userAge`: int?

**Navigation**: → BuddyCompletionScreen

#### 5. BuddyCompletionScreen

**Purpose**: Celebrate onboarding completion and transition to main app

**Key Elements**:

- Animated Buddy (jumping/celebrating)
- Personalized message: "[Buddy Name] wants to play!"
- Motivational text: "Let's do your first challenge!"
- "START FIRST MISSION" button

**State**: Stateless

**Navigation**: → Dashboard or First Activity

### Reusable Widgets

#### BuddyCharacterWidget

**Purpose**: Render the Buddy character with consistent styling

**Props**:

```dart
class BuddyCharacterWidget extends StatelessWidget {
  final Color color;
  final double size;
  final BuddyAnimation animation;
  final bool showFace;

  const BuddyCharacterWidget({
    required this.color,
    this.size = 160.0,
    this.animation = BuddyAnimation.idle,
    this.showFace = true,
  });
}
```

**Rendering**:

- Blob/bean shape using `CustomPaint` or `Container` with `BorderRadius`
- Two dot eyes (8x8 circles)
- Small beak/smile (triangle or arc)
- Two rosy cheeks (12x12 circles with opacity)

#### BuddyEggWidget

**Purpose**: Render egg-shaped color options

**Props**:

```dart
class BuddyEggWidget extends StatelessWidget {
  final Color baseColor;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const BuddyEggWidget({
    required this.baseColor,
    required this.isSelected,
    required this.onTap,
    this.size = 80.0,
  });
}
```

**Rendering**:

- Egg shape (oval with rounded bottom)
- Spotted pattern (3-4 darker spots)
- Selection border/glow when selected
- Tap animation (scale bounce)

#### OnboardingButton

**Purpose**: Consistent button styling across onboarding screens

**Props**:

```dart
class OnboardingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color? customColor;

  const OnboardingButton({
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.customColor,
  });
}
```

**Styling**:

- Primary: Green (#4CAF50) or Primary Blue (#3B82F6)
- Secondary: Outlined with gray border
- Border radius: 12px
- Height: 56px
- Font: 16sp, semi-bold

## Data Models

### BuddyProfile

**Purpose**: Store Buddy customization and progression data

```dart
class BuddyProfile {
  final String id;
  final String userId;
  final String name;
  final String color;
  final int level;
  final int xp;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Future expansion
  final List<String> unlockedColors;
  final Map<String, dynamic>? accessories;

  BuddyProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.level = 1,
    this.xp = 0,
    required this.createdAt,
    required this.updatedAt,
    this.unlockedColors = const ['blue'],
    this.accessories,
  });

  factory BuddyProfile.fromJson(Map<String, dynamic> json) {
    return BuddyProfile(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      color: json['color'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      unlockedColors: List<String>.from(json['unlocked_colors'] ?? ['blue']),
      accessories: json['accessories'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'level': level,
      'xp': xp,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'unlocked_colors': unlockedColors,
      'accessories': accessories,
    };
  }
}
```

### BuddyOnboardingState

**Purpose**: Manage temporary onboarding data before profile creation

```dart
class BuddyOnboardingState {
  final String? selectedColor;
  final String? buddyName;
  final String? userNickname;
  final int? userAge;
  final bool isComplete;

  BuddyOnboardingState({
    this.selectedColor,
    this.buddyName,
    this.userNickname,
    this.userAge,
    this.isComplete = false,
  });

  BuddyOnboardingState copyWith({
    String? selectedColor,
    String? buddyName,
    String? userNickname,
    int? userAge,
    bool? isComplete,
  }) {
    return BuddyOnboardingState(
      selectedColor: selectedColor ?? this.selectedColor,
      buddyName: buddyName ?? this.buddyName,
      userNickname: userNickname ?? this.userNickname,
      userAge: userAge ?? this.userAge,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
```

## State Management

### BuddyOnboardingNotifier

**Purpose**: Manage onboarding flow state and validation

```dart
class BuddyOnboardingNotifier extends StateNotifier<BuddyOnboardingState> {
  BuddyOnboardingNotifier() : super(BuddyOnboardingState());

  void selectColor(String color) {
    state = state.copyWith(selectedColor: color);
  }

  void setBuddyName(String name) {
    state = state.copyWith(buddyName: name);
  }

  void setUserInfo(String? nickname, int? age) {
    state = state.copyWith(
      userNickname: nickname,
      userAge: age,
    );
  }

  String? validateBuddyName(String name) {
    if (name.isEmpty) return 'Please enter a name';
    if (name.length > 20) return 'Name must be 20 characters or less';
    return null;
  }

  Future<void> completeOnboarding(String userId) async {
    // Create Buddy profile
    final buddyProfile = BuddyProfile(
      id: uuid.v4(),
      userId: userId,
      name: state.buddyName!,
      color: state.selectedColor ?? 'blue',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Supabase
    await _saveBuddyProfile(buddyProfile);

    // Update user profile with nickname/age if provided
    if (state.userNickname != null || state.userAge != null) {
      await _updateUserProfile(userId, state.userNickname, state.userAge);
    }

    state = state.copyWith(isComplete: true);
  }
}

final buddyOnboardingProvider = StateNotifierProvider<BuddyOnboardingNotifier, BuddyOnboardingState>(
  (ref) => BuddyOnboardingNotifier(),
);
```

## Database Schema

### New Table: buddy_profiles

```sql
CREATE TABLE buddy_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT 'blue',
  level INT DEFAULT 1,
  xp INT DEFAULT 0,
  unlocked_colors TEXT[] DEFAULT ARRAY['blue'],
  accessories JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast user lookups
CREATE INDEX idx_buddy_profiles_user_id ON buddy_profiles(user_id);

-- RLS Policies
ALTER TABLE buddy_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own buddy profile"
  ON buddy_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own buddy profile"
  ON buddy_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own buddy profile"
  ON buddy_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);
```

### Modified Table: user_profiles

Add optional fields for kids mode:

```sql
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS nickname TEXT,
ADD COLUMN IF NOT EXISTS is_kids_mode BOOLEAN DEFAULT FALSE;
```

## Animations

### Buddy Idle Animation

**Type**: Continuous loop
**Duration**: 2 seconds
**Effect**: Gentle breathing/bobbing motion

```dart
class BuddyIdleAnimation extends StatefulWidget {
  final Widget child;

  @override
  _BuddyIdleAnimationState createState() => _BuddyIdleAnimationState();
}

class _BuddyIdleAnimationState extends State<BuddyIdleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Buddy Celebration Animation

**Type**: One-time
**Duration**: 1 second
**Effect**: Jump with scale and rotation

```dart
class BuddyCelebrationAnimation extends StatefulWidget {
  final Widget child;

  @override
  _BuddyCelebrationAnimationState createState() => _BuddyCelebrationAnimationState();
}

class _BuddyCelebrationAnimationState extends State<BuddyCelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _jumpAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _jumpAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -50.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -50.0, end: 0.0), weight: 50),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _jumpAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Egg Selection Animation

**Type**: On tap
**Duration**: 200ms
**Effect**: Scale bounce

```dart
void _onEggTap(String color) {
  setState(() {
    _selectedColor = color;
  });

  // Trigger haptic feedback
  HapticFeedback.lightImpact();

  // Animate selection
  _scaleController.forward().then((_) {
    _scaleController.reverse();
  });
}
```

## Error Handling

### Validation Errors

**Buddy Name Validation**:

- Empty name: "Please give your buddy a name!"
- Too long: "That name is too long! Try something shorter."
- Invalid characters: "Please use only letters and numbers."

**Profile Setup Validation**:

- No age selected: "How old are you? This helps us personalize your experience."
- Age out of range: "Please select your age from the options."

### Network Errors

**Supabase Connection Failure**:

- Show friendly error: "Oops! We couldn't save your buddy. Check your internet connection."
- Retry button: "Try Again"
- Skip option: "Continue Offline" (save locally, sync later)

### Data Persistence Errors

**Local Storage Failure**:

- Log error silently
- Continue with in-memory state
- Attempt to save on next screen

## Testing Strategy

### Unit Tests

1. **BuddyOnboardingNotifier Tests**:

   - Test color selection updates state
   - Test buddy name validation
   - Test profile completion flow
   - Test error handling

2. **Data Model Tests**:
   - Test BuddyProfile JSON serialization
   - Test BuddyOnboardingState copyWith
   - Test validation logic

### Widget Tests

1. **BuddyCharacterWidget Tests**:

   - Test rendering with different colors
   - Test size variations
   - Test face visibility toggle

2. **BuddyEggWidget Tests**:

   - Test selection state
   - Test tap interaction
   - Test animation triggers

3. **Screen Tests**:
   - Test navigation flow
   - Test form validation
   - Test button states

### Integration Tests

1. **Complete Onboarding Flow**:

   - Navigate through all screens
   - Verify data persistence
   - Test skip functionality
   - Verify dashboard navigation

2. **Error Recovery**:
   - Test network failure handling
   - Test validation error display
   - Test retry mechanisms

## Performance Considerations

### Animation Performance

- Use `RepaintBoundary` around animated Buddy character
- Dispose animation controllers properly
- Limit simultaneous animations to 2-3

### Image Assets

- Use vector graphics (SVG) for Buddy character when possible
- Provide multiple resolutions for raster images
- Lazy load assets not immediately visible

### State Management

- Keep onboarding state lightweight
- Clear temporary state after completion
- Use `AutoDispose` for providers when appropriate

## Accessibility

### Screen Reader Support

```dart
Semantics(
  label: 'Buddy character in ${color} color',
  child: BuddyCharacterWidget(color: color),
)
```

### Touch Targets

- Minimum 48x48 logical pixels for all interactive elements
- Adequate spacing between egg options (16px minimum)

### Color Contrast

- Text on white background: minimum 4.5:1 ratio
- Button labels: use high contrast colors
- Provide alternative text for all visual elements

## Migration Strategy

### Phase 1: Parallel Implementation

- Create new onboarding screens alongside existing survey
- Add feature flag to toggle between flows
- Test with small user group

### Phase 2: Data Migration

- Add `buddy_profiles` table
- Migrate existing users with default Buddy (optional)
- Update user profile schema

### Phase 3: Route Replacement

- Update `/survey_intro` route to point to `BuddyWelcomeScreen`
- Deprecate old survey screens
- Update navigation logic in `main.dart`

### Phase 4: Cleanup

- Remove old survey screens after 2 weeks
- Archive old code for reference
- Update documentation

## Future Enhancements

### Color Unlocking System

- Implement level-based color unlocks
- Add unlock animations
- Create color unlock notifications

### Buddy Accessories

- Design accessory system (hats, clothes, etc.)
- Create accessory selection screen
- Implement accessory unlocks

### Buddy Animations

- Add more emotion states (happy, sad, excited)
- Implement context-aware animations
- Create celebration animations for achievements

### Social Features

- Buddy sharing (screenshot with friend code)
- Buddy comparison (show friends' Buddies)
- Buddy challenges (compete with friends)

## Conclusion

This design provides a comprehensive blueprint for implementing the Buddy onboarding flow in FlowFit. The architecture leverages existing patterns while introducing new, engaging elements that will appeal to the target audience of children aged 7-12. The minimalist, gender-neutral design inspired by successful self-care apps ensures broad appeal while maintaining FlowFit's brand identity.

The implementation prioritizes performance, accessibility, and user experience, with clear error handling and testing strategies to ensure a polished, production-ready feature.
