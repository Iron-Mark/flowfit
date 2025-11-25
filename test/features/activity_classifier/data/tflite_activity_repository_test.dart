import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/activity_classifier/data/activity_dto.dart';
import 'package:flowfit/features/activity_classifier/data/tflite_activity_repository.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';

/// Simple test double for TFLiteActivityClassifier
class FakeTFLiteActivityClassifier implements TFLiteActivityClassifier {
  List<double>? nextPrediction;
  bool _isLoaded = false;

  @override
  Future<List<double>> predict(List<List<double>> buffer) async {
    if (!_isLoaded) {
      throw StateError('Model not loaded');
    }

    if (nextPrediction == null) {
      throw StateError('nextPrediction not set');
    }

    return nextPrediction!;
  }

  @override
  Future<void> loadModel() async {
    _isLoaded = true;
  }

  @override
  bool get isLoaded => _isLoaded;

  @override
  void dispose() {
    _isLoaded = false;
  }
}

void main() {
  group('TFLiteActivityRepository', () {
    late FakeTFLiteActivityClassifier fakeClassifier;
    late TFLiteActivityRepository repository;

    setUp(() {
      fakeClassifier = FakeTFLiteActivityClassifier();
      repository = TFLiteActivityRepository(fakeClassifier);
    });

    test('classify activity returns Activity with correct label', () async {
      await fakeClassifier.loadModel();
      final buffer = List.generate(320, (_) => [1.0, 2.0, 3.0, 72.0]);
      fakeClassifier.nextPrediction = [0.1, 0.8, 0.1]; // Cardio

      final result = await repository.classifyActivity(buffer);

      expect(result.label, equals('Cardio'));
      expect(result.confidence, closeTo(0.8, 0.01));
      expect(result.probabilities, equals([0.1, 0.8, 0.1]));
    });

    test('classify activity with Stress prediction', () async {
      await fakeClassifier.loadModel();
      final buffer = List.generate(320, (_) => [0.5, 0.5, 0.5, 60.0]);
      fakeClassifier.nextPrediction = [0.85, 0.1, 0.05]; // Stress

      final result = await repository.classifyActivity(buffer);

      expect(result.label, equals('Stress'));
      expect(result.confidence, closeTo(0.85, 0.01));
    });

    test('classify activity with Strength prediction', () async {
      await fakeClassifier.loadModel();
      final buffer = List.generate(320, (_) => [3.0, 3.0, 3.0, 120.0]);
      fakeClassifier.nextPrediction = [0.05, 0.1, 0.85]; // Strength

      final result = await repository.classifyActivity(buffer);

      expect(result.label, equals('Strength'));
      expect(result.confidence, closeTo(0.85, 0.01));
    });

    test('get activity labels returns all three labels', () async {
      final labels = await repository.getActivityLabels();

      expect(labels, equals(['Stress', 'Cardio', 'Strength']));
      expect(labels.length, equals(3));
    });

    test('propagate classifier errors', () async {
      await fakeClassifier.loadModel();
      final buffer = List.generate(320, (_) => [1.0, 2.0, 3.0, 72.0]);
      fakeClassifier.nextPrediction = null; // This will throw

      expect(
        () => repository.classifyActivity(buffer),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ActivityDto', () {
    test('create DTO from prediction probabilities', () {
      final probs = [0.05, 0.85, 0.1];

      final dto = ActivityDto.fromPrediction(probs);

      expect(dto.label, equals('Cardio'));
      expect(dto.confidence, equals(0.85));
      expect(dto.probabilities, equals(probs));
    });

    test('identify max probability correctly', () {
      final dto1 = ActivityDto.fromPrediction([0.9, 0.05, 0.05]);
      expect(dto1.label, equals('Stress'));

      final dto2 = ActivityDto.fromPrediction([0.05, 0.9, 0.05]);
      expect(dto2.label, equals('Cardio'));

      final dto3 = ActivityDto.fromPrediction([0.05, 0.05, 0.9]);
      expect(dto3.label, equals('Strength'));
    });

    test('throw error on invalid prediction length', () {
      final invalidProbs = [0.5, 0.5]; // Only 2 values

      expect(
        () => ActivityDto.fromPrediction(invalidProbs),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handle equal probabilities (first wins)', () {
      final probs = [0.33, 0.33, 0.34];

      final dto = ActivityDto.fromPrediction(probs);

      expect(dto.label, equals('Strength')); // Last one has highest
    });
  });
}
