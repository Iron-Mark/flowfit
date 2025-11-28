import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/profile/profile_screen.dart';
import 'package:flowfit/presentation/providers/profile_providers.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/core/domain/repositories/profile_repository.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/presentation/providers/providers.dart'
    hide profileRepositoryProvider;
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Sync Status - Property Tests', () {
    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
    });

    /// **Feature: dashboard-refactoring-merge, Property 10: Sync status determines UI display**
    /// **Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5, 5.6**
    ///
    /// Property: For any sync status value, the sync status bar should display
    /// the appropriate UI elements (message, color, visibility) corresponding
    /// to that status.
    testWidgets('Property 10: Syncing status shows correct UI', (
      WidgetTester tester,
    ) async {
      // Test syncing status
      final mockRepository = MockProfileRepository(
        syncStatus: SyncStatus.syncing,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            profileRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockRepository, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.syncing),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Syncing text should be visible
      expect(
        find.text('Syncing...'),
        findsOneWidget,
        reason: 'Syncing status should show "Syncing..." text',
      );
    });

    testWidgets(
      'Property 10: Pending sync status shows correct UI with count',
      (WidgetTester tester) async {
        // Test pending sync status with count
        final mockRepository = MockProfileRepository(
          syncStatus: SyncStatus.pendingSync,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(MockAuthRepository()),
              profileRepositoryProvider.overrideWith(
                (ref) async => mockRepository,
              ),
              profileNotifierProvider.overrideWith((ref, userId) {
                return MockProfileNotifier(mockRepository, userId);
              }),
              syncStatusProvider.overrideWith(
                (ref, userId) => Stream.value(SyncStatus.pendingSync),
              ),
              pendingSyncCountProvider.overrideWith((ref) async => 3),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Assert: Pending sync text with count should be visible
        expect(
          find.text('Pending sync (3)'),
          findsOneWidget,
          reason: 'Pending sync status should show count',
        );
      },
    );

    testWidgets('Property 10: Pending sync status without count', (
      WidgetTester tester,
    ) async {
      // Test pending sync status with zero count
      final mockRepository = MockProfileRepository(
        syncStatus: SyncStatus.pendingSync,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            profileRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockRepository, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.pendingSync),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Pending sync text without count should be visible
      expect(
        find.text('Pending sync'),
        findsOneWidget,
        reason: 'Pending sync status should show without count when count is 0',
      );
    });

    testWidgets('Property 10: Sync failed status shows correct UI', (
      WidgetTester tester,
    ) async {
      // Test sync failed status
      final mockRepository = MockProfileRepository(
        syncStatus: SyncStatus.syncFailed,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            profileRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockRepository, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.syncFailed),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Sync failed text should be visible
      expect(
        find.text('Sync failed - will retry'),
        findsOneWidget,
        reason: 'Sync failed status should show error message',
      );
    });

    testWidgets('Property 10: Offline status shows correct UI', (
      WidgetTester tester,
    ) async {
      // Test offline status
      final mockRepository = MockProfileRepository(
        syncStatus: SyncStatus.offline,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            profileRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockRepository, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.offline),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Offline text should be visible
      expect(
        find.text('Offline'),
        findsOneWidget,
        reason: 'Offline status should show "Offline" text',
      );
    });

    testWidgets('Property 10: Synced status hides the bar', (
      WidgetTester tester,
    ) async {
      // Test synced status - bar should be hidden
      final mockRepository = MockProfileRepository(
        syncStatus: SyncStatus.synced,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            profileRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
            profileNotifierProvider.overrideWith((ref, userId) {
              return MockProfileNotifier(mockRepository, userId);
            }),
            syncStatusProvider.overrideWith(
              (ref, userId) => Stream.value(SyncStatus.synced),
            ),
            pendingSyncCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: No sync status messages should be visible
      expect(
        find.text('Syncing...'),
        findsNothing,
        reason: 'Synced status should hide the bar',
      );
      expect(
        find.text('Pending sync'),
        findsNothing,
        reason: 'Synced status should hide the bar',
      );
      expect(
        find.text('Sync failed - will retry'),
        findsNothing,
        reason: 'Synced status should hide the bar',
      );
      expect(
        find.text('Offline'),
        findsNothing,
        reason: 'Synced status should hide the bar',
      );
    });
  });
}

/// Mock ProfileNotifier that doesn't auto-load
class MockProfileNotifier extends ProfileNotifier {
  MockProfileNotifier(ProfileRepository repository, String userId)
    : super(repository, userId) {
    // Override state with pre-loaded data to avoid auto-loading
    state = AsyncValue.data(
      UserProfile(
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

  @override
  Future<void> loadProfile() async {
    // Don't actually load - keep the pre-set state
  }
}

/// Mock ProfileRepository for testing
class MockProfileRepository implements ProfileRepository {
  final SyncStatus syncStatus;

  MockProfileRepository({this.syncStatus = SyncStatus.synced});

  @override
  Future<UserProfile?> getLocalProfile(String userId) async {
    return UserProfile(
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
  Future<void> saveLocalProfile(UserProfile profile) async {}

  @override
  Future<void> deleteLocalProfile(String userId) async {}

  @override
  Future<UserProfile?> getBackendProfile(String userId) async => null;

  @override
  Future<void> saveBackendProfile(UserProfile profile) async {}

  @override
  Future<void> syncProfile(String userId) async {}

  @override
  Future<bool> hasPendingSync(String userId) async => false;

  @override
  Stream<SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(syncStatus);
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async => true;
}

/// Mock AuthRepository for testing
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
  Future<void> signOut() async {}

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
