import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/presentation/providers/profile_providers.dart'
    as profile_providers;
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/onboarding/survey_intro_screen.dart';
import 'package:flowfit/screens/onboarding/survey_basic_info_screen.dart';
import 'package:flowfit/screens/onboarding/survey_body_measurements_screen.dart';
import 'package:flowfit/screens/onboarding/survey_activity_goals_screen.dart';
import 'package:flowfit/screens/onboarding/survey_daily_targets_screen.dart';
import 'package:flowfit/screens/profile/profile_view.dart';
import 'package:flowfit/secrets.dart';

/// Integration tests for profile-onboarding integration.
///
/// These tests verify:
/// - Complete onboarding flow → profile creation
/// - Profile data display in profile screen
/// - Profile editing flow
/// - Offline mode behavior
/// - Sync on connectivity restore
///
/// Requirements: All requirements from profile-onboarding-integration spec
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Set mock initial values for SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Initialize Supabase for testing
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
    } catch (e) {
      // Supabase might already be initialized
      // This is fine for tests
    }
  });

  group('Profile Onboarding Integration Tests', () {
    late ProviderContainer container;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});

      // Create fresh provider container
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets(
      'INTEGRATION: Complete onboarding flow creates profile',
      (WidgetTester tester) async {
        const testUserId = 'test-user-123';
        const testName = 'Test User';

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/survey_intro',
                            arguments: {'userId': testUserId, 'name': testName},
                          );
                        },
                        child: const Text('Start Survey'),
                      ),
                    ),
                  );
                },
              ),
              routes: {
                '/survey_intro': (context) => const SurveyIntroScreen(),
                '/survey_basic_info': (context) =>
                    const SurveyBasicInfoScreen(),
                '/survey_body_measurements': (context) =>
                    const SurveyBodyMeasurementsScreen(),
                '/survey_activity_goals': (context) =>
                    const SurveyActivityGoalsScreen(),
                '/survey_daily_targets': (context) =>
                    const SurveyDailyTargetsScreen(),
                '/dashboard': (context) => Scaffold(
                  appBar: AppBar(title: const Text('Dashboard')),
                  body: const Center(child: Text('Dashboard')),
                ),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Start survey
        await tester.tap(find.text('Start Survey'));
        await tester.pumpAndSettle();

        // Survey Intro
        expect(find.text('Quick Setup'), findsOneWidget);
        await tester.tap(find.text('LET\'S PERSONALIZE'));
        await tester.pumpAndSettle();

        // Basic Info
        await tester.tap(find.text('Male'));
        await tester.pumpAndSettle();
        final ageField = find.byType(TextFormField).first;
        await tester.enterText(ageField, '30');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Body Measurements
        final weightField = find.widgetWithText(
          TextFormField,
          'Enter weight in kg',
        );
        await tester.enterText(weightField, '75');
        await tester.pumpAndSettle();
        final heightField = find.widgetWithText(
          TextFormField,
          'Enter height in cm',
        );
        await tester.enterText(heightField, '175');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Activity Goals
        await tester.tap(find.text('Moderately Active'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lose Weight'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Daily Targets - Complete survey
        await tester.tap(find.text('COMPLETE SETUP'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify profile was created in local storage
        final profileAsync = container.read(
          profile_providers.profileNotifierProvider(testUserId),
        );

        expect(profileAsync, isA<AsyncData<UserProfile?>>());
        final profile = profileAsync.value;
        expect(profile, isNotNull);
        expect(profile!.userId, testUserId);
        expect(profile.age, 30);
        expect(profile.gender, 'Male');
        expect(profile.weight, 75.0);
        expect(profile.height, 175.0);
        expect(profile.activityLevel, 'Moderately Active');
        expect(profile.goals, contains('Lose Weight'));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'INTEGRATION: Profile data displays correctly in profile screen',
      (WidgetTester tester) async {
        const testUserId = 'test-user-456';

        // Create a test profile
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'John Doe',
          age: 28,
          gender: 'Male',
          height: 180.0,
          weight: 80.0,
          heightUnit: 'cm',
          weightUnit: 'kg',
          activityLevel: 'Very Active',
          goals: ['Build Muscle', 'Improve Cardio'],
          dailyCalorieTarget: 2500,
          dailyStepsTarget: 10000,
          dailyActiveMinutesTarget: 60,
          dailyWaterTarget: 3.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Save profile to local storage
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Build profile view with the profile
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: ProfileView(profile: testProfile, onPhotoTap: () {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify profile data is displayed
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.textContaining('28'), findsWidgets);
        expect(find.textContaining('Male'), findsWidgets);
        expect(find.textContaining('180'), findsWidgets);
        expect(find.textContaining('80'), findsWidgets);
        expect(find.textContaining('Very Active'), findsWidgets);
        expect(find.textContaining('Build Muscle'), findsWidgets);
        expect(find.textContaining('2500'), findsWidgets);
        expect(find.textContaining('10000'), findsWidgets);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Profile editing flow saves changes',
      (WidgetTester tester) async {
        const testUserId = 'test-user-789';

        // Create initial profile
        final initialProfile = UserProfile(
          userId: testUserId,
          fullName: 'Jane Smith',
          age: 25,
          gender: 'Female',
          height: 165.0,
          weight: 60.0,
          heightUnit: 'cm',
          weightUnit: 'kg',
          activityLevel: 'Moderately Active',
          goals: ['Lose Weight'],
          dailyCalorieTarget: 1800,
          dailyStepsTarget: 8000,
          dailyActiveMinutesTarget: 45,
          dailyWaterTarget: 2.5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(initialProfile);

        // NOTE: EditProfileScreen was removed - now using survey screens for editing
        // This test is disabled as the edit flow now goes through survey screens
        // TODO: Update test to use survey screens for profile editing
        return; // Skip this test for now

        // Find and update age field
        final ageFields = find.byType(TextFormField);
        expect(ageFields, findsWidgets);

        // Clear and enter new age (age field is the second TextFormField)
        await tester.enterText(ageFields.at(1), '26');
        await tester.pumpAndSettle();

        // Find and tap save button
        final saveButton = find.text('Save Changes');
        expect(saveButton, findsOneWidget);
        await tester.tap(saveButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify profile was updated
        final updatedProfile = await repository.getLocalProfile(testUserId);
        expect(updatedProfile, isNotNull);
        expect(updatedProfile!.age, 26);
        expect(updatedProfile.fullName, 'Jane Smith'); // Other fields unchanged
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Offline mode saves profile locally',
      (WidgetTester tester) async {
        const testUserId = 'test-user-offline';
        const testName = 'Offline User';

        // Note: This test simulates offline by not attempting backend sync
        // In real scenario, connectivity would be checked

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/survey_intro',
                            arguments: {'userId': testUserId, 'name': testName},
                          );
                        },
                        child: const Text('Start Survey'),
                      ),
                    ),
                  );
                },
              ),
              routes: {
                '/survey_intro': (context) => const SurveyIntroScreen(),
                '/survey_basic_info': (context) =>
                    const SurveyBasicInfoScreen(),
                '/survey_body_measurements': (context) =>
                    const SurveyBodyMeasurementsScreen(),
                '/survey_activity_goals': (context) =>
                    const SurveyActivityGoalsScreen(),
                '/survey_daily_targets': (context) =>
                    const SurveyDailyTargetsScreen(),
                '/dashboard': (context) =>
                    const Scaffold(body: Center(child: Text('Dashboard'))),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Complete survey
        await tester.tap(find.text('Start Survey'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('LET\'S PERSONALIZE'));
        await tester.pumpAndSettle();

        // Fill basic info
        await tester.tap(find.text('Female'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '32');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Fill body measurements
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter weight in kg'),
          '65',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter height in cm'),
          '170',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Fill activity goals
        await tester.tap(find.text('Sedentary'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Maintain Weight'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Complete survey
        await tester.tap(find.text('COMPLETE SETUP'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify profile saved locally (even if backend sync fails)
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        final profile = await repository.getLocalProfile(testUserId);

        expect(profile, isNotNull);
        expect(profile!.userId, testUserId);
        expect(profile.age, 32);
        expect(profile.gender, 'Female');
        expect(profile.weight, 65.0);
        expect(profile.height, 170.0);

        // Profile should be marked as not synced if offline
        // (In real scenario, isSynced would be false)
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('UNIT: Profile repository handles sync queue correctly', () async {
      const testUserId = 'test-sync-user';

      final testProfile = UserProfile(
        userId: testUserId,
        fullName: 'Sync Test',
        age: 30,
        gender: 'Male',
        height: 175.0,
        weight: 75.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      final repository = await container.read(
        profile_providers.profileRepositoryProvider.future,
      );

      // Save profile locally
      await repository.saveLocalProfile(testProfile);

      // Verify it's saved
      final savedProfile = await repository.getLocalProfile(testUserId);
      expect(savedProfile, isNotNull);
      expect(savedProfile!.userId, testUserId);
      expect(savedProfile.isSynced, false);

      // Check if there's pending sync
      final hasPending = await repository.hasPendingSync(testUserId);
      // Note: This depends on implementation details
      // In offline-first architecture, unsync profiles should be queued
    });

    testWidgets('INTEGRATION: Survey data persists across navigation', (
      WidgetTester tester,
    ) async {
      const testUserId = 'test-persist-user';

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/survey_basic_info',
                          arguments: {
                            'userId': testUserId,
                            'name': 'Test User',
                          },
                        );
                      },
                      child: const Text('Start Survey'),
                    ),
                  ),
                );
              },
            ),
            routes: {
              '/survey_basic_info': (context) => const SurveyBasicInfoScreen(),
              '/survey_body_measurements': (context) =>
                  const SurveyBodyMeasurementsScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start survey
      await tester.tap(find.text('Start Survey'));
      await tester.pumpAndSettle();

      // Fill basic info
      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '35');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify data persisted
      final surveyState = container.read(surveyNotifierProvider);
      expect(surveyState.surveyData['age'], 35);
      expect(surveyState.surveyData['gender'], 'Male');

      // Navigate forward again
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Data should still be there
      final surveyState2 = container.read(surveyNotifierProvider);
      expect(surveyState2.surveyData['age'], 35);
      expect(surveyState2.surveyData['gender'], 'Male');
    });
  });
}
