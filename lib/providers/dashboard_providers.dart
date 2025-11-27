import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_stats.dart';
import '../models/recent_activity.dart';
import '../models/daily_mood.dart';
import 'package:flowfit/core/providers/repositories/heart_rate_repository_provider.dart' as core_hrp;

/// Provider for fetching daily fitness statistics
/// 
/// Returns DailyStats containing steps, calories, and active minutes.
/// States: loading, data(DailyStats), error
/// 
/// Refresh by calling: ref.invalidate(dailyStatsProvider)
final dailyStatsProvider = FutureProvider<DailyStats>((ref) async {
  // TODO: Replace with actual data source (Supabase, SQLite, etc.)
  // Simulating async data fetch
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Mock data for development
  return DailyStats(
    steps: 6504,
    stepsGoal: 10000,
    calories: 387,
    activeMinutes: 45,
  );
});

/// Provider for fetching recent workout activities
/// 
/// Returns a list of RecentActivity objects sorted by most recent first.
/// States: loading, data(List<RecentActivity>), error
/// 
/// Refresh by calling: ref.invalidate(recentActivitiesProvider)
final recentActivitiesProvider = FutureProvider<List<RecentActivity>>((ref) async {
  // TODO: Replace with actual data source (Supabase, SQLite, etc.)
  // Simulating async data fetch
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Mock data for development
  final now = DateTime.now();
  return [
    RecentActivity(
      id: '1',
      name: 'Morning Run',
      type: 'run',
      details: '3.2 miles • 30 min',
      date: now,
    ),
    RecentActivity(
      id: '2',
      name: 'Evening Walk',
      type: 'walk',
      details: '1.5 miles • 20 min',
      date: now.subtract(const Duration(days: 1)),
    ),
    RecentActivity(
      id: '3',
      name: 'Gym Workout',
      type: 'workout',
      details: '45 min • Upper body',
      date: now.subtract(const Duration(days: 2)),
    ),
    RecentActivity(
      id: '4',
      name: 'Bike Ride',
      type: 'cycle',
      details: '10 miles • 45 min',
      date: now.subtract(const Duration(days: 3)),
    ),
  ];
});

/// Provider for daily mood/stress summary from AI tracker
final dailyMoodProvider = FutureProvider<DailyMood>((ref) async {
  // Try to get historical heart rate readings for today and derive a mood summary from them.
  try {
    final heartRateRepo = ref.watch(core_hrp.heartRateRepositoryProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = now;
    final readings = await heartRateRepo.getHistoricalData(startDate: start, endDate: end);
    if (readings.isEmpty) {
      // No data — return a neutral mood based on zero stress
      return DailyMood(stressMinutes: 0, calmMinutes: 24 * 60);
    }

    // compute average delta between consecutive readings
    int avgDeltaSeconds = 10; // default: assume 10s
    if (readings.length >= 2) {
      final deltas = <int>[];
      for (int i = 1; i < readings.length; i++) {
        final delta = readings[i].timestamp.difference(readings[i - 1].timestamp).inSeconds;
        if (delta > 0) deltas.add(delta);
      }
      if (deltas.isNotEmpty) {
        final sum = deltas.reduce((a, b) => a + b);
        avgDeltaSeconds = (sum / deltas.length).round();
        avgDeltaSeconds = avgDeltaSeconds.clamp(1, 600);
      }
    }

    // Determine baseline as average bpm for the day (fallback to 70)
    final bpms = readings.map((r) => r.bpm ?? 0).where((b) => b > 0).toList();
    final avgBpm = bpms.isEmpty ? 70 : (bpms.reduce((a, b) => a + b) / bpms.length);
    double threshold = avgBpm + 15.0; // threshold above average indicates possible stress
    threshold = threshold.clamp(80.0, 140.0);

    // classify each reading as stressed or calm using threshold
    int stressedSeconds = 0;
    int calmSeconds = 0;
    for (final r in readings) {
      final bpm = r.bpm ?? 0;
      if (bpm >= threshold) {
        stressedSeconds += avgDeltaSeconds;
      } else {
        calmSeconds += avgDeltaSeconds;
      }
    }
    final stressedMinutes = (stressedSeconds / 60).round();
    final calmMinutes = (calmSeconds / 60).round();
    return DailyMood(stressMinutes: stressedMinutes, calmMinutes: calmMinutes);
  } catch (e) {
    // Fallback to mocked values in case of error
    await Future.delayed(const Duration(milliseconds: 250));
    return DailyMood(stressMinutes: 30, calmMinutes: 90);
  }
});

/// Provider to compare today's cardio/active minutes vs baseline.
/// Returns a percentage (positive => more than baseline, negative => less)
final activityComparisonProvider = FutureProvider<double>((ref) async {
  final stats = await ref.watch(dailyStatsProvider.future);
  // TODO: Replace baseline with multi-day average from database
  const baseline = 30.0; // baseline active minutes
  final diff = stats.activeMinutes - baseline;
  final pctChange = (diff / (baseline == 0 ? 1 : baseline));
  return pctChange; // e.g., 0.2 => 20% more
});

/// Provider for managing the selected bottom navigation index
/// 
/// Initial value: 0 (Home)
/// Range: 0-4 (5 navigation items: Home, Health, Track, Progress, Profile)
final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for managing unread notification count
/// 
/// Initial value: 0
/// Display logic: Shows "9+" when count > 9
final unreadNotificationsProvider = StateProvider<int>((ref) => 0);
