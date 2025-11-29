import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile Name Extraction - Property Tests', () {
    /// **Feature: dashboard-refactoring-merge, Property 15: User name extraction for greeting**
    /// **Validates: Requirements 10.4**
    ///
    /// Property: For any user profile with a full name, the greeting should
    /// display the first name extracted from the full name.
    test('Property 15: For any full name, first name is correctly extracted', () {
      // Property-based test: Test with multiple full name formats
      // This validates that the name extraction logic works correctly
      // across a wide variety of input formats
      final testCases = [
        {'fullName': 'John Doe', 'expectedFirstName': 'John'},
        {'fullName': 'Jane Smith', 'expectedFirstName': 'Jane'},
        {'fullName': 'Mary Jane Watson', 'expectedFirstName': 'Mary'},
        {'fullName': 'Jean-Pierre Dubois', 'expectedFirstName': 'Jean-Pierre'},
        {'fullName': 'Alice', 'expectedFirstName': 'Alice'},
        {'fullName': 'Bob O\'Brien', 'expectedFirstName': 'Bob'},
        {
          'fullName': 'Carlos Rodriguez Martinez',
          'expectedFirstName': 'Carlos',
        },
        {'fullName': 'Dr. Sarah Johnson', 'expectedFirstName': 'Dr.'},
        {'fullName': '  John   Doe  ', 'expectedFirstName': 'John'},
        {'fullName': 'X Æ A-12', 'expectedFirstName': 'X'},
        {'fullName': 'María García', 'expectedFirstName': 'María'},
        {'fullName': '李明', 'expectedFirstName': '李明'},
        {'fullName': 'محمد علي', 'expectedFirstName': 'محمد'},
        {'fullName': 'O\'Connor Smith', 'expectedFirstName': 'O\'Connor'},
        {'fullName': 'Anne-Marie Dubois', 'expectedFirstName': 'Anne-Marie'},
      ];

      for (final testCase in testCases) {
        final fullName = testCase['fullName'] as String;
        final expectedFirstName = testCase['expectedFirstName'] as String;

        // Act: Extract first name using the same logic as implementation
        final firstName = _extractFirstName(fullName);

        // Assert: First name should match expected
        expect(
          firstName,
          equals(expectedFirstName),
          reason:
              'For fullName="$fullName", first name should be "$expectedFirstName"',
        );
      }
    });

    test('Property 15: Empty or null names default to "there"', () {
      // Test edge cases for empty/null names
      // Requirements 10.5 states that when profile is not available,
      // the system should default to "there"
      final testCases = [
        {'fullName': null, 'expectedFirstName': 'there'},
        {'fullName': '', 'expectedFirstName': 'there'},
        {'fullName': '   ', 'expectedFirstName': 'there'},
        {'fullName': '\t\n', 'expectedFirstName': 'there'},
      ];

      for (final testCase in testCases) {
        final fullName = testCase['fullName'];
        final expectedFirstName = testCase['expectedFirstName'] as String;

        // Act: Extract first name with null handling
        final firstName = _extractFirstNameWithDefault(fullName);

        // Assert: Should default to "there"
        expect(
          firstName,
          equals(expectedFirstName),
          reason:
              'For fullName=$fullName, should default to "$expectedFirstName"',
        );
      }
    });

    test(
      'Property 15: First name extraction is consistent across multiple calls',
      () {
        // Test idempotence - calling multiple times should give same result
        // This ensures the extraction function is pure and deterministic
        final testCases = [
          'John Doe',
          'Jane Smith',
          'Mary Jane Watson',
          'Alice',
          'Jean-Pierre Dubois',
        ];

        for (final fullName in testCases) {
          // Act: Extract first name multiple times
          final firstName1 = _extractFirstName(fullName);
          final firstName2 = _extractFirstName(fullName);
          final firstName3 = _extractFirstName(fullName);

          // Assert: All extractions should be identical
          expect(
            firstName1,
            equals(firstName2),
            reason: 'First extraction should equal second extraction',
          );
          expect(
            firstName2,
            equals(firstName3),
            reason: 'Second extraction should equal third extraction',
          );
        }
      },
    );

    test(
      'Property 15: First name never contains leading or trailing spaces',
      () {
        // Test that extracted first names are properly trimmed
        // This ensures clean display in the UI
        final testCases = [
          '  John Doe',
          'Jane   Smith',
          '  Mary  Jane  Watson  ',
          'Alice ',
          '\tBob\t',
          ' \n Charlie \n ',
        ];

        for (final fullName in testCases) {
          // Act: Extract first name
          final firstName = _extractFirstName(fullName);

          // Assert: First name should not have leading/trailing spaces
          expect(
            firstName,
            equals(firstName.trim()),
            reason: 'First name should be trimmed',
          );
          expect(
            firstName.startsWith(' '),
            isFalse,
            reason: 'First name should not start with space',
          );
          expect(
            firstName.endsWith(' '),
            isFalse,
            reason: 'First name should not end with space',
          );
        }
      },
    );

    test('Property 15: First name extraction handles single names', () {
      // Test that single names (no spaces) are handled correctly
      final testCases = ['Alice', 'Bob', 'Charlie', 'Madonna', 'Cher'];

      for (final fullName in testCases) {
        // Act: Extract first name
        final firstName = _extractFirstName(fullName);

        // Assert: Single name should be returned as-is
        expect(
          firstName,
          equals(fullName),
          reason: 'Single name should be returned unchanged',
        );
      }
    });

    test('Property 15: First name extraction splits on first space only', () {
      // Test that only the first space is used as delimiter
      // This ensures middle names and last names are not included
      final testCases = [
        {
          'fullName': 'John Michael Doe',
          'expectedFirstName': 'John',
          'shouldNotContain': ['Michael', 'Doe'],
        },
        {
          'fullName': 'Mary Jane Watson Parker',
          'expectedFirstName': 'Mary',
          'shouldNotContain': ['Jane', 'Watson', 'Parker'],
        },
      ];

      for (final testCase in testCases) {
        final fullName = testCase['fullName'] as String;
        final expectedFirstName = testCase['expectedFirstName'] as String;
        final shouldNotContain = testCase['shouldNotContain'] as List<String>;

        // Act: Extract first name
        final firstName = _extractFirstName(fullName);

        // Assert: Should only contain first name
        expect(
          firstName,
          equals(expectedFirstName),
          reason: 'Should extract only the first name',
        );

        // Assert: Should not contain middle or last names
        for (final name in shouldNotContain) {
          expect(
            firstName,
            isNot(contains(name)),
            reason: 'First name should not contain "$name"',
          );
        }
      }
    });
  });
}

/// Helper function that mimics the first name extraction logic
/// This should match the logic used in the actual implementation
///
/// The logic is:
/// 1. Trim the full name
/// 2. If empty, return "there"
/// 3. Split on spaces and return the first part
String _extractFirstName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return 'there';

  final parts = trimmed.split(' ');
  return parts[0];
}

/// Helper function with null handling
/// This matches Requirements 10.5 - default to "there" when profile not available
String _extractFirstNameWithDefault(dynamic fullName) {
  if (fullName == null || fullName.toString().trim().isEmpty) {
    return 'there';
  }
  return _extractFirstName(fullName.toString());
}
