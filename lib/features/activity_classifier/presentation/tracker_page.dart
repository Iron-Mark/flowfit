import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:provider/provider.dart';

import 'providers.dart';
import '../platform/tflite_activity_classifier.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({Key? key}) : super(key: key);

  @override
  _TrackerPageState createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  // Buffers
  final List<List<double>> _dataBuffer = [];
  static const int WINDOW_SIZE = 320; // 10 seconds @ ~32Hz

  // State
  double _simulatedHR = 80.0; // Slider to control Heart Rate manually

  // Sensor subscription
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // Local references to providers
  late ActivityClassifierViewModel _viewModel;
  late TFLiteActivityClassifier _platformClassifier;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      // Resolve providers from the widget tree
      _viewModel = Provider.of<ActivityClassifierViewModel>(context, listen: false);
      _platformClassifier = Provider.of<TFLiteActivityClassifier>(context, listen: false);

      // Ensure model is loaded once at startup
      if (!_platformClassifier.isLoaded) {
        _platformClassifier.loadModel();
      }

      // Start listening to accelerometer now we have necessary providers
      _accelSub = accelerometerEvents.listen((event) {
        _addToBuffer(event);
      });

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _addToBuffer(AccelerometerEvent event) {
    // 1. Add current reading + Simulated Heart Rate to buffer
    // Your model expects: [AccX, AccY, AccZ, BPM]
    _dataBuffer.add([event.x, event.y, event.z, _simulatedHR]);

    // 2. Keep buffer at exactly 320 items
    if (_dataBuffer.length > WINDOW_SIZE) {
      _dataBuffer.removeAt(0); // Slide window
    }

    // 3. Run inference every ~32 samples (approx once per second)
    // We don't run on every frame to save battery
    if (_dataBuffer.length == WINDOW_SIZE && !_viewModel.isLoading && _dataBuffer.length % 32 == 0) {
      _runInference();
    }
  }

  Future<void> _runInference() async {
    // Make a defensive copy of the window for inference
    final input = List<List<double>>.from(_dataBuffer);

    try {
      await _viewModel.classify(input);
    } catch (_) {
      // ViewModel handles error logging and exposing error state
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the ViewModel
    final viewModel = Provider.of<ActivityClassifierViewModel>(context);

    final currentActivity = viewModel.currentActivity?.label ?? 'Waiting...';
    final probs = viewModel.currentActivity?.probabilities ?? [0.0, 0.0, 0.0];
    final isLoading = viewModel.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Anxiety Gap Demo')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. The Result (Big Text)
            Text(
              currentActivity,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: currentActivity == 'Stress' ? Colors.red : Colors.green,
              ),
            ),

            const SizedBox(height: 20),

            // 2. The Probabilities (Debug View)
            Text('Stress: ${(_formatProb(probs[0]))}%'),
            Text('Cardio: ${(_formatProb(probs[1]))}%'),
            Text('Strength: ${(_formatProb(probs[2]))}%'),

            const SizedBox(height: 24),

            // Loading state
            if (isLoading) const CircularProgressIndicator(),

            const SizedBox(height: 24),

            // 3. The "Wizard of Oz" Control (simulate Heart Rate)
            Text('Simulate Watch Heart Rate: ${_simulatedHR.round()} BPM'),
            Slider(
              min: 60,
              max: 180,
              value: _simulatedHR,
              onChanged: (val) => setState(() => _simulatedHR = val),
              activeColor: Colors.red,
            ),
            const SizedBox(height: 4),
            const Text('Drag slider HIGH to simulate Panic/Running'),

            // Optional: show last error from ViewModel
            if (viewModel.hasError) ...[
              const SizedBox(height: 12),
              Text('Error: ${viewModel.error}', style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatProb(double p) => (p * 100).toStringAsFixed(1);
}
