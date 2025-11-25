import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flowfit/services/phone_data_listener.dart';
import 'package:provider/provider.dart';

import 'providers.dart';
import '../platform/tflite_activity_classifier.dart';
import '../platform/heart_bpm_adapter.dart';

enum BpmSource { Simulation, Plugin, Watch }

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
  StreamSubscription<int?>? _bpmSub;
  Timer? _accelTimer;
  int _accelSimTick = 0;
  bool _simulateAccel = false; // Use synthetic accelerometer data
  double _accelAmplitude = 1.0; // Synthetic amplitude
  double _accelFreqHz = 1.0; // Tones per second in simulation

  // Local references to providers
  late ActivityClassifierViewModel _viewModel;
  late TFLiteActivityClassifier _platformClassifier;
  bool _initialized = false;
  int? _currentBpmValue;
  bool _forceSimulate = true; // Default: simulate mock heartbeat first
  BpmSource _bpmSource = BpmSource.Simulation;
  bool _pluginAvailable = false;
  // plugin availability determined dynamically by adapter connection

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

      _startSensorSubscription();

      // Subscribe to BPM stream (if any)
      // connect adapter to the selected source (default Simulation)
      _connectToSelectedSource();

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _stopSensorSubscription();
    _bpmSub?.cancel();
    super.dispose();
  }

  void _startSensorSubscription() {
    _stopSensorSubscription();

    if (_simulateAccel) {
      // Simulate at ~32Hz (31ms per sample)
      final sampleMs = (1000 / 32).round();
      _accelTimer = Timer.periodic(Duration(milliseconds: sampleMs), (_) {
        // Synthetic signal: sinusoidal components + noise
        final t = _accelSimTick / 32.0; // seconds
        final x = _accelAmplitude * sin(2 * pi * _accelFreqHz * t) + (Random().nextDouble() - 0.5) * 0.05;
        final y = _accelAmplitude * sin(2 * pi * _accelFreqHz * t + pi / 3) + (Random().nextDouble() - 0.5) * 0.05;
        final z = _accelAmplitude * sin(2 * pi * _accelFreqHz * t + 2 * pi / 3) + 9.8 + (Random().nextDouble() - 0.5) * 0.05;
        _accelSimTick++;
        _addToBuffer(AccelerometerEvent(x, y, z));
      });
    } else {
      _accelSub = accelerometerEvents.listen((event) {
        _addToBuffer(event);
      });
    }
  }

  void _stopSensorSubscription() {
    _accelSub?.cancel();
    _accelSub = null;
    _accelTimer?.cancel();
    _accelTimer = null;
    _accelSimTick = 0;
  }

  void _addToBuffer(AccelerometerEvent event) {
    // 1. Add current reading + Simulated Heart Rate to buffer
    // Your model expects: [AccX, AccY, AccZ, BPM]
    final activeBpm = _forceSimulate ? _simulatedHR.round() : (_currentBpmValue ?? _simulatedHR.round());
    _dataBuffer.add([event.x, event.y, event.z, activeBpm.toDouble()]);

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

  void _connectToSelectedSource() {
    final adapter = Provider.of<HeartBpmAdapter>(context, listen: false);

    // Cancel existing subscription
    _bpmSub?.cancel();
    _bpmSub = null;

    switch (_bpmSource) {
      case BpmSource.Simulation:
        // Disconnect any external source and use manual slider bpm
        adapter.connectExternalStream(null);
        break;
      case BpmSource.Plugin:
        // Plugin connection is managed by app (main.dart) or other init code.
        // We assume main.dart or other code may have already connected the plugin stream.
        // If no plugin is connected, keep adapter disconnected and notify UI.
        // Optionally, application initialization can call:
        // `context.read<HeartBpmAdapter>().connectExternalStream(HeartBpm.heartBpmStream);`
        // no-op: assume plugin is connected externally (e.g., main.dart or other)
        break;
      case BpmSource.Watch:
        // Use PhoneDataListener to get watch HR
        final phoneListener = Provider.of<PhoneDataListener>(context, listen: false);
        adapter.connectExternalStream(
          phoneListener.heartRateStream.map((hr) => hr.bpm ?? 0),
        );
        break;
    }

    // Also locally subscribe to adapter stream to show current BPM in UI
    _bpmSub = adapter.bpmStream.listen((bpm) {
      setState(() => _currentBpmValue = bpm);
    });

    // Update plugin availability state (shows connected or not)
    setState(() {
      _pluginAvailable = adapter.hasExternalConnection;
    });
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Simulate Watch Heart Rate: ${_simulatedHR.round()} BPM'),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text('Use simulation'),
                    Switch(
                      value: _forceSimulate,
                      onChanged: (v) => setState(() => _forceSimulate = v),
                    ),
                  ],
                ),
              ],
            ),
            Slider(
              min: 60,
              max: 180,
              value: _simulatedHR,
              onChanged: (val) => setState(() => _simulatedHR = val),
              activeColor: Colors.red,
            ),
            const SizedBox(height: 4),
            const Text('Drag slider HIGH to simulate Panic/Running'),

            const SizedBox(height: 12),
            // Simulate movement toggle and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Simulate Movement'),
                Switch(
                  value: _simulateAccel,
                  onChanged: (val) {
                    setState(() {
                      _simulateAccel = val;
                      _startSensorSubscription();
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text('Amp:'),
                Slider(
                  min: 0.0,
                  max: 2.0,
                  value: _accelAmplitude,
                  onChanged: (v) {
                    setState(() => _accelAmplitude = v);
                  },
                  divisions: 20,
                  label: _accelAmplitude.toStringAsFixed(2),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                const Text('Frequency'),
                Slider(
                  min: 0.5,
                  max: 4.0,
                  value: _accelFreqHz,
                  onChanged: (v) {
                    setState(() {
                      _accelFreqHz = v;
                    });
                  },
                  divisions: 35,
                  label: '${_accelFreqHz.toStringAsFixed(2)}Hz',
                ),
              ],
            ),

            const SizedBox(height: 12),
            // BPM Source selection
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Simulation'),
                  selected: _bpmSource == BpmSource.Simulation,
                  onSelected: (s) {
                    setState(() {
                      _bpmSource = BpmSource.Simulation;
                      _forceSimulate = true;
                      _connectToSelectedSource();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Plugin'),
                  selected: _bpmSource == BpmSource.Plugin,
                  onSelected: (s) {
                    setState(() {
                      _bpmSource = BpmSource.Plugin;
                      _forceSimulate = false;
                      _connectToSelectedSource();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Watch'),
                  selected: _bpmSource == BpmSource.Watch,
                  onSelected: (s) {
                    setState(() {
                      _bpmSource = BpmSource.Watch;
                      _forceSimulate = false;
                      _connectToSelectedSource();
                    });
                  },
                ),
              ],
            ),

            // Optional: show last error from ViewModel
            if (viewModel.hasError) ...[
              const SizedBox(height: 12),
              Text('Error: ${viewModel.error}', style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 12),
            // Display plugin/watch connection status
            if (_bpmSource == BpmSource.Plugin) ...[
              Text(
                _pluginAvailable ? 'Plugin connected' : 'Plugin not connected',
                style: TextStyle(color: _pluginAvailable ? Colors.green : Colors.orange),
              ),
            ] else if (_bpmSource == BpmSource.Watch) ...[
              Text(
                _currentBpmValue != null
                    ? 'Watch BPM: $_currentBpmValue'
                    : 'Watch not connected',
                style: TextStyle(color: _currentBpmValue != null ? Colors.green : Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatProb(double p) => (p * 100).toStringAsFixed(1);
}
