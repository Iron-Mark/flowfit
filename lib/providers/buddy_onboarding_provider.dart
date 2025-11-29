import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/buddy_onboarding_state.dart';
import '../models/buddy_profile.dart';

/// Notifier for managing Buddy onboarding flow state
///
/// This notifier handles the temporary state during the onboarding process,
/// validates user input, and persists data to Supabase when complete.
class BuddyOnboardingNotifier extends StateNotifier<BuddyOnboardingState> {
  final SupabaseClient? _supabase;
  final Uuid _uuid;

  BuddyOnboardingNotifier({SupabaseClient? supabase, Uuid? uuid})
    : _supabase = supabase,
      _uuid = uuid ?? const Uuid(),
      super(const BuddyOnboardingState());

  /// Get the Supabase client, initializing if needed
  SupabaseClient get _client {
    return _supabase ?? Supabase.instance.client;
  }

  /// Select a color for the Buddy
  ///
  /// Updates the state with the selected color from the color selection screen.
  void selectColor(String color) {
    state = state.copyWith(selectedColor: color);
  }

  /// Set the Buddy's name
  ///
  /// Updates the state with the user-chosen Buddy name.
  /// Should be called after validation passes.
  void setBuddyName(String name) {
    state = state.copyWith(buddyName: name);
  }

  /// Set user information (nickname and age)
  ///
  /// Updates the state with optional user profile information.
  /// Both parameters are optional as users can skip this step.
  void setUserInfo(String? nickname, int? age) {
    state = state.copyWith(userNickname: nickname, userAge: age);
  }

  /// Validate the Buddy name
  ///
  /// Returns an error message if validation fails, or null if valid.
  ///
  /// Validation rules:
  /// - Name must not be empty
  /// - Name must be between 1 and 20 characters
  String? validateBuddyName(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'Please give your buddy a name!';
    }

    if (trimmedName.length > 20) {
      return 'That name is too long! Try something shorter.';
    }

    return null;
  }

  /// Complete the onboarding process
  ///
  /// Saves the Buddy profile and user information to Supabase.
  /// Marks the onboarding as complete in the state.
  ///
  /// Throws an exception if:
  /// - Required fields are missing (buddyName, selectedColor)
  /// - Database operations fail
  Future<void> completeOnboarding(String userId) async {
    // Validate required fields
    if (state.buddyName == null || state.buddyName!.isEmpty) {
      throw Exception('Buddy name is required');
    }

    final selectedColor = state.selectedColor ?? 'blue';

    try {
      // Create Buddy profile
      final now = DateTime.now();
      final buddyProfile = BuddyProfile(
        id: _uuid.v4(),
        userId: userId,
        name: state.buddyName!,
        color: selectedColor,
        level: 1,
        xp: 0,
        unlockedColors: [selectedColor],
        createdAt: now,
        updatedAt: now,
      );

      // Save Buddy profile to Supabase
      await _saveBuddyProfile(buddyProfile);

      // Update user profile with nickname and age if provided
      if (state.userNickname != null || state.userAge != null) {
        await _updateUserProfile(userId, state.userNickname, state.userAge);
      }

      // Mark onboarding as complete
      state = state.copyWith(isComplete: true);
    } catch (e) {
      // Re-throw with more context
      throw Exception('Failed to complete onboarding: $e');
    }
  }

  /// Save Buddy profile to Supabase
  Future<void> _saveBuddyProfile(BuddyProfile profile) async {
    await _client.from('buddy_profiles').insert(profile.toJson());
  }

  /// Update user profile with nickname and kids mode flag
  Future<void> _updateUserProfile(
    String userId,
    String? nickname,
    int? age,
  ) async {
    final updates = <String, dynamic>{};

    if (nickname != null && nickname.isNotEmpty) {
      updates['nickname'] = nickname;
    }

    if (age != null) {
      updates['is_kids_mode'] = age <= 12;
    }

    if (updates.isNotEmpty) {
      await _client.from('user_profiles').update(updates).eq('id', userId);
    }
  }

  /// Reset the onboarding state
  ///
  /// Useful for testing or if user wants to restart the flow.
  void reset() {
    state = const BuddyOnboardingState();
  }
}

/// Provider for Buddy onboarding state management
final buddyOnboardingProvider =
    StateNotifierProvider<BuddyOnboardingNotifier, BuddyOnboardingState>(
      (ref) => BuddyOnboardingNotifier(),
    );
