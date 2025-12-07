import 'package:camera/camera.dart';
import '../entities/detection_result.dart';
import '../repositories/yolo_repository.dart';

class DetectPoseUseCase {
  final YoloRepository _repository;

  DetectPoseUseCase(this._repository);

  Future<List<DetectionResult>> call(CameraImage image) {
    return _repository.detectPose(image);
  }
}
