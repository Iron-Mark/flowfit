/// Domain model for activity classification result
class Activity {
  final String label;
  final double confidence;
  final DateTime timestamp;
  final List<double> probabilities;

  Activity({
    required this.label,
    required this.confidence,
    required this.timestamp,
    required this.probabilities,
  });

  /// Create a copy with modified fields
  Activity copyWith({
    String? label,
    double? confidence,
    DateTime? timestamp,
    List<double>? probabilities,
  }) {
    return Activity(
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      probabilities: probabilities ?? this.probabilities,
    );
  }

  @override
  String toString() =>
      'Activity(label: $label, confidence: ${(confidence * 100).toStringAsFixed(1)}%, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity &&
        other.label == label &&
        other.confidence == confidence &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(label, confidence, timestamp);
}
