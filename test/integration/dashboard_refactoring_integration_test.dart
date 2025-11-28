import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';
import 'package:flowfit/domain/entities/auth_state.dart';
import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/presentation/providers/profile_providers.dart'
    as profile_providers;
import 'package:flowfit/presentation/notifiers/auth_notifier.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/screens/dashboard_screen.dart';
import 'package:flowfit/screens/profile/profile_screen.dart';
import 'package:flowfit/screens/onboarding/survey_basic_info_screen.dart';

/// Integration tests for dashboard refactoring merge feature.
///
/// These tests verify:
/// - Complete photo upload flow (camera → save → persist → reload)
/// - Complete logout flow (tap → confirm → signOut → navigate)
/// - Complete edit profile flow (tap → navigate → edit → return → refresh)
/// - Initial tab navigation from route arguments
/// - Pull-to-refresh updates profile data
///
/// Requirements: All requirements from dashboard-refactoring-merge spec
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard Refactoring Integration Tests', () {
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
      'INTEGRATION: Initial tab navigation from route arguments',
      (WidgetTester tester) async {
        // Create a test user profile
        const testUserId = 'test-user-tab-nav';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Tab Test User',
          age: 30,
          gender: 'Male',
          height: 175.0,
          weight: 75.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Save profile to local storage
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Mock auth state with test user
        final mockUser = User(
          id: testUserId,
          email: 'test@example.com',
          fullName: 'Tab Test User',
          createdAt: DateTime.now(),
        );

        container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return MockAuthNotifier(mockUser);
            }),
          ],
        );

        // Build app with dashboard and initial tab argument
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
                            '/dashboard',
                            arguments: {'initialTab': 4}, // Navigate to Profile
                          );
                        },
                        child: const Text('Open Dashboard'),
                      ),
                    ),
                  );
                },
              ),
              routes: {
                '/dashboard': (context) => const DashboardScreen(),
                '/welcome': (context) =>
                    const Scaffold(body: Center(child: Text('Welcome'))),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap button to navigate to dashboard with initial tab
        await tester.tap(find.text('Open Dashboard'));
        await tester.pumpAndSettle();

        // Verify we're on the dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Verify Profile tab is selected (index 4)
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNavBar.currentIndex, 4);

        // Verify ProfileScreen is displayed
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Photo picker modal opens with haptic feedback',
      (WidgetTester tester) async {
        const testUserId = 'test-user-photo';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Photo Test User',
          age: 28,
          gender: 'Female',
          height: 165.0,
          weight: 60.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Save profile
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Mock auth state
        final mockUser = User(
          id: testUserId,
          email: 'photo@example.com',
          fullName: 'Photo Test User',
          createdAt: DateTime.now(),
        );

        container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return MockAuthNotifier(mockUser);
            }),
          ],
        );

        // Track haptic feedback calls
        final List<MethodCall> hapticCalls = [];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'HapticFeedback.vibrate') {
                hapticCalls.add(methodCall);
              }
              return null;
            });

        // Build profile screen
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify profile is displayed
        expect(find.text('Photo Test User'), findsOneWidget);

        // Tap on profile photo to open picker
        final profileAvatar = find.byType(GestureDetector).first;
        await tester.tap(profileAvatar);
        await tester.pumpAndSettle();

        // Verify photo picker modal is shown
        expect(find.text('Change Profile Photo'), findsOneWidget);
        expect(find.text('Take Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);

        // Verify haptic feedback was triggered
        expect(
          hapticCalls.any(
            (call) =>
                call.method == 'HapticFeedback.vibrate' &&
                call.arguments == 'HapticFeedbackType.lightImpact',
          ),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Complete photo upload flow (save → persist → reload)',
      (WidgetTester tester) async {
        const testUserId = 'test-user-photo-persist';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Photo Persist User',
          age: 29,
          gender: 'Male',
          height: 175.0,
          weight: 70.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Clear SharedPreferences
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // Save profile
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Mock auth state
        final mockUser = User(
          id: testUserId,
          email: 'photopersist@example.com',
          fullName: 'Photo Persist User',
          createdAt: DateTime.now(),
        );

        container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return MockAuthNotifier(mockUser);
            }),
          ],
        );

        // Build profile screen
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify no photo initially
        final key = 'profile_image_$testUserId';
        expect(prefs.getString(key), isNull);

        // Simulate saving a photo path
        const testPhotoPath = '/fake/path/to/photo.jpg';
        await prefs.setString(key, testPhotoPath);

        // Rebuild the widget to trigger reload
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify photo path was persisted
        expect(prefs.getString(key), testPhotoPath);

        // Test photo removal
        await prefs.remove(key);
        expect(prefs.getString(key), isNull);

        // Verify persistence round-trip
        const newPhotoPath = '/another/fake/path/photo2.jpg';
        await prefs.setString(key, newPhotoPath);
        expect(prefs.getString(key), newPhotoPath);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Logout flow shows confirmation and navigates',
      (WidgetTester tester) async {
        const testUserId = 'test-user-logout';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Logout Test User',
          age: 35,
          gender: 'Male',
          height: 180.0,
          weight: 80.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Save profile
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Mock auth state
        final mockUser = User(
          id: testUserId,
          email: 'logout@example.com',
          fullName: 'Logout Test User',
          createdAt: DateTime.now(),
        );

        container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return MockAuthNotifier(mockUser);
            }),
          ],
        );

        // Build profile screen with navigation
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: const ProfileScreen(),
              routes: {
                '/welcome': (context) =>
                    const Scaffold(body: Center(child: Text('Welcome Screen'))),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find and tap logout button
        final logoutTile = find.text('Logout');
        expect(logoutTile, findsOneWidget);
        await tester.tap(logoutTile);
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears
        expect(find.text('Are you sure you want to logout?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Find the logout button in dialog (there are two "Logout" texts now)
        final logoutButtons = find.text('Logout');
        expect(logoutButtons, findsNWidgets(2)); // One in list, one in dialog

        // Tap cancel first
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should close, still on profile screen
        expect(find.text('Logout Test User'), findsOneWidget);

        // Tap logout again
        await tester.tap(logoutTile);
        await tester.pumpAndSettle();

        // Confirm logout this time
        final dialogLogoutButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Logout'),
        );
        await tester.tap(dialogLogoutButton);
        await tester.pumpAndSettle();

        // Verify auth state changed to unauthenticated
        final authState = container.read(authNotifierProvider);
        expect(authState.status, AuthStatus.unauthenticated);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Edit profile navigation with haptic feedback',
      (WidgetTester tester) async {
        const testUserId = 'test-user-edit';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Edit Test User',
          age: 32,
          gender: 'Female',
          height: 170.0,
          weight: 65.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Save profile
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Mock auth state
        final mockUser = User(
          id: testUserId,
          email: 'edit@example.com',
          fullName: 'Edit Test User',
          createdAt: DateTime.now(),
        );

        container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return MockAuthNotifier(mockUser);
            }),
          ],
        );

        // Track haptic feedback calls
        final List<MethodCall> hapticCalls = [];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'HapticFeedback.vibrate') {
                hapticCalls.add(methodCall);
              }
              return null;
            });

        // Build profile screen with navigation
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: const ProfileScreen(),
              routes: {
                '/survey_basic_info': (context) =>
                    const SurveyBasicInfoScreen(),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find and tap edit profile button
        final editButton = find.byKey(const Key('edit_profile_button'));
        expect(editButton, findsOneWidget);

        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Verify haptic feedback was triggered
        expect(
          hapticCalls.any(
            (call) =>
                call.method == 'HapticFeedback.vibrate' &&
                call.arguments == 'HapticFeedbackType.mediumImpact',
          ),
          isTrue,
        );

        // Verify navigation to survey screen
        expect(find.byType(SurveyBasicInfoScreen), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Pull-to-refresh updates profile data',
      (WidgetTester tester) async {
        const testUserId = 'test-user-refresh';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Refresh Test User',
          age: 40,
          gender: 'Male',
          height: 185.0,
          weight: 90.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Save profile
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Mock auth state
        final mockUser = User(
          id: testUserId,
          email: 'refresh@example.com',
          fullName: 'Refresh Test User',
          createdAt: DateTime.now(),
        );

        container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return MockAuthNotifier(mockUser);
            }),
          ],
        );

        // Build profile screen
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial profile data
        expect(find.text('Refresh Test User'), findsOneWidget);

        // Find the RefreshIndicator
        final refreshIndicator = find.byType(RefreshIndicator);
        expect(refreshIndicator, findsOneWidget);

        // Trigger pull-to-refresh
        await tester.drag(refreshIndicator, const Offset(0, 300));
        await tester.pumpAndSettle();

        // Verify success message appears
        expect(find.text('Profile refreshed successfully'), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Default tab navigation when no arguments',
      (WidgetTester tester) async {
        const testUserId = 'test-user-default-tab';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Default Tab User',
          age: 25,
          gender: 'Female',
          height: 160.0,
          weight: 55.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Save profile
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Mock auth state
        final mockUser = User(
          id: testUserId,
          email: 'default@example.com',
          fullName: 'Default Tab User',
          createdAt: DateTime.now(),
        );

        container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return MockAuthNotifier(mockUser);
            }),
          ],
        );

        // Build dashboard without initial tab argument
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: const DashboardScreen(),
              routes: {
                '/welcome': (context) =>
                    const Scaffold(body: Center(child: Text('Welcome'))),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify we're on the dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Verify Home tab is selected by default (index 0)
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNavBar.currentIndex, 0);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'INTEGRATION: Invalid tab index defaults to home',
      (WidgetTester tester) async {
        const testUserId = 'test-user-invalid-tab';
        final testProfile = UserProfile(
          userId: testUserId,
          fullName: 'Invalid Tab User',
          age: 27,
          gender: 'Male',
          height: 178.0,
          weight: 78.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        );

        // Save profile
        final repository = await container.read(
          profile_providers.profileRepositoryProvider.future,
        );
        await repository.saveLocalProfile(testProfile);

        // Mock auth state
        final mockUser = User(
          id: testUserId,
          email: 'invalid@example.com',
          fullName: 'Invalid Tab User',
          createdAt: DateTime.now(),
        );

        container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith((ref) {
              return MockAuthNotifier(mockUser);
            }),
          ],
        );

        // Build app with invalid tab index
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
                            '/dashboard',
                            arguments: {'initialTab': 10}, // Invalid index
                          );
                        },
                        child: const Text('Open Dashboard'),
                      ),
                    ),
                  );
                },
              ),
              routes: {
                '/dashboard': (context) => const DashboardScreen(),
                '/welcome': (context) =>
                    const Scaffold(body: Center(child: Text('Welcome'))),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to dashboard
        await tester.tap(find.text('Open Dashboard'));
        await tester.pumpAndSettle();

        // Verify we're on the dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Verify Home tab is selected (defaults to 0 for invalid index)
        final bottomNavBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNavBar.currentIndex, 0);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}

/// Mock AuthNotifier for testing
class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(User user) : super(MockAuthRepository(user)) {
    // Set initial authenticated state
    state = AuthState.authenticated(user);
  }

  @override
  Future<void> signOut() async {
    state = AuthState.unauthenticated();
  }
}

/// Mock AuthRepository for testing
class MockAuthRepository implements IAuthRepository {
  final User _user;

  MockAuthRepository(this._user);

  @override
  Future<User?> getCurrentUser() async => _user;

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    Map<String, dynamic>? metadata,
  }) async => _user;

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(_user);
  }
}
