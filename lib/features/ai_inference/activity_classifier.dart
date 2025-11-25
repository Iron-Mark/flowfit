import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ActivityClassifier {
  Interpreter? _interpreter;
  
  // 0=Stress, 1=Aerobic, 2=Anaerobic
  static const List<String> labels = ['Stress', 'Cardio', 'Strength'];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/activity_tracker.tflite');
      print('✅ Model loaded successfully');
      
      // Print input/output shape for debugging
      var inputShape = _interpreter!.getInputTensor(0).shape; // Should be [1, 320, 4]
      var outputShape = _interpreter!.getOutputTensor(0).shape; // Should be [1, 3]
      print('Input Shape: $inputShape'); 
      print('Output Shape: $outputShape');
      
    } catch (e) {
      print('❌ Error loading model: $e');
    }
  }

  // Expects a list of 320 items, where each item is [accX, accY, accZ, bpm]
  Future<List<double>> predict(List<List<double>> buffer) async {
    if (_interpreter == null) return [0, 0, 0];

    // 1. Reshape input to [1, 320, 4] (Batch size of 1)
    // Note: tflite_flutter handles List<List<double>> automatically
    var input = [buffer]; 
    
    // 2. Prepare output buffer [1, 3]
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]);

    // 3. Run Inference
    _interpreter!.run(input, output);

    // 4. Return probabilities (e.g., [0.1, 0.8, 0.1])
    return List<double>.from(output[0]);
  }
}