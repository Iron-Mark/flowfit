import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/running_session.dart';
import '../models/mood_rating.dart';
import '../models/workout_session.dart';
import '../services/gps_tracking_service.dart';
import '../services/timer_service.dart';
import '../services/heart_rate_service.dart';
import '../services/calorie_calculator_service.dart';
import '../services/workout_session_service.dart';

/// Provider for GPS tracking service
final gpsTrackingServiceProvider = Provider((ref) => GPSTrackingService());

/// Provider for timer service
final timerServiceProvider = Provider((ref) => TimerService());

/// Provider for heart rate service
final heartRateServiceProvider = Provider((ref) => HeartRateService());

/// Provider for calorie calculator service
final calorieCalculatorServiceProvider = Provider((ref) => CalorieCalculatorService());

/// Provider for workout session service
final workoutSessionServiceProvider = Provider((ref) => WorkoutSessionService());

/// Provider for managing running workout sessions
class RunningSessionNotifier extends StateNotifier<RunningSession?> {
  final GPSTrackingService _gpsService;
  final TimerService _timerService;
  final HeartRateService _hrService;
  final CalorieCalculatorService _calorieService;
  final WorkoutSessionService _sessionService;

  StreamSubscription<LatLng>? _gpsSubscription;
  StreamSubscription<int>? _timerSubscription;
  StreamSubscription<int>? _hrSubscription;
  Timer? _metricsUpdateTimer;

  RunningSessionNotifier({
    required GPSTrackingService gpsService,
    required TimerService timerService,
    required HeartRateService hrService,
    required CalorieCalculatorService calorieService,
    required WorkoutSessionService sessionService,
  })  : _gpsService = gpsService,
        _timerService = timerService,
        _hrService = hrService,
        _calorieService = calorieService,
        _sessionService = sessionService,
        super(null);

  /// Starts a new running session
  Future<void> startSession({
    required GoalType goalType,
    double? targetDistance,
    int? targetDuration,
    MoodRating? preMood,
  }) async {
    final session = RunningSession(
      id: const Uuid().v4(),
      userId: 'current-user-id', // TODO: Get from auth
      startTime: DateTime.now(),
      goalType: goalType,
      targetDistance: targetDistance,
      targetDuration: targetDuration,
      preMood: preMood,
    );

    state = session;

    // Start services
    await _gpsService.startTracking();
    _timerService.start();
    await _hrService.startMonitoring();

    // Subscribe to GPS updates
    _gpsSubscription = _gpsService.locationStream.listen((location) {
      _updateLocation(location);
    });

    // Subscribe to timer updates
    _timerSubscription = _timerService.timerStream.listen((seconds) {
      _updateDuration(seconds);
    });

    // Subscribe to heart rate updates
    _hrSubscription = _hrService.heartRateStream.listen((hr) {
      _updateHeartRate(hr);
    });

    // Update metrics every second
    _metricsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMetrics(),
    );

    // Save initial session to database
    await _sessionService.createSession(session);
  }

  /// Updates location and route
  void _updateLocation(LatLng location) {
    if (state == null) return;

    final updatedPoints = [...state!.routePoints, location];
    final distance = _gpsService.calculateRouteDistance(updatedPoints);

    state = state!.copyWith(
      routePoints: updatedPoints,
      currentDistance: distance,
    );
  }

  /// Updates duration
  void _updateDuration(int seconds) {
    if (state == null) return;

    state = state!.copyWith(durationSeconds: seconds);
  }

  /// Updates heart rate
  void _updateHeartRate(int hr) {
    if (state == null) return;

    state = state!.copyWith(
      avgHeartRate: _hrService.avgHeartRate,
      maxHeartRate: _hrService.maxHeartRate,
      heartRateZones: _hrService.heartRateZones,
    );
  }

  /// Updates all metrics (pace, calories)
  void _updateMetrics() {
    if (state == null) return;

    // Calculate pace
    final durationMinutes = (state!.durationSeconds ?? 0) / 60.0;
    final pace = state!.currentDistance > 0
        ? durationMinutes / state!.currentDistance
        : null;

    // Calculate calories
    final calories = _calorieService.calculateCalories(
      workoutType: WorkoutType.running,
      durationMinutes: durationMinutes.round(),
      distanceKm: state!.currentDistance,
      avgHeartRate: state!.avgHeartRate,
    );

    state = state!.copyWith(
      avgPace: pace,
      caloriesBurned: calories,
    );
  }

  /// Pauses the running session
  void pauseSession() {
    if (state == null) return;

    _timerService.pause();
    _gpsService.stopTracking();
    _hrService.stopMonitoring();
    _metricsUpdateTimer?.cancel();

    state = state!.copyWith(status: WorkoutStatus.paused);
  }

  /// Resumes the running session
  Future<void> resumeSession() async {
    if (state == null) return;

    _timerService.resume();
    await _gpsService.startTracking();
    await _hrService.startMonitoring();

    _metricsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMetrics(),
    );

    state = state!.copyWith(status: WorkoutStatus.active);
  }

  /// Ends the running session
  Future<void> endSession({MoodRating? postMood}) async {
    if (state == null) return;

    _timerService.stop();
    await _gpsService.stopTracking();
    await _hrService.stopMonitoring();
    _metricsUpdateTimer?.cancel();

    final moodChange = postMood != null && state!.preMood != null
        ? postMood.value - state!.preMood!.value
        : null;

    state = state!.copyWith(
      endTime: DateTime.now(),
      postMood: postMood,
      moodChange: moodChange,
      status: WorkoutStatus.completed,
    );

    // Save final session to database
    await _sessionService.saveSession(state!);
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _timerSubscription?.cancel();
    _hrSubscription?.cancel();
    _metricsUpdateTimer?.cancel();
    _gpsService.dispose();
    _timerService.dispose();
    _hrService.dispose();
    super.dispose();
  }
}

/// Provider for running session state
final runningSessionProvider = StateNotifierProvider<RunningSessionNotifier, RunningSession?>(
  (ref) => RunningSessionNotifier(
    gpsService: ref.watch(gpsTrackingServiceProvider),
    timerService: ref.watch(timerServiceProvider),
    hrService: ref.watch(heartRateServiceProvider),
    calorieService: ref.watch(calorieCalculatorServiceProvider),
    sessionService: ref.watch(workoutSessionServiceProvider),
  ),
);
