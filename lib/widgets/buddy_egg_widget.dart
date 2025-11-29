import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that renders an egg-shaped color option for Buddy selection.
///
/// The egg has a spotted pattern and supports selection state with
/// border/glow effect and tap animation.
class BuddyEggWidget extends StatefulWidget {
  /// The base color of the egg
  final Color baseColor;

  /// Whether this egg is currently selected
  final bool isSelected;

  /// Callback when the egg is tapped
  final VoidCallback onTap;

  /// The size of the egg
  final double size;

  const BuddyEggWidget({
    super.key,
    required this.baseColor,
    required this.isSelected,
    required this.onTap,
    this.size = 80.0,
  });

  @override
  State<BuddyEggWidget> createState() => _BuddyEggWidgetState();
}

class _BuddyEggWidgetState extends State<BuddyEggWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Trigger haptic feedback
    HapticFeedback.lightImpact();

    // Animate scale bounce
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    // Call the onTap callback
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size * 1.2, // Eggs are taller than wide
              decoration: BoxDecoration(
                // Add selection border/glow
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.baseColor.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
                border: widget.isSelected
                    ? Border.all(color: widget.baseColor, width: 3)
                    : null,
                borderRadius: BorderRadius.circular(widget.size * 0.5),
              ),
              child: CustomPaint(
                painter: _EggPainter(
                  baseColor: widget.baseColor,
                  isSelected: widget.isSelected,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the egg shape with spotted pattern
class _EggPainter extends CustomPainter {
  final Color baseColor;
  final bool isSelected;

  _EggPainter({required this.baseColor, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    // Draw egg shape (oval with rounded bottom)
    final eggPath = Path();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create egg shape using an ellipse that's wider at bottom
    eggPath.addOval(rect);

    canvas.drawPath(eggPath, paint);

    // Draw spotted pattern (3-4 darker spots)
    _drawSpots(canvas, size);
  }

  void _drawSpots(Canvas canvas, Size size) {
    // Create darker shade for spots
    final spotColor = Color.lerp(baseColor, Colors.black, 0.2)!;
    final spotPaint = Paint()
      ..color = spotColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Define spot positions and sizes (relative to egg size)
    final spots = [
      {'x': 0.3, 'y': 0.25, 'radius': 0.08},
      {'x': 0.65, 'y': 0.35, 'radius': 0.06},
      {'x': 0.45, 'y': 0.55, 'radius': 0.07},
      {'x': 0.25, 'y': 0.65, 'radius': 0.05},
    ];

    for (final spot in spots) {
      final x = size.width * (spot['x'] as double);
      final y = size.height * (spot['y'] as double);
      final radius = size.width * (spot['radius'] as double);

      canvas.drawCircle(Offset(x, y), radius, spotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EggPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.isSelected != isSelected;
  }
}
