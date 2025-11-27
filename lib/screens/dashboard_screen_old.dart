import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:solar_icons/solar_icons.dart';
import '../core/providers/providers.dart' as core_providers;
import '../providers/dashboard_providers.dart';
import '../presentation/providers/providers.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart' as ac_providers;
import '../widgets/page_header.dart';
import 'home/widgets/home_header.dart';
import 'home/widgets/stats_section.dart';
import 'home/widgets/cta_section.dart';
import 'home/widgets/recent_activity_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const HealthTab(),
    const TrackTab(),
    const ProgressTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Check auth state on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final authState = ref.read(authNotifierProvider);
    
    // If not authenticated, redirect to welcome screen
    if (authState.user == null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Listen for auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      // If user logs out, redirect to welcome
      if (next.user == null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
      }
    });
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          selectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.bodySmall,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 24,
          elevation: 0, // We handle elevation with Container shadow
          items: const [
            BottomNavigationBarItem(
              icon: Icon(SolarIconsOutline.home2),
              label: 'Home',
              tooltip: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(SolarIconsOutline.heartPulse),
              label: 'Health',
              tooltip: 'Health',
            ),
            BottomNavigationBarItem(
              icon: Icon(SolarIconsOutline.mapPointWave),
              label: 'Track',
              tooltip: 'Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(SolarIconsOutline.chartSquare),
              label: 'Progress',
              tooltip: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(SolarIconsOutline.userCircle),
              label: 'Profile',
              tooltip: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Home Tab - Original design with greeting and quick actions
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    final dailyStatsAsync = ref.watch(dailyStatsProvider);
    final dailyMoodAsync = ref.watch(dailyMoodProvider);
    final heartRateAsync = ref.watch(core_providers.currentHeartRateProvider);
    final heartRateTracking = ref.watch(core_providers.heartRateTrackingStateProvider);
    final watchConnectedAsync = ref.watch(core_providers.watchConnectionStateProvider);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          PageHeader(
            title: '${_getGreeting()}, Jim!',
            subtitle: "Let's make today a great day.",
          ),
          // Watch status banner for immediate visibility
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            child: watchConnectedAsync.when(
              data: (connected) => connected
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.watch, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Watch connected — live data available', style: Theme.of(context).textTheme.bodySmall)),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.watch_off, size: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Watch not connected — connect to enable live AI tracking', style: Theme.of(context).textTheme.bodySmall)),
                          TextButton(
                            onPressed: () async {
                              try {
                                await ref.read(core_providers.connectionControlProvider.notifier).connect();
                              } catch (_) {}
                            },
                            child: const Text('Connect'),
                          )
                        ],
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                
                const SizedBox(height: 24),
                
                // Stats Cards Row
                Row(
                  children: [
                    Expanded(
                      child: dailyStatsAsync.when(
                        data: (s) => _buildStatCard(
                          context,
                          'Steps',
                          '${s.steps}',
                          Icons.directions_walk,
                          theme.colorScheme.primary,
                        ),
                        loading: () => _buildStatCard(
                          context,
                          'Steps',
                          '--',
                          Icons.directions_walk,
                          theme.colorScheme.primary,
                        ),
                        error: (_, __) => _buildStatCard(
                          context,
                          'Steps',
                          '--',
                          Icons.directions_walk,
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: dailyStatsAsync.when(
                        data: (s) => _buildStatCard(
                          context,
                          'Calories',
                          '${s.calories}',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                        loading: () => _buildStatCard(
                          context,
                          'Calories',
                          '--',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                        error: (_, __) => _buildStatCard(
                          context,
                          'Calories',
                          '--',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Minutes Card
                dailyStatsAsync.when(
                  data: (s) => _buildStatCard(
                    context,
                    'Minutes',
                    '${s.activeMinutes}',
                    Icons.timer,
                    theme.colorScheme.tertiary,
                  ),
                  loading: () => _buildStatCard(
                    context,
                    'Minutes',
                    '--',
                    Icons.timer,
                    theme.colorScheme.tertiary,
                  ),
                  error: (_, __) => _buildStatCard(
                    context,
                    'Minutes',
                    '--',
                    Icons.timer,
                    theme.colorScheme.tertiary,
                  ),
                ),
                
                const SizedBox(height: 20),

                // Streak Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🔥', style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '5-Day Streak',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "You're on fire!\nKeep the momentum going.",
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Quick Track Section
                Text(
                  'Quick Track',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),
                
                // Quick Track Grid (2x2) - improved
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    GestureDetector(
                      onTap: () async {
                          if (!heartRateTracking) {
                            // Start tracking using the notifier
                            await ref.read(core_providers.heartRateTrackingStateProvider.notifier).startTracking();
                          } else {
                            Navigator.pushNamed(context, '/phone_heart_rate');
                          }
                        },
                        child: heartRateAsync.when(
                          data: (hr) {
                            final bpm = hr.bpm?.toString() ?? '--';
                            final status = heartRateTracking ? 'Tracking' : 'Start';
                            return _buildQuickTrackCard(
                              context,
                              'Heart Rate',
                              '$bpm bpm • $status',
                              SolarIconsBold.heartPulse,
                              Colors.red,
                            );
                          },
                          loading: () => _buildQuickTrackCard(
                            context,
                            'Heart Rate',
                            'Loading…',
                            SolarIconsBold.heartPulse,
                            Colors.red,
                          ),
                          error: (_, __) => _buildQuickTrackCard(
                            context,
                            'Heart Rate',
                            'Offline',
                            SolarIconsBold.heartPulse,
                            Colors.red,
                          ),
                        ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        // If watch connected -> open live tracker
                        final isConnected = watchConnectedAsync.maybeWhen(data: (v) => v, orElse: () => false);
                        if (isConnected) {
                          Navigator.pushNamed(context, '/trackertest');
                        } else {
                          // open the watch connection flow
                          // attempt to connect using connectionControlProvider
                          await ref.read(core_providers.connectionControlProvider.notifier).connect();
                        }
                      },
                      child: _buildAIActivityCard(
                        context,
                        ref,
                        dailyMoodAsync,
                        heartRateAsync,
                        watchConnectedAsync,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Add Meal
                      },
                      child: _buildQuickTrackCard(
                        context,
                        'Add Meal',
                        'Record your intake',
                        SolarIconsBold.hamburgerMenu,
                        Colors.orange,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, "/mission");
                      },
                      child: _buildQuickTrackCard(
                        context,
                        'Log Sleep',
                        'Track your rest',
                        SolarIconsBold.moon,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIActivityCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> dailyMoodAsync,
    AsyncValue<dynamic> heartRateAsync,
    AsyncValue<bool> watchConnectedAsync,
  ) {
    final theme = Theme.of(context);
    // Try to read the provider-managed ActivityClassifierViewModel if available
    ac_providers.ActivityClassifierViewModel? classifierViewModel;
    try {
      classifierViewModel = provider_pkg.Provider.of<ac_providers.ActivityClassifierViewModel>(context);
    } catch (_) {
      classifierViewModel = null;
    }

    // (fallback card uses _buildQuickTrackCard)

    return watchConnectedAsync.when(
      data: (isConnected) {
        if (!isConnected) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.surface, theme.colorScheme.surfaceVariant],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(SolarIconsBold.cpu, size: 20, color: Colors.deepPurple),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Activity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Watch required for live stress tracking', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Connect your watch to enable live AI detection', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref.read(core_providers.connectionControlProvider.notifier).connect();
                          } catch (_) {
                            // ignore
                          }
                        },
                        child: const Text('Connect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        }

        // Watch connected – show live classification or fallback
        final activityLabel = classifierViewModel?.currentActivity?.label ?? 'Estimating';
        final probs = classifierViewModel?.currentActivity?.probabilities ?? [0.0, 0.0, 0.0];
        final isStressed = activityLabel.toLowerCase().contains('stress');
        final bpm = heartRateAsync.when(data: (hr) => hr.bpm?.toString() ?? '--', loading: () => '--', error: (_, __) => '--');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isStressed ? Colors.red : Colors.green).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(SolarIconsBold.cpu, size: 20, color: isStressed ? Colors.red : Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('AI Activity (Live)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: isStressed ? Colors.red : Colors.green, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Live', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(activityLabel, style: theme.textTheme.bodyMedium?.copyWith(color: isStressed ? Colors.red : Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Confidence: ${(probs.isNotEmpty ? (probs.first * 100).round() : 0)}%', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text('$bpm bpm', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: probs.isNotEmpty ? (probs.first.clamp(0.0, 1.0)) : 0,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(isStressed ? Colors.red : Colors.green),
              ),
            ],
          ),
        );
      },
      loading: () => _buildQuickTrackCard(context, 'AI Activity', 'Checking watch…', SolarIconsBold.cpu, Colors.deepPurple),
      error: (_, __) => _buildQuickTrackCard(context, 'AI Activity', 'AI down', SolarIconsBold.cpu, Colors.deepPurple),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTrackCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Health Tab
class HealthTab extends StatelessWidget {
  const HealthTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          const PageHeader(
            title: 'Daily Log',
            subtitle: 'Today, November 25',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              
              const SizedBox(height: 24),
              
              // Food Intake Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  SolarIconsBold.hamburgerMenu,
                                  size: 24,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Food Intake',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '1250/2000 kcal',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Food'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.625, // 1250/2000
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Meal Type Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildMealTab(context, 'Breakfast', true),
                            const SizedBox(width: 8),
                            _buildMealTab(context, 'Lunch', false),
                            const SizedBox(width: 8),
                            _buildMealTab(context, 'Dinner', false),
                            const SizedBox(width: 8),
                            _buildMealTab(context, 'Snacks', false),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Food Items
                      _buildFoodItem(context, 'Oatmeal with Berries', '350 kcal'),
                      const SizedBox(height: 12),
                      _buildFoodItem(context, 'Black Coffee', '5 kcal'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Hydration Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.cyan.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.water_drop,
                                  size: 24,
                                  color: Colors.cyan,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Hydration',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '1.5 / 2.0 L',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Circular Progress
                      Center(
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 160,
                                height: 160,
                                child: CircularProgressIndicator(
                                  value: 0.75,
                                  strokeWidth: 14,
                                  backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '75%',
                                    style: theme.textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Goal',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Water buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildWaterButton(context, '-'),
                          const SizedBox(width: 40),
                          _buildWaterButton(context, '+'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Sleep Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  SolarIconsBold.moon,
                                  size: 24,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sleep',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total sleep: 7h 30m',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              'Edit',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Sleep Time Cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Went to Bed',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '10:30 PM',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Wake Up',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '6:00 AM',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTab(BuildContext context, String label, bool isSelected) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.surfaceVariant : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, String name, String calories) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                calories,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterButton(BuildContext context, String label) {
    final theme = Theme.of(context);
    
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Text(
          label,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.cyan,
          ),
        ),
        onPressed: () {},
      ),
    );
  }
}

// Track Tab - Using the redesigned modular widgets
class TrackTab extends ConsumerWidget {
  const TrackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const HomeHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate and refresh all providers
          ref.invalidate(dailyStatsProvider);
          ref.invalidate(recentActivitiesProvider);
          
          // Wait for providers to complete
          await Future.wait([
            ref.read(dailyStatsProvider.future),
            ref.read(recentActivitiesProvider.future),
          ]);
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              
              // Stats Section
              StatsSection(),
              SizedBox(height: 24),
              
              // CTA Section
              CTASection(),
              SizedBox(height: 24),
              
              // Recent Activity Section
              RecentActivitySection(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Progress Tab
class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  bool _isWeekView = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          const PageHeader(
            title: 'Progress',
            subtitle: 'Track your fitness journey',
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                
                const SizedBox(height: 24),
                
                // This Week's Insight Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        SolarIconsBold.lightbulb,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "This Week's Insight",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Great job on your consistency! You've increased your average daily steps by 15% this week. Keep it up!",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Weekly Activity Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Activity',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Active Minutes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    // Week/Month Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildToggleButton(context, 'Week', _isWeekView),
                          _buildToggleButton(context, 'Month', !_isWeekView),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Activity Chart
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Activity Chart',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Mon', style: theme.textTheme.bodySmall),
                          Text('Tue', style: theme.textTheme.bodySmall),
                          Text('Wed', style: theme.textTheme.bodySmall),
                          Text('Thu', style: theme.textTheme.bodySmall),
                          Text('Fri', style: theme.textTheme.bodySmall),
                          Text('Sat', style: theme.textTheme.bodySmall),
                          Text('Sun', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sleep Quality Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sleep Quality',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Avg. 7h 32m',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'View Details',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Sleep bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 12,
                                color: Colors.blue,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 12,
                                color: Colors.lightBlue,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 12,
                                color: Colors.cyan,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 12,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSleepLegend(context, 'Deep', Colors.blue),
                          _buildSleepLegend(context, 'Light', Colors.lightBlue),
                          _buildSleepLegend(context, 'Rem', Colors.cyan),
                          _buildSleepLegend(context, 'Awake', Colors.grey.shade300),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Your Trends Section
                Text(
                  'Your Trends',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Trends Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildTrendCard(
                        context,
                        'Steps',
                        '8,210',
                        '+1204 vs last week',
                        SolarIconsBold.walking,
                        theme.colorScheme.primary,
                        true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTrendCard(
                        context,
                        'Calories',
                        '8,210',
                        '+1204 vs last week',
                        SolarIconsBold.fire,
                        Colors.orange,
                        true,
                      ),
                    ),
                  ],
                ),
                
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context, String label, bool isSelected) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeekView = label == 'Week';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSleepLegend(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTrendCard(
    BuildContext context,
    String label,
    String value,
    String change,
    IconData icon,
    Color color,
    bool isPositive,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            change,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Profile Tab
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    ref.watch(authNotifierProvider);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Profile',
            subtitle: 'Manage your account',
            trailing: IconButton(
              icon: const Icon(SolarIconsOutline.settings),
              onPressed: () {},
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    color: theme.colorScheme.surface,
                    padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Text(
                      'MG',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark Garcia',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@mark_garcia',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'FlowFit Member since 2022',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // General Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'General Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingItem(context, 'Privacy Policy', SolarIconsOutline.shieldCheck),
            _buildSettingItem(context, 'Notification Reminder', SolarIconsOutline.bell),
            _buildSettingItem(context, 'App Integration', SolarIconsOutline.widget),
            
            const SizedBox(height: 24),
            
            // My Account Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'My Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(context, 'Username', '@mark_garcia'),
            _buildSettingItem(context, 'Profile Photo', SolarIconsOutline.camera),
            _buildInfoItem(context, 'Sex', 'Male'),
            _buildInfoItem(context, 'Date of Birth', '05/12/1990'),
            _buildInfoItem(context, 'Location', 'New York, NY'),
            _buildInfoItem(context, 'Email', 'mark.garcia@email.com'),
            _buildSettingItem(context, 'Change Password', SolarIconsOutline.lock),
            _buildSettingItem(context, 'Delete Account', SolarIconsOutline.trashBinMinimalistic),
            _buildSettingItem(
              context, 
              'Logout', 
              SolarIconsOutline.logout,
              onTap: () async {
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  // Sign out using auth notifier
                  await ref.read(authNotifierProvider.notifier).signOut();
                  
                  // Navigate to welcome screen and clear stack
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/welcome',
                      (route) => false,
                    );
                  }
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            // My Goals Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'My Goals',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildGoalItem(
              context,
              'Weight Goals',
              'Current: 145 lbs, Goal weight: 135 lbs, Weekly Goal: 1 lb/week',
            ),
            _buildGoalItem(
              context,
              'Fitness Preference, Fitness Goals',
              'Activity Level: Moderate, Workout: 4 times/workout 45 min',
            ),
            _buildGoalItem(
              context,
              'Nutrition Goals',
              'Default Macros Goal: 2000 calories, Daily Macros Goal (Custom): 2200 calories',
            ),
            
            const SizedBox(height: 24),
            
            // Progress Timeline Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Timeline',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTimelineButton(context, 'All', true),
                        const SizedBox(width: 8),
                        _buildTimelineButton(context, '1 Week', false),
                        const SizedBox(width: 8),
                        _buildTimelineButton(context, '1 Month', false),
                        const SizedBox(width: 8),
                        _buildTimelineButton(context, '3 Months', false),
                        const SizedBox(width: 8),
                        _buildTimelineButton(context, '6 Months', false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Weight Progress Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '145 lbs',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Last 30 Days -2%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Simple chart placeholder
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Weight Chart',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Jan', style: theme.textTheme.bodySmall),
                        Text('Feb', style: theme.textTheme.bodySmall),
                        Text('Mar', style: theme.textTheme.bodySmall),
                        Text('Apr', style: theme.textTheme.bodySmall),
                        Text('May', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: Icon(
          icon,
          color: title == 'Logout' ? Colors.red : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: title == 'Logout' ? Colors.red : null,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, String title, String description) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: theme.colorScheme.surface,
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildTimelineButton(BuildContext context, String label, bool isSelected) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
