import 'package:flowfit/features/activity_classifier/data/tflite_activity_repository.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'package:flowfit/features/activity_classifier/platform/heart_bpm_adapter.dart';
import 'package:flowfit/features/activity_classifier/presentation/tracker_page.dart';
import 'package:flowfit/features/wellness/presentation/maps_page_wrapper.dart';
import 'package:flowfit/services/phone_data_listener.dart';
import 'package:flowfit/features/activity_classifier/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'theme/app_theme.dart';
import 'screens/loading_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/phone_home.dart';
import 'screens/phone/phone_heart_rate_screen.dart';
import 'screens/onboarding/survey_screen_1.dart';
import 'screens/onboarding/survey_screen_2.dart';
import 'screens/onboarding/survey_screen_3.dart';
import 'screens/onboarding/survey_intro_screen.dart';
import 'screens/onboarding/survey_basic_info_screen.dart';
import 'screens/onboarding/survey_body_measurements_screen.dart';
import 'screens/onboarding/survey_activity_goals_screen.dart';
import 'screens/onboarding/survey_daily_targets_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/font_demo_screen.dart';
import 'widgets/debug_route_menu.dart';

void main() {
  runApp(const ProviderScope(child: FlowFitPhoneApp()));
}

class FlowFitPhoneApp extends StatelessWidget {
  const FlowFitPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String initialRoute = const String.fromEnvironment(
      'INITIAL_ROUTE',
      defaultValue: '/',
    );

    return MultiProvider(
      providers: [
        Provider<HeartBpmAdapter>(create: (_) => HeartBpmAdapter()),
        // Phone data listener used to receive watch heart rate via Wearable data layer
        Provider<PhoneDataListener>(create: (_) => PhoneDataListener()),
        Provider<TFLiteActivityClassifier>(
          create: (_) => TFLiteActivityClassifier(),
        ),

        // Data layer
        ProxyProvider<TFLiteActivityClassifier, ActivityClassifierRepository>(
          create: (context) => TFLiteActivityRepository(
            context.read<TFLiteActivityClassifier>(),
          ),
          update: (_, classifier, __) => TFLiteActivityRepository(classifier),
        ),
        // Domain layer (use ActivityClassifierRepository abstract type)
        ProxyProvider<ActivityClassifierRepository, ClassifyActivityUseCase>(
          create: (context) => ClassifyActivityUseCase(
            context.read<ActivityClassifierRepository>(),
          ),
          update: (_, repository, __) => ClassifyActivityUseCase(repository),
        ),

        // Presentation layer
        ChangeNotifierProxyProvider<
          ClassifyActivityUseCase,
          ActivityClassifierViewModel
        >(
          create: (context) => ActivityClassifierViewModel(
            context.read<ClassifyActivityUseCase>(),
          ),
          update: (_, useCase, __) => ActivityClassifierViewModel(useCase),
        ),
      ],
      // Read an optional compile-time environment variable `INITIAL_ROUTE`.
      // This allows developers to quickly jump to a route when running the app
      // without editing code. Example:
      // flutter run -d <device-id> -t lib/main.dart --dart-define=INITIAL_ROUTE=/font-demo
      child: MaterialApp(
        // Wrap the app's child with a debug overlay (Floating debug menu)
        builder: (context, child) => Stack(
          children: [
            if (child != null) child,
            // Show the debug route menu only in debug builds.
            const DebugRouteMenu(),
          ],
        ),
        title: 'FlowFit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: initialRoute,
        routes: {
          '/': (context) => const LoadingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          // Old survey screens (kept for backward compatibility)
          '/survey1': (context) => const SurveyScreen1(),
          '/survey2': (context) => const SurveyScreen2(),
          '/survey3': (context) => const SurveyScreen3(),
          // New optimized survey flow
          '/survey_intro': (context) => const SurveyIntroScreen(),
          '/survey_basic_info': (context) => const SurveyBasicInfoScreen(),
          '/survey_body_measurements': (context) => const SurveyBodyMeasurementsScreen(),
          '/survey_activity_goals': (context) => const SurveyActivityGoalsScreen(),
          '/survey_daily_targets': (context) => const SurveyDailyTargetsScreen(),
          '/onboarding1': (context) => const OnboardingScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/trackertest': (context) => const TrackerPage(),
          '/mission': (context) => const MapsPageWrapper(),
          '/home': (context) => const PhoneHomePage(),
          '/phone_heart_rate': (context) => const PhoneHeartRateScreen(),
          '/font-demo': (context) => const FontDemoScreen(),
        },
      ),
    );
  }
}
