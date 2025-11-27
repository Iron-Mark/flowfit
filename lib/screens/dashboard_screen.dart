import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/dashboard_providers.dart';
import '../presentation/providers/providers.dart';
import '../core/domain/repositories/profile_repository.dart';
import '../widgets/page_header.dart';
import '../core/domain/entities/user_profile.dart';
import 'home/widgets/home_header.dart';
import 'home/widgets/stats_section.dart';
import 'home/widgets/cta_section.dart';
import 'home/widgets/recent_activity_section.dart';
import 'profile/profile_view.dart';
import 'onboarding/survey_basic_info_screen.dart';

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
      _checkInitialTab();
    });
  }

  void _checkInitialTab() {
    // Check if we should navigate to a specific tab
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final initialTab = args?['initialTab'] as int?;

    if (initialTab != null && initialTab != _currentIndex) {
      setState(() {
        _currentIndex = initialTab;
      });
    }
  }

  void _checkAuthState() {
    final authState = ref.read(authNotifierProvider);

    // If not authenticated, redirect to welcome screen
    if (authState.user == null) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Listen for auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      // If user logs out, redirect to welcome
      if (next.user == null && mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    });

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: bottomPadding),
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

    // Watch auth state to get user ID
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id;

    // Watch profile to get user's name (Requirement 7.1, 7.2)
    String userName = 'there';
    if (userId != null) {
      final profileAsync = ref.watch(profileNotifierProvider(userId));
      profileAsync.whenData((profile) {
        if (profile?.fullName != null) {
          // Get first name from full name
          final nameParts = profile!.fullName!.split(' ');
          userName = nameParts.isNotEmpty ? nameParts[0] : 'there';
        }
      });
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          PageHeader(
            title: '${_getGreeting()}, $userName!',
            subtitle: "Let's make today a great day.",
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Steps',
                            '6504',
                            Icons.directions_walk,
                            theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Calories',
                            '6504',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      context,
                      'Minutes',
                      '45',
                      Icons.timer,
                      theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 20),
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
                            child: const Text(
                              '🔥',
                              style: TextStyle(fontSize: 32),
                            ),
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
                    Text(
                      'Quick Track',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/phone_heart_rate');
                          },
                          child: _buildQuickTrackCard(
                            context,
                            'Heart Rate',
                            'Live monitoring',
                            SolarIconsBold.heartPulse,
                            Colors.red,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/trackertest');
                          },
                          child: _buildQuickTrackCard(
                            context,
                            'AI Activity',
                            'Track with AI',
                            SolarIconsBold.cpu,
                            Colors.deepPurple,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
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
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
          const PageHeader(title: 'Daily Log', subtitle: 'Today, November 27'),
          Expanded(
            child: Center(
              child: Text(
                'Health Tab - Coming Soon',
                style: theme.textTheme.headlineMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Track Tab
class TrackTab extends ConsumerWidget {
  const TrackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const HomeHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyStatsProvider);
          ref.invalidate(recentActivitiesProvider);
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
              StatsSection(),
              SizedBox(height: 24),
              CTASection(),
              SizedBox(height: 24),
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
class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

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
            child: Center(
              child: Text(
                'Progress Tab - Coming Soon',
                style: theme.textTheme.headlineMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Profile Tab
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Load profile image from SharedPreferences
  Future<void> _loadProfileImage() async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final imagePath = prefs.getString('profile_image_$userId');

      if (imagePath != null) {
        // Check if file still exists
        final file = File(imagePath);
        if (await file.exists() && mounted) {
          setState(() {
            _profileImagePath = imagePath;
          });
        } else {
          // File doesn't exist, clear the saved path
          await prefs.remove('profile_image_$userId');
        }
      }
    } catch (e) {
      // Silently fail - profile will just not have an image
    }
  }

  /// Save profile image to SharedPreferences
  Future<void> _saveProfileImage(String? path) async {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    final prefs = await ref.read(sharedPreferencesProvider.future);

    if (path != null) {
      await prefs.setString('profile_image_$userId', path);
    } else {
      await prefs.remove('profile_image_$userId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id;

    // If not authenticated, show login prompt
    if (userId == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Column(
          children: [
            PageHeader(title: 'Profile', subtitle: 'Manage your account'),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      SolarIconsOutline.userCircle,
                      size: 80,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please log in to view your profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
                      },
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Watch profile state
    final profileAsync = ref.watch(profileNotifierProvider(userId));

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Profile',
            subtitle: 'Manage your account',
            trailing: IconButton(
              icon: const Icon(SolarIconsOutline.settings),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
          Expanded(
            child: profileAsync.when(
              loading: () => _buildLoadingState(context),
              error: (error, stack) => _buildErrorState(context, error),
              data: (profile) {
                if (profile == null) {
                  return _buildEmptyState(context);
                }
                return _buildProfileView(context, profile);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.dangerTriangle,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final authState = ref.read(authNotifierProvider);
                final userId = authState.user?.id;
                if (userId != null) {
                  ref.invalidate(profileNotifierProvider(userId));
                }
              },
              icon: const Icon(SolarIconsOutline.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.documentText,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Complete Your Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please complete the onboarding survey to set up your profile',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/survey-intro');
              },
              child: const Text('Complete Onboarding'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, UserProfile profile) {
    final authState = ref.read(authNotifierProvider);
    final userId = authState.user?.id;

    return Column(
      children: [
        // Sync status indicator at the top
        if (userId != null) _buildSyncStatusBar(context, userId),
        Expanded(
          // Add RefreshIndicator for pull-to-refresh (Requirement 7.1, 7.2)
          child: RefreshIndicator(
            onRefresh: () => _handleRefresh(context, userId),
            child: ProfileView(
              profile: profile,
              profileImagePath: _profileImagePath,
              userEmail: authState.user?.email ?? 'Not set',
              onPhotoTap: () => _showPhotoPickerDialog(context),
              onEditTap: () => _navigateToEditProfile(context, profile),
              onLogout: () => _handleLogout(context),
            ),
          ),
        ),
      ],
    );
  }

  /// Handle profile refresh
  /// Requirement 7.1: Update UI when profile data changes
  /// Requirement 7.2: Immediately reflect changes in profile screen
  Future<void> _handleRefresh(BuildContext context, String? userId) async {
    if (userId == null) return;

    try {
      // Get the profile notifier
      final notifier = ref.read(profileNotifierProvider(userId).notifier);

      // Trigger reload
      await notifier.loadProfile();

      // Also refresh sync status
      ref.invalidate(syncStatusProvider(userId));
      ref.invalidate(pendingSyncCountProvider);

      if (!mounted) return;

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Build sync status bar showing current sync state
  Widget _buildSyncStatusBar(BuildContext context, String userId) {
    final theme = Theme.of(context);
    final syncStatusAsync = ref.watch(syncStatusProvider(userId));
    final pendingSyncCountAsync = ref.watch(pendingSyncCountProvider);

    return syncStatusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (syncStatus) {
        // Determine display based on sync status
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showManualSync = false;

        switch (syncStatus) {
          case SyncStatus.synced:
            statusText = 'Synced';
            statusColor = Colors.green;
            statusIcon = SolarIconsOutline.checkCircle;
            showManualSync = false;
            break;
          case SyncStatus.syncing:
            statusText = 'Syncing...';
            statusColor = theme.colorScheme.primary;
            statusIcon = SolarIconsOutline.refresh;
            showManualSync = false;
            break;
          case SyncStatus.pendingSync:
            final pendingCount = pendingSyncCountAsync.valueOrNull ?? 0;
            statusText = pendingCount > 0
                ? 'Pending sync ($pendingCount)'
                : 'Pending sync';
            statusColor = Colors.orange;
            statusIcon = SolarIconsOutline.cloudUpload;
            showManualSync = true;
            break;
          case SyncStatus.syncFailed:
            statusText = 'Sync failed - will retry';
            statusColor = Colors.red;
            statusIcon = SolarIconsOutline.dangerTriangle;
            showManualSync = true;
            break;
          case SyncStatus.offline:
            statusText = 'Offline';
            statusColor = theme.colorScheme.onSurfaceVariant;
            statusIcon = SolarIconsOutline.cloudCross;
            showManualSync = false;
            break;
        }

        // Don't show bar if synced and no pending items
        if (syncStatus == SyncStatus.synced) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(statusIcon, size: 20, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showManualSync)
                TextButton.icon(
                  onPressed: () => _handleManualSync(context, userId),
                  icon: Icon(
                    SolarIconsOutline.refresh,
                    size: 16,
                    color: statusColor,
                  ),
                  label: Text('Sync Now', style: TextStyle(color: statusColor)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              if (syncStatus == SyncStatus.syncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Handle manual sync button press
  Future<void> _handleManualSync(BuildContext context, String userId) async {
    final theme = Theme.of(context);

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onInverseSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Syncing profile...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Trigger manual sync
      final result = await ref.read(manualSyncProvider.future);

      if (!mounted) return;

      if (result) {
        // Sync attempted - refresh profile to get latest state
        ref.invalidate(profileNotifierProvider(userId));
        ref.invalidate(syncStatusProvider(userId));
        ref.invalidate(pendingSyncCountProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  SolarIconsOutline.checkCircle,
                  color: theme.colorScheme.onInverseSurface,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text('Profile synced successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // No connectivity
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  SolarIconsOutline.cloudCross,
                  color: theme.colorScheme.onInverseSurface,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text('No internet connection'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                SolarIconsOutline.dangerTriangle,
                color: theme.colorScheme.onInverseSurface,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text('Sync failed: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Navigate to onboarding flow for editing profile (Requirement 4.1, 4.5)
  Future<void> _navigateToEditProfile(
    BuildContext context,
    UserProfile profile,
  ) async {
    // Haptic feedback when tapping edit
    HapticFeedback.mediumImpact();

    // Re-run onboarding flow with existing profile data pre-populated
    // Survey screens will load existing profile data via _loadExistingData()
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SurveyBasicInfoScreen(),
        settings: RouteSettings(
          arguments: {
            'userId': profile.userId,
            'fromEdit': true, // Flag to indicate editing mode
          },
        ),
      ),
    );

    // Profile will auto-refresh due to ref.watch in ProfileTab
    // No need to manually refresh or change tabs
  }

  // Handle logout
  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Sign out from auth
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.signOut();

      if (!mounted) return;

      // Navigate to welcome screen and clear all routes
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/welcome', (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to logout: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
        await _saveProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
        await _saveProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting photo: $e')));
      }
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _profileImagePath = null;
    });
    await _saveProfileImage(null);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo removed')));
    }
  }

  void _showPhotoPickerDialog(BuildContext context) {
    // Haptic feedback when tapping photo
    HapticFeedback.lightImpact();

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Change Profile Photo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      SolarIconsOutline.camera,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      SolarIconsOutline.gallery,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                if (_profileImagePath != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        SolarIconsOutline.trashBinMinimalistic,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
