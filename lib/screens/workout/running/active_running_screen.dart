import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:solar_icons/solar_icons.dart';
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
  MapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
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
            onPressed: () async {
              Navigator.of(context).pop();
              
              // End the session properly
              final notifier = ref.read(runningSessionProvider.notifier);
              await notifier.endSession();
              
              // Navigate to summary
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/workout/running/summary');
              }
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen map as background
            _buildFullScreenMap(session, currentLocation),
            
            // Gradient overlay for better readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.2, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            
            // Content overlay
            Column(
              children: [
                // Header with controls
                _buildHeader(theme, session, isPaused),
                
                const Spacer(),
                
                // Bottom metrics panel
                _buildBottomMetricsPanel(theme, session),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, dynamic session, bool isPaused) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(SolarIconsOutline.altArrowLeft, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              minimumSize: const Size(44, 44),
            ),
          ),
          
          const Spacer(),
          
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isPaused 
                  ? Colors.orange.withOpacity(0.9)
                  : Colors.green.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPaused ? SolarIconsBold.pauseCircle : SolarIconsBold.playCircle,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isPaused ? 'PAUSED' : 'RUNNING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Menu button
          IconButton(
            onPressed: () {},
            icon: const Icon(SolarIconsOutline.menuDots, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildFullScreenMap(dynamic session, LatLng? currentLocation) {
    return session.routePoints.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  SolarIconsBold.mapPoint,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Waiting for GPS signal...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : FlutterMap(
            mapController: _mapController ??= MapController(),
            options: MapOptions(
              initialCenter: currentLocation ?? const LatLng(0, 0),
              initialZoom: 16,
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
                      strokeWidth: 5,
                      color: const Color(0xFF3B82F6),
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
              // Current location marker
              if (currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
  }

  Widget _buildBottomMetricsPanel(ThemeData theme, dynamic session) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLargeMetric(
                'Distance',
                '${_formatDistance(session.currentDistance)}',
                'km',
                SolarIconsBold.mapArrowSquare,
                const Color(0xFF3B82F6),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              _buildLargeMetric(
                'Duration',
                _formatTime(session.durationSeconds),
                '',
                SolarIconsBold.clockCircle,
                Colors.orange,
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              _buildLargeMetric(
                'Pace',
                _formatPace(session.avgPace),
                '/km',
                SolarIconsBold.chartSquare,
                Colors.green,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Secondary metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallMetric(
                'Heart Rate',
                session.avgHeartRate != null ? '${session.avgHeartRate}' : '--',
                'bpm',
                SolarIconsBold.heartPulse,
                Colors.red,
              ),
              _buildSmallMetric(
                'Calories',
                session.caloriesBurned != null ? '${session.caloriesBurned}' : '--',
                'cal',
                SolarIconsBold.fire,
                Colors.orange,
              ),
              _buildSmallMetric(
                'Steps',
                session.steps != null ? '${session.steps}' : '--',
                'steps',
                SolarIconsBold.walking,
                const Color(0xFF3B82F6),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Control buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final isPaused = session.status == WorkoutStatus.paused;
                    if (isPaused) {
                      ref.read(runningSessionProvider.notifier).resumeSession();
                    } else {
                      ref.read(runningSessionProvider.notifier).pauseSession();
                    }
                  },
                  icon: Icon(
                    session.status == WorkoutStatus.paused 
                        ? SolarIconsBold.play 
                        : SolarIconsBold.pause,
                  ),
                  label: Text(
                    session.status == WorkoutStatus.paused ? 'Resume' : 'Pause',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _showEndWorkoutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(SolarIconsBold.stopCircle, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeMetric(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMetric(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
