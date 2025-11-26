import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mood_tracking_provider.dart';
import '../providers/workout_flow_provider.dart';
import '../models/mood_rating.dart';

/// Quick mood check bottom sheet for pre-workout mood tracking
/// 
/// Displays 5 emoji buttons for mood selection with auto-dismiss timer.
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
class QuickMoodCheckBottomSheet extends ConsumerStatefulWidget {
  final bool isPostWorkout;
  final VoidCallback? onMoodSelected;
  
  const QuickMoodCheckBottomSheet({
    super.key,
    this.isPostWorkout = false,
    this.onMoodSelected,
  });

  @override
  ConsumerState<QuickMoodCheckBottomSheet> createState() => _QuickMoodCheckBottomSheetState();
}

class _QuickMoodCheckBottomSheetState extends ConsumerState<QuickMoodCheckBottomSheet> {
  Timer? _autoSelectTimer;
  int _remainingSeconds = 10;

  @override
  void initState() {
    super.initState();
    _startAutoSelectTimer();
  }

  void _startAutoSelectTimer() {
    final duration = widget.isPostWorkout ? 15 : 10;
    _remainingSeconds = duration;
    
    _autoSelectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleAutoSelect();
      }
    });
  }

  void _handleAutoSelect() {
    if (!mounted) return;

    if (widget.isPostWorkout) {
      // Default to pre-workout mood
      final preMood = ref.read(moodTrackingProvider).preMood;
      if (preMood != null) {
        _selectMood(preMood.value);
      } else {
        _selectMood(3); // Neutral
      }
    } else {
      // Default to neutral
      _selectMood(3);
    }
  }

  void _selectMood(int moodValue) {
    _autoSelectTimer?.cancel();

    if (widget.isPostWorkout) {
      ref.read(moodTrackingProvider.notifier).selectPostMood(moodValue);
    } else {
      ref.read(moodTrackingProvider.notifier).selectPreMood(moodValue);
      final mood = MoodRating.fromValue(moodValue);
      ref.read(workoutFlowProvider.notifier).setPreMood(mood);
    }

    // Dismiss bottom sheet
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      
      // Call the callback if provided
      widget.onMoodSelected?.call();
    }
  }

  @override
  void dispose() {
    _autoSelectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Heading
          Text(
            widget.isPostWorkout ? 'How do you feel now?' : 'How are you feeling?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Timer text
          Text(
            'Auto-selecting in $_remainingSeconds seconds',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Emoji buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMoodButton(context, 1, '😢', 'Very Bad'),
              _buildMoodButton(context, 2, '😕', 'Bad'),
              _buildMoodButton(context, 3, '😐', 'Neutral'),
              _buildMoodButton(context, 4, '🙂', 'Good'),
              _buildMoodButton(context, 5, '💪', 'Energized'),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMoodButton(BuildContext context, int value, String emoji, String label) {
    final theme = Theme.of(context);

    return _MoodButtonWithAnimation(
      emoji: emoji,
      label: label,
      onTap: () => _selectMood(value),
      theme: theme,
    );
  }
}

/// Mood button with scale animation on tap
class _MoodButtonWithAnimation extends StatefulWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  const _MoodButtonWithAnimation({
    required this.emoji,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_MoodButtonWithAnimation> createState() => _MoodButtonWithAnimationState();
}

class _MoodButtonWithAnimationState extends State<_MoodButtonWithAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse().then((_) {
        widget.onTap();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.surfaceVariant.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
