import '../domain/activity.dart';

/// Use case: Classify sensor buffer into an activity type
/// Pure business logic, no platform dependencies
class ClassifyActivityUseCase {
  final ActivityClassifierRepository _repository;

  ClassifyActivityUseCase(this._repository);

  /// Classify a buffer of [accX, accY, accZ, bpm] readings
  /// Expects buffer length of exactly 320 items (windowed data)
  Future<Activity> execute(List<List<double>> buffer) async {
    if (buffer.isEmpty) {
      throw ArgumentError('Buffer cannot be empty');
    }

    if (buffer.length != 320) {
      throw ArgumentError(
        'Buffer must contain exactly 320 samples, got ${buffer.length}',
      );
    }

    // Validate each item has 4 values: [accX, accY, accZ, bpm]
    for (final item in buffer) {
      if (item.length != 4) {
        throw ArgumentError(
          'Each buffer item must have 4 values [accX, accY, accZ, bpm], got ${item.length}',
        );
      }
    }

    // Delegate to repository for actual classification
    return _repository.classifyActivity(buffer);
  }
}

/// Repository interface for activity classification
/// Decouples use case from platform-specific ML implementation
abstract class ActivityClassifierRepository {
  /// Classify sensor buffer and return activity prediction
  /// Returns Activity with label, confidence, and probabilities
  Future<Activity> classifyActivity(List<List<double>> buffer);

  /// Get available activity labels
  Future<List<String>> getActivityLabels();
}
