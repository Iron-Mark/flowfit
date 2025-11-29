/// Buddy companion pet profile model
///
/// Stores customization and progression data for the user's Buddy companion.
/// Buddy is a customizable pet that guides children through their fitness journey.
class BuddyProfile {
  /// Unique buddy profile identifier
  final String id;

  /// Reference to the user who owns this buddy
  final String userId;

  /// Buddy's name chosen by the user
  final String name;

  /// Buddy's current color (e.g., 'blue', 'green', 'purple')
  final String color;

  /// Buddy's current level (starts at 1)
  final int level;

  /// Buddy's current experience points
  final int xp;

  /// List of colors unlocked by the user (starts with initial color)
  final List<String> unlockedColors;

  /// Optional accessories data for future expansion
  final Map<String, dynamic>? accessories;

  /// Timestamp when buddy profile was created
  final DateTime createdAt;

  /// Timestamp when buddy profile was last updated
  final DateTime updatedAt;

  BuddyProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.level = 1,
    this.xp = 0,
    this.unlockedColors = const ['blue'],
    this.accessories,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a BuddyProfile from JSON
  factory BuddyProfile.fromJson(Map<String, dynamic> json) {
    return BuddyProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      unlockedColors: json['unlocked_colors'] != null
          ? List<String>.from(json['unlocked_colors'] as List)
          : ['blue'],
      accessories: json['accessories'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts this BuddyProfile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'level': level,
      'xp': xp,
      'unlocked_colors': unlockedColors,
      if (accessories != null) 'accessories': accessories,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BuddyProfile(id: $id, name: $name, color: $color, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuddyProfile &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.color == color &&
        other.level == level &&
        other.xp == xp &&
        _listEquals(other.unlockedColors, unlockedColors) &&
        _mapEquals(other.accessories, accessories) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      color,
      level,
      xp,
      Object.hashAll(unlockedColors),
      accessories,
      createdAt,
      updatedAt,
    );
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper method to compare maps
  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
