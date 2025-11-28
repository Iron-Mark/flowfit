import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../presentation/providers/providers.dart';
import 'home/home_screen.dart';
import 'health/health_screen.dart';
import 'track/track_screen.dart';
import 'progress/progress_screen.dart';
import 'profile/profile_screen.dart';
// Keep tab imports for future use
// ignore: unused_import
import 'dashboard/home_tab.dart';
// ignore: unused_import
import 'dashboard/health_tab.dart';
// ignore: unused_import
import 'dashboard/track_tab.dart';
// ignore: unused_import
import 'dashboard/progress_tab.dart';
// ignore: unused_import
import 'dashboard/profile_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HealthScreen(),
    const TrackScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
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

    if (initialTab != null && initialTab >= 0 && initialTab < _screens.length) {
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
