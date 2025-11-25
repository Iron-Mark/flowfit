import 'package:flowfit/features/activity_classifier/data/tflite_activity_repository.dart';
import 'package:flowfit/features/activity_classifier/domain/classify_activity_usecase.dart';
import 'package:flowfit/features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'package:flowfit/features/activity_classifier/platform/heart_bpm_adapter.dart';
import 'package:flowfit/features/activity_classifier/presentation/tracker_page.dart';
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
import 'screens/onboarding/survey_screen_1.dart';
import 'screens/onboarding/survey_screen_2.dart';
import 'screens/onboarding/survey_screen_3.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const ProviderScope(child: FlowFitPhoneApp()));
}

class FlowFitPhoneApp extends StatelessWidget {
  const FlowFitPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          create: (context) =>
              ClassifyActivityUseCase(context.read<ActivityClassifierRepository>()),
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
      child: MaterialApp(
        title: 'FlowFit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoadingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/survey1': (context) => const SurveyScreen1(),
          '/survey2': (context) => const SurveyScreen2(),
          '/survey3': (context) => const SurveyScreen3(),
          '/onboarding1': (context) => const OnboardingScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/trackertest': (context) => const TrackerPage(),
          '/home': (context) => const PhoneHomePage(),
        },
      ),
    );
  }
}
