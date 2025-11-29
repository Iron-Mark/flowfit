import 'package:flutter/material.dart';

/// Buddy Color System
///
/// Maps color names to Flutter Color objects based on the
/// blue-centered palette from MAIN-FEATURES.MD
///
/// Color Unlock Progression:
/// - Blue (Ocean Blue): Default, always available
/// - Teal: Level 3
/// - Green: Level 5
/// - Purple: Level 8
/// - Yellow: Level 10
/// - Orange: Level 15
/// - Pink: Level 20
/// - Navy: Level 25
class BuddyColors {
  /// Color palette mapping
  static const Map<String, Color> colors = {
    'blue': Color(0xFF4ECDC4), // Ocean Blue (DEFAULT)
    'teal': Color(0xFF26A69A), // Calm Teal (Level 3)
    'green': Color(0xFF66BB6A), // Fresh Green (Level 5)
    'purple': Color(0xFF9575CD), // Soft Purple (Level 8)
    'yellow': Color(0xFFFFD54F), // Gentle Yellow (Level 10)
    'orange': Color(0xFFFFB74D), // Warm Orange (Level 15)
    'pink': Color(0xFFF06292), // Happy Pink (Level 20)
    'navy': Color(0xFF5C6BC0), // Deep Navy (Level 25)
  };

  /// Level requirements for each color
  static const Map<String, int> colorLevels = {
    'blue': 1, // Default
    'teal': 3,
    'green': 5,
    'purple': 8,
    'yellow': 10,
    'orange': 15,
    'pink': 20,
    'navy': 25,
  };

  /// Display names for colors
  static const Map<String, String> colorNames = {
    'blue': 'Ocean Blue',
    'teal': 'Calm Teal',
    'green': 'Fresh Green',
    'purple': 'Soft Purple',
    'yellow': 'Gentle Yellow',
    'orange': 'Warm Orange',
    'pink': 'Happy Pink',
    'navy': 'Deep Navy',
  };

  /// Emojis for colors (for UI display)
  static const Map<String, String> colorEmojis = {
    'blue': '💙',
    'teal': '🐚',
    'green': '🟢',
    'purple': '🟣',
    'yellow': '🟡',
    'orange': '🟠',
    'pink': '💗',
    'navy': '🔵',
  };

  /// Get color by name, defaults to blue if not found
  static Color getColor(String colorName) {
    return colors[colorName] ?? colors['blue']!;
  }

  /// Get display name for color
  static String getDisplayName(String colorName) {
    return colorNames[colorName] ?? 'Unknown';
  }

  /// Get emoji for color
  static String getEmoji(String colorName) {
    return colorEmojis[colorName] ?? '💙';
  }

  /// Get level requirement for color
  static int getLevelRequirement(String colorName) {
    return colorLevels[colorName] ?? 1;
  }

  /// Check if color is unlocked at given level
  static bool isUnlocked(String colorName, int currentLevel) {
    final requiredLevel = getLevelRequirement(colorName);
    return currentLevel >= requiredLevel;
  }

  /// Get all colors unlocked at given level
  static List<String> getUnlockedColors(int currentLevel) {
    return colors.keys
        .where((color) => isUnlocked(color, currentLevel))
        .toList();
  }

  /// Get next color to unlock
  static String? getNextColorToUnlock(int currentLevel) {
    final sortedColors = colors.keys.toList()
      ..sort(
        (a, b) => getLevelRequirement(a).compareTo(getLevelRequirement(b)),
      );

    for (final color in sortedColors) {
      if (!isUnlocked(color, currentLevel)) {
        return color;
      }
    }
    return null; // All colors unlocked
  }

  /// Generate lighter shade for accents (belly, inner ears)
  static Color getLighterShade(Color baseColor) {
    return Color.lerp(baseColor, Colors.white, 0.3)!;
  }

  /// Generate darker shade for outlines and shadows
  static Color getDarkerShade(Color baseColor) {
    return Color.lerp(baseColor, Colors.black, 0.2)!;
  }

  /// Get all color names in unlock order
  static List<String> getAllColorsInOrder() {
    final sortedColors = colors.keys.toList()
      ..sort(
        (a, b) => getLevelRequirement(a).compareTo(getLevelRequirement(b)),
      );
    return sortedColors;
  }
}
