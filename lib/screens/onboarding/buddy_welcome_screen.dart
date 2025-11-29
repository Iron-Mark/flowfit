import 'package:flutter/material.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../widgets/onboarding_button.dart';

/// Buddy Welcome Screen
///
/// First screen in the Buddy onboarding flow that introduces
/// the user to their new fitness companion.
///
/// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 10.3, 10.4
class BuddyWelcomeScreen extends StatelessWidget {
  const BuddyWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD), // FlowFit light gray
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // FlowFit logo in header (subtle)
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'FlowFit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF3B82F6), // Primary Blue
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Spacer(),

              // Animated Buddy character in Ocean Blue
              BuddyIdleAnimation(
                child: BuddyCharacterWidget(
                  color: const Color(0xFF4ECDC4), // Ocean Blue
                  size: 200,
                ),
              ),

              const SizedBox(height: 32),

              // Large heading "Meet Your Buddy!"
              Text(
                'Meet Your Buddy!',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF314158), // FlowFit text color
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Friendly tagline
              Text(
                'Your new fitness best friend',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Primary button "Meet Your Buddy"
              OnboardingButton(
                text: 'Meet Your Buddy',
                onPressed: () {
                  Navigator.pushNamed(context, '/buddy-color-selection');
                },
                isPrimary: true,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
