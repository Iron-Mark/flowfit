import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../providers/running_session_provider.dart';
import '../../../models/workout_session.dart';

/// Active running screen with real-time GPS tracking and metrics
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8
class ActiveRunningScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const ActiveRunningScreen({
    super.key,
    this.sessionId,
  });

  @override
  ConsumerState<ActiveRunningScreen> createState() => _ActiveRunningScreenState();
}

class _ActiveRunningScreenState extends ConsumerState<ActiveRunningScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _formatTime(int? seconds) {
    if (seconds == null) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double distance) {
    return distance.toStringAsFixed(2);
  }

  String _formatPace(double? pace) {
    if (pace == null) return '--:--';
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showEndWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Workout?'),
        content: const Text('Are you sure you want to end this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to post-mood check
              // TODO: Implement navigation to post-mood check
              Navigator.of(context).pushReplacementNamed('/workout/running/summary');
            },
            child: const Text('End Workout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(runningSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Running')),
        body: const Center(
          child: Text('No active session'),
        ),
      );
    }

    final isPaused = session.status == WorkoutStatus.paused;
    final currentLocation = session.routePoints.isNotEmpty 
        ? session.routePoints.last 
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      body: SafeArea(
        child: Column(
          children: [
            // Header with status, timer, and controls
            _buildHeader(theme, session, isPaused),
            
            // Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Primary metric: Distance
                    _buildPrimaryMetric(theme, session),
                    
                    const SizedBox(height: 24),
                    
                    // Secondary metrics grid
                    _buildMetricsGrid(theme, session),
                    
                    const SizedBox(height: 24),
                    
                    // Progress bar
                    _buildProgressBar(theme, session),
                    
                    const SizedBox(height: 24),
                    
                    // Map
                    _buildMap(session, currentLocation),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, dynamic session, bool isPaused) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPaused 
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPaused ? 'PAUSED' : 'ACTIVE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isPaused ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Timer
          Expanded(
            child: Text(
              _formatTime(session.durationSeconds),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Pause/Resume button
          IconButton(
            onPressed: () {
              if (isPaused) {
                ref.read(runningSessionProvider.notifier).resumeSession();
              } else {
                ref.read(runningSessionProvider.notifier).pauseSession();
              }
            },
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              minimumSize: const Size(48, 48),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // End button
          IconButton(
            onPressed: _showEndWorkoutDialog,
            icon: const Icon(Icons.stop),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMetric(ThemeData theme, dynamic session) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Distance',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDistance(session.currentDistance)} km',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ThemeData theme, dynamic session) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          theme,
          'Duration',
          _formatTime(session.durationSeconds),
          Icons.timer_outlined,
        ),
        _buildMetricCard(
          theme,
          'Pace',
          '${_formatPace(session.avgPace)} /km',
          Icons.speed,
        ),
        _buildMetricCard(
          theme,
          'Heart Rate',
          session.avgHeartRate != null 
              ? '${session.avgHeartRate} bpm'
              : '--',
          Icons.favorite_outline,
        ),
        _buildMetricCard(
          theme,
          'Calories',
          session.caloriesBurned != null 
              ? '${session.caloriesBurned} cal'
              : '--',
          Icons.local_fire_department_outlined,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, dynamic session) {
    final progress = session.progressPercentage;
    final progressPercent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$progressPercent%',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(dynamic session, LatLng? currentLocation) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: session.routePoints.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Waiting for GPS signal...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentLocation ?? const LatLng(0, 0),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.flowfit.app',
                ),
                // Route polyline
                if (session.routePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: session.routePoints,
                        strokeWidth: 4,
                        color: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                // Current location marker
                if (currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
