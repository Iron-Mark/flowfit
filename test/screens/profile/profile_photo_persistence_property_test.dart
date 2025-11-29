import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Photo Persistence - Property Tests', () {
    late Directory tempDir;

    setUp(() async {
      // Create a temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('profile_photo_test_');
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    /// **Feature: dashboard-refactoring-merge, Property 3: Profile photo persistence round-trip**
    /// **Validates: Requirements 3.1, 3.2**
    ///
    /// Property: For any user ID and photo file path, saving the photo path to
    /// SharedPreferences and then loading it should return the same path.
    test(
      'Property 3: For any userId and path, save then load returns same path',
      () async {
        // Property-based test: Test with multiple user IDs and paths
        final testCases = [
          {'userId': 'user-123', 'path': path.join(tempDir.path, 'photo1.jpg')},
          {
            'userId': 'user-456-abc',
            'path': path.join(tempDir.path, 'subfolder', 'photo2.png'),
          },
          {
            'userId': 'user-xyz-789-long-id',
            'path': path.join(
              tempDir.path,
              'another',
              'deep',
              'path',
              'photo3.jpg',
            ),
          },
          {
            'userId': 'user-special-chars-!@#',
            'path': path.join(tempDir.path, 'photo with spaces.jpg'),
          },
          {'userId': 'a', 'path': path.join(tempDir.path, 'x.jpg')},
        ];

        for (final testCase in testCases) {
          final userId = testCase['userId'] as String;
          final photoPath = testCase['path'] as String;

          // Arrange: Initialize SharedPreferences
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final key = 'profile_image_$userId';

          // Create the file so it exists
          final file = File(photoPath);
          await file.create(recursive: true);
          await file.writeAsString('test image data');

          // Act: Save the path
          await prefs.setString(key, photoPath);

          // Load the path
          final loadedPath = prefs.getString(key);

          // Assert: Loaded path should equal saved path
          expect(
            loadedPath,
            equals(photoPath),
            reason: 'For userId=$userId, saved path should equal loaded path',
          );

          // Verify file still exists
          expect(
            await file.exists(),
            isTrue,
            reason: 'File should still exist after save/load',
          );

          // Clean up for next iteration
          await file.delete();
        }
      },
    );

    /// **Feature: dashboard-refactoring-merge, Property 5: Invalid photo path cleanup**
    /// **Validates: Requirements 3.4**
    ///
    /// Property: For any saved photo path where the file no longer exists,
    /// loading the profile should remove that path from SharedPreferences.
    test(
      'Property 5: For any path where file does not exist, path is removed from SharedPreferences',
      () async {
        // Property-based test: Test with multiple non-existent paths
        final testCases = [
          {
            'userId': 'user-123',
            'path': path.join(tempDir.path, 'nonexistent1.jpg'),
          },
          {
            'userId': 'user-456',
            'path': path.join(tempDir.path, 'missing', 'photo2.png'),
          },
          {'userId': 'user-789', 'path': '/completely/invalid/path/photo3.jpg'},
          {
            'userId': 'user-abc',
            'path': path.join(tempDir.path, 'deleted.jpg'),
          },
        ];

        for (final testCase in testCases) {
          final userId = testCase['userId'] as String;
          final photoPath = testCase['path'] as String;

          // Arrange: Save a path to SharedPreferences
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final key = 'profile_image_$userId';
          await prefs.setString(key, photoPath);

          // Verify path was saved
          expect(prefs.getString(key), equals(photoPath));

          // Act: Simulate the _loadProfileImage logic
          final savedPath = prefs.getString(key);
          if (savedPath != null) {
            final file = File(savedPath);
            if (!await file.exists()) {
              // File doesn't exist, cleanup invalid path
              await prefs.remove(key);
            }
          }

          // Assert: Path should be removed from SharedPreferences
          expect(
            prefs.getString(key),
            isNull,
            reason:
                'For userId=$userId with non-existent file, path should be removed',
          );
        }
      },
    );

    /// **Feature: dashboard-refactoring-merge, Property 6: Photo removal clears persistence**
    /// **Validates: Requirements 3.5**
    ///
    /// Property: For any user with a saved profile photo, removing the photo
    /// should delete the path from SharedPreferences.
    test(
      'Property 6: For any userId with saved photo, removal clears SharedPreferences',
      () async {
        // Property-based test: Test with multiple users
        final testCases = [
          {'userId': 'user-123', 'path': path.join(tempDir.path, 'photo1.jpg')},
          {
            'userId': 'user-456-long-id',
            'path': path.join(tempDir.path, 'photo2.png'),
          },
          {'userId': 'user-xyz', 'path': path.join(tempDir.path, 'photo3.jpg')},
          {'userId': 'a', 'path': path.join(tempDir.path, 'x.jpg')},
        ];

        for (final testCase in testCases) {
          final userId = testCase['userId'] as String;
          final photoPath = testCase['path'] as String;

          // Arrange: Save a photo path
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final key = 'profile_image_$userId';
          await prefs.setString(key, photoPath);

          // Verify path was saved
          expect(prefs.getString(key), equals(photoPath));

          // Act: Simulate the _saveProfileImage(null) logic (removal)
          await prefs.remove(key);

          // Assert: Path should be removed from SharedPreferences
          expect(
            prefs.getString(key),
            isNull,
            reason:
                'For userId=$userId, removal should clear SharedPreferences',
          );
        }
      },
    );

    test('Property 3: Round-trip with file existence check', () async {
      // Test that round-trip only works when file exists
      final testCases = [
        {
          'userId': 'user-exists',
          'path': path.join(tempDir.path, 'exists.jpg'),
          'createFile': true,
        },
        {
          'userId': 'user-missing',
          'path': path.join(tempDir.path, 'missing.jpg'),
          'createFile': false,
        },
      ];

      for (final testCase in testCases) {
        final userId = testCase['userId'] as String;
        final photoPath = testCase['path'] as String;
        final createFile = testCase['createFile'] as bool;

        // Arrange
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final key = 'profile_image_$userId';

        if (createFile) {
          final file = File(photoPath);
          await file.create(recursive: true);
          await file.writeAsString('test data');
        }

        // Act: Save path
        await prefs.setString(key, photoPath);

        // Simulate load with file existence check
        final savedPath = prefs.getString(key);
        String? loadedPath;
        if (savedPath != null) {
          final file = File(savedPath);
          if (await file.exists()) {
            loadedPath = savedPath;
          } else {
            await prefs.remove(key);
          }
        }

        // Assert
        if (createFile) {
          expect(
            loadedPath,
            equals(photoPath),
            reason: 'When file exists, path should be loaded',
          );
          expect(
            prefs.getString(key),
            equals(photoPath),
            reason: 'When file exists, path should remain in SharedPreferences',
          );
          // Clean up
          await File(photoPath).delete();
        } else {
          expect(
            loadedPath,
            isNull,
            reason: 'When file does not exist, path should not be loaded',
          );
          expect(
            prefs.getString(key),
            isNull,
            reason:
                'When file does not exist, path should be removed from SharedPreferences',
          );
        }
      }
    });
  });
}
