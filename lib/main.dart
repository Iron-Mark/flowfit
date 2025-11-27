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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secrets.dart';
import 'theme/app_theme.dart';
import 'utils/deep_link_handler.dart';
import 'screens/loading_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/phone_home.dart';
import 'screens/phone/phone_heart_rate_screen.dart';
import 'screens/onboarding/survey_intro_screen.dart';
import 'screens/onboarding/survey_basic_info_screen.dart';
import 'screens/onboarding/survey_body_measurements_screen.dart';
import 'screens/onboarding/survey_activity_goals_screen.dart';
import 'screens/onboarding/survey_daily_targets_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/font_demo_screen.dart';
import 'screens/profile/settings/general/privacy_policy_screen.dart';
import 'screens/profile/settings/settings_screen.dart';
import 'screens/profile/settings/general/notification_settings_screen.dart';
import 'screens/profile/settings/general/app_integration_screen.dart';
import 'screens/profile/settings/general/language_settings_screen.dart';
import 'screens/profile/settings/general/unit_settings_screen.dart';
import 'screens/profile/settings/general/terms_of_service_screen.dart';
import 'screens/profile/settings/general/help_support_screen.dart';
import 'screens/profile/settings/general/about_us_screen.dart';
import 'screens/profile/settings/change_password_screen.dart';
import 'screens/profile/settings/delete_account_screen.dart';
import 'screens/profile/goals/weight_goals_screen.dart';
import 'screens/profile/goals/fitness_goals_screen.dart';
import 'screens/profile/goals/nutrition_goals_screen.dart';
import 'widgets/debug_route_menu.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with configuration from secrets and deep link support
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // Use PKCE flow for mobile security
    ),
  );

  // Initialize deep link handler
  DeepLinkHandler().initialize();

  runApp(const ProviderScope(child: FlowFitPhoneApp()));
}

class FlowFitPhoneApp extends StatelessWidget {
  const FlowFitPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String initialRoute = String.fromEnvironment(
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
          '/': (context) => const SplashScreen(),
          '/loading': (context) => const LoadingScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/email_verification': (context) => const EmailVerificationScreen(),
          // Survey flow (4 steps)
          '/survey_intro': (context) => const SurveyIntroScreen(), // Step 0
          '/survey_basic_info': (context) =>
              const SurveyBasicInfoScreen(), // Step 1
          '/survey_body_measurements': (context) =>
              const SurveyBodyMeasurementsScreen(), // Step 2
          '/survey_activity_goals': (context) =>
              const SurveyActivityGoalsScreen(), // Step 3
          '/survey_daily_targets': (context) =>
              const SurveyDailyTargetsScreen(), // Step 4
          '/onboarding1': (context) => const OnboardingScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/trackertest': (context) => const TrackerPage(),
          '/mission': (context) => const MapsPageWrapper(),
          '/home': (context) => const PhoneHomePage(),
          '/phone_heart_rate': (context) => const PhoneHeartRateScreen(),
          '/font-demo': (context) => const FontDemoScreen(),
          '/privacy-policy': (context) => const PrivacyPolicyScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/notification-settings': (context) =>
              const NotificationSettingsScreen(),
          '/app-integration': (context) => const AppIntegrationScreen(),
          '/language-settings': (context) => const LanguageSettingsScreen(),
          '/unit-settings': (context) => const UnitSettingsScreen(),
          '/terms-of-service': (context) => const TermsOfServiceScreen(),
          '/help-support': (context) => const HelpSupportScreen(),
          '/change-password': (context) => const ChangePasswordScreen(),
          '/delete-account': (context) => const DeleteAccountScreen(),
          '/weight-goals': (context) => const WeightGoalsScreen(),
          '/fitness-goals': (context) => const FitnessGoalsScreen(),
          '/nutrition-goals': (context) => const NutritionGoalsScreen(),
          '/about-us': (context) => const AboutUsScreen(),
        },
      ),
    );
  }
}
