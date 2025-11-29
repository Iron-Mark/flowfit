import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/profile/profile_screen.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart' as core;
import 'package:flowfit/domain/entities/user_profile.dart' as domain;
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Edit Navigation - Unit Tests', () {
    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });

    /// Test: Navigation occurs to correct route
    /// Requirements: 7.2
    testWidgets('navigation occurs to survey_basic_info route', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with mock auth repository
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();
      bool surveyBasicInfoRouteVisited = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/survey_basic_info': (context) {
                surveyBasicInfoRouteVisited = true;
                return const Scaffold(
                  body: Center(child: Text('Survey Basic Info Screen')),
                );
              },
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the edit profile button
      final editButton = find.byKey(const Key('edit_profile_button'));
      expect(editButton, findsOneWidget);

      // Act: Tap the edit profile button
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Assert: Should navigate to survey_basic_info route
      expect(surveyBasicInfoRouteVisited, isTrue);
      expect(find.text('Survey Basic Info Screen'), findsOneWidget);
    });

    /// Test: Route arguments include userId and fromEdit flag
    /// Requirements: 7.3
    testWidgets('route arguments include userId and fromEdit flag', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with mock auth repository
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();
      Map<String, dynamic>? capturedArguments;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/survey_basic_info') {
                capturedArguments = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Center(child: Text('Survey Basic Info Screen')),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the edit profile button
      final editButton = find.byKey(const Key('edit_profile_button'));
      expect(editButton, findsOneWidget);

      // Act: Tap the edit profile button
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Assert: Arguments should include userId and fromEdit flag
      expect(capturedArguments, isNotNull);
      expect(capturedArguments!['userId'], equals('test-user-123'));
      expect(capturedArguments!['fromEdit'], isTrue);
    });

    /// Test: Haptic feedback is triggered
    /// Requirements: 7.1
    testWidgets('haptic feedback is triggered on edit profile tap', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen with mock auth repository
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();
      final List<MethodCall> hapticCalls = [];

      // Set up method channel to capture haptic feedback calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall methodCall,
          ) async {
            hapticCalls.add(methodCall);
            return null;
          });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/survey_basic_info': (context) => const Scaffold(
                body: Center(child: Text('Survey Basic Info Screen')),
              ),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the edit profile button
      final editButton = find.byKey(const Key('edit_profile_button'));
      expect(editButton, findsOneWidget);

      // Act: Tap the edit profile button
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Assert: Haptic feedback should have been triggered
      expect(
        hapticCalls.any(
          (call) =>
              call.method == 'HapticFeedback.vibrate' &&
              call.arguments == 'HapticFeedbackType.mediumImpact',
        ),
        isTrue,
        reason: 'Medium impact haptic feedback should be triggered',
      );

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    /// Test: Edit button is visible and accessible
    /// Requirements: 7.1
    testWidgets('edit profile button is visible and accessible', (
      WidgetTester tester,
    ) async {
      // Arrange: Build ProfileScreen
      final mockAuthRepo = MockAuthRepository();
      final mockProfileRepo = MockProfileRepository();
      final mockCoreProfileRepo = MockCoreProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockCoreProfileRepo, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: const ProfileScreen(),
            routes: {
              '/survey_basic_info': (context) => const Scaffold(
                body: Center(child: Text('Survey Basic Info Screen')),
              ),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Edit button should be visible
      final editButton = find.byKey(const Key('edit_profile_button'));
      expect(editButton, findsOneWidget);

      // Verify it's an IconButton
      expect(find.byType(IconButton), findsWidgets);

      // Verify the button is enabled
      final iconButton = tester.widget<IconButton>(editButton);
      expect(iconButton.onPressed, isNotNull);
    });
  });
}

/// Mock AuthRepository for basic testing
class MockAuthRepository implements IAuthRepository {
  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: fullName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    return User(
      id: 'test-user-123',
      email: email,
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {
    // Mock successful sign out
  }

  @override
  Future<User?> getCurrentUser() async {
    return User(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Test User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(
      User(
        id: 'test-user-123',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Mock ProfileRepository for IProfileRepository interface
class MockProfileRepository implements IProfileRepository {
  @override
  Future<domain.UserProfile> createProfile(domain.UserProfile profile) async {
    return profile;
  }

  @override
  Future<domain.UserProfile> updateProfile(domain.UserProfile profile) async {
    return profile;
  }

  @override
  Future<domain.UserProfile?> getProfile(String userId) async {
    return domain.UserProfile(
      userId: userId,
      fullName: 'Test User',
      age: 30,
      gender: 'Male',
      weight: 70.0,
      weightUnit: 'kg',
      height: 175.0,
      heightUnit: 'cm',
      activityLevel: 'Moderate',
      goals: ['Fitness'],
      dailyCalorieTarget: 2000,
      surveyCompleted: true,
    );
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return true;
  }
}

/// Mock ProfileRepository for ProfileRepository (core domain)
class MockCoreProfileRepository implements ProfileRepository {
  final SyncStatus syncStatus;

  MockCoreProfileRepository({this.syncStatus = SyncStatus.synced});

  @override
  Future<core.UserProfile?> getLocalProfile(String userId) async {
    return core.UserProfile(
      userId: userId,
      fullName: 'Test User',
      age: 30,
      gender: 'Male',
      weight: 70.0,
      weightUnit: 'kg',
      height: 175.0,
      heightUnit: 'cm',
      activityLevel: 'Moderate',
      goals: ['Fitness'],
      dailyCalorieTarget: 2000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: true,
    );
  }

  @override
  Future<void> saveLocalProfile(core.UserProfile profile) async {
    // Mock save
  }

  @override
  Future<void> deleteLocalProfile(String userId) async {
    // Mock delete
  }

  @override
  Future<core.UserProfile?> getBackendProfile(String userId) async {
    return getLocalProfile(userId);
  }

  @override
  Future<void> saveBackendProfile(core.UserProfile profile) async {
    // Mock save
  }

  @override
  Future<void> syncProfile(String userId) async {
    // Mock sync
  }

  @override
  Future<bool> hasPendingSync(String userId) async {
    return false;
  }

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(syncStatus);
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return true;
  }
}

/// Mock ProfileNotifier
class MockProfileNotifier extends ProfileNotifier {
  MockProfileNotifier(super.repository, super.userId);

  @override
  Future<void> loadProfile() async {
    state = AsyncValue.data(
      core.UserProfile(
        userId: userId,
        fullName: 'Test User',
        age: 30,
        gender: 'Male',
        weight: 70.0,
        weightUnit: 'kg',
        height: 175.0,
        heightUnit: 'cm',
        activityLevel: 'Moderate',
        goals: ['Fitness'],
        dailyCalorieTarget: 2000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: true,
      ),
    );
  }
}
