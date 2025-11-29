import 'package:flutter/material.dart';

/// A widget that applies a celebration animation to its child.
///
/// This animation creates a one-time 1-second jump animation with scale and rotation
/// effects to celebrate achievements or completion events.
///
/// Requirements: 5.1, 9.1, 9.2, 9.3, 9.5
class BuddyCelebrationAnimation extends StatefulWidget {
  final Widget child;

  const BuddyCelebrationAnimation({super.key, required this.child});

  @override
  State<BuddyCelebrationAnimation> createState() =>
      _BuddyCelebrationAnimationState();
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

    // Create a 1-second animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Jump animation: -50px up, then back to 0
    _jumpAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -50.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -50.0, end: 0.0), weight: 50),
    ]).animate(_controller);

    // Scale animation: 1.0 → 1.2 → 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_controller);

    // Subtle rotation with elasticOut curve
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Start the animation
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
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    // Properly dispose animation controller to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }
}
