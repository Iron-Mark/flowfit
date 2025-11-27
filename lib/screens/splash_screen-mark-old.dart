import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../presentation/providers/providers.dart';
import '../domain/entities/auth_state.dart';

/// Splash screen shown while checking authentication state.
///
/// Requirements: 5.1 - Check auth state on app start
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Start animation
    _animationController.forward();

    _checkAuthState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    // Wait for animation and minimum splash time
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // final authState = ref.read(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    // Initialize auth state (check for existing session)
    await authNotifier.initialize();

    if (!mounted) return;

    final updatedAuthState = ref.read(authNotifierProvider);

    if (updatedAuthState.status == AuthStatus.authenticated &&
        updatedAuthState.user != null) {
      // User is authenticated, check if profile is complete
      final profileRepository = ref.read(profileRepositoryProvider);

      try {
        final hasCompletedSurvey = await profileRepository.hasCompletedSurvey(
          updatedAuthState.user!.id,
        );

        if (!mounted) return;

        if (hasCompletedSurvey) {
          // Profile complete, go to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // Profile incomplete, go to survey
          Navigator.pushReplacementNamed(
            context,
            '/survey_intro',
            arguments: {'userId': updatedAuthState.user!.id},
          );
        }
      } catch (e) {
        // Error checking profile, assume incomplete and go to survey
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/survey_intro',
            arguments: {'userId': updatedAuthState.user!.id},
          );
        }
      }
    } else {
      // Not authenticated, go to welcome screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF), // Light blue background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Logo
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: SvgPicture.asset(
                  'assets/flowfit_logo.svg',
                  width: 120,
                  height: 120,
                ),
              ),

              const Spacer(),

              // App Name at the bottom
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48.0),
                  child: Text(
                    'FlowFit',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: const Color(0xFF3183E8), // Brand Blue
                      fontWeight: FontWeight.bold,
                      fontFamily: 'GeneralSans',
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
