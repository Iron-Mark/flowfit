/// Data Transfer Object for activity classification API
class ActivityDto {
  final String label;
  final double confidence;
  final List<double> probabilities;

  ActivityDto({
    required this.label,
    required this.confidence,
    required this.probabilities,
  });

  /// Map DTO to domain model
  factory ActivityDto.fromPrediction(List<double> probabilities) {
    if (probabilities.length != 3) {
      throw ArgumentError('Probabilities must have exactly 3 values');
    }

    // Labels: 0=Stress, 1=Cardio, 2=Strength
    const labels = ['Stress', 'Cardio', 'Strength'];

    // Find max probability and corresponding label
    int maxIndex = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    return ActivityDto(
      label: labels[maxIndex],
      confidence: maxProb,
      probabilities: probabilities,
    );
  }
}
