/// Buddy onboarding state model
///
/// Manages temporary onboarding data before final profile creation.
/// This state is used during the onboarding flow to collect user choices
/// before persisting them to the database.
class BuddyOnboardingState {
  /// Selected Buddy color (e.g., 'blue', 'green', 'purple')
  final String? selectedColor;

  /// Buddy name chosen by the user
  final String? buddyName;

  /// User's nickname (optional)
  final String? userNickname;

  /// User's age (optional)
  final int? userAge;

  /// Whether the onboarding flow is complete
  final bool isComplete;

  const BuddyOnboardingState({
    this.selectedColor,
    this.buddyName,
    this.userNickname,
    this.userAge,
    this.isComplete = false,
  });

  /// Creates a copy of this state with updated fields
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

  @override
  String toString() {
    return 'BuddyOnboardingState('
        'selectedColor: $selectedColor, '
        'buddyName: $buddyName, '
        'userNickname: $userNickname, '
        'userAge: $userAge, '
        'isComplete: $isComplete)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuddyOnboardingState &&
        other.selectedColor == selectedColor &&
        other.buddyName == buddyName &&
        other.userNickname == userNickname &&
        other.userAge == userAge &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode {
    return Object.hash(
      selectedColor,
      buddyName,
      userNickname,
      userAge,
      isComplete,
    );
  }
}
