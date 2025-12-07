import 'package:camera/camera.dart';
import '../entities/detection_result.dart';
import '../repositories/yolo_repository.dart';

class DetectObjectUseCase {
  final YoloRepository _repository;

  DetectObjectUseCase(this._repository);

  Future<List<DetectionResult>> call(CameraImage image) {
    return _repository.detectObjects(image);
  }
}
