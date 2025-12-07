class DetectionResult {
  final String label;
  final double confidence;
  final List<double>
  bbox; // [x, y, w, h] or [x1, y1, x2, y2] - we'll standardize on normalized [x1, y1, x2, y2]
  final List<List<double>>? keypoints; // For pose detection

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.bbox,
    this.keypoints,
  });

  @override
  String toString() {
    return 'DetectionResult(label: $label, confidence: $confidence, bbox: $bbox, keypoints: $keypoints)';
  }
}
