# Error Handling and Logging Implementation Guide

## Overview

This document describes the comprehensive error handling and logging system implemented for the profile-onboarding integration feature.

## Components

### 1. Logger (`lib/core/utils/logger.dart`)

A structured logging utility that provides different severity levels:

- **debug**: Development-only information
- **info**: Informational messages
- **warning**: Warning messages for non-critical issues
- **error**: Error messages for failures
- **critical**: Critical errors that require immediate attention

**Usage:**

```dart
final _logger = Logger('ClassName');

_logger.info('Operation completed successfully');
_logger.error('Operation failed', error: e, stackTrace: stackTrace);
```

### 2. Custom Exceptions (`lib/core/exceptions/profile_exceptions.dart`)

Specialized exception classes for different error scenarios:

- **ProfileException**: Base exception for all profile-related errors
- **LocalStorageException**: Local storage operation failures
- **BackendSyncException**: Backend synchronization failures
  - `isNetworkError`: Network connectivity issues
  - `isTimeout`: Request timeout errors
- **ValidationException**: Data validation failures
- **DataMigrationException**: Survey data migration failures
- **SurveyCompletionException**: Survey completion failures

**Usage:**

```dart
throw LocalStorageException(
  'Failed to save profile',
  originalError: e,
  stackTrace: stackTrace,
);
```

### 3. Retry Helper (`lib/core/utils/retry_helper.dart`)

Utility for retrying operations with exponential backoff:

**Features:**

- Configurable max attempts
- Exponential backoff delay
- Automatic detection of retryable errors
- Connectivity checking

**Usage:**

```dart
final result = await RetryHelper.retry(
  operation: () => _repository.saveBackendProfile(profile),
  maxAttempts: 3,
  initialDelay: Duration(seconds: 1),
);
```

### 4. Error Messages (`lib/core/utils/error_messages.dart`)

Helper for generating user-friendly error messages:

**Methods:**

- `getUserMessage(error)`: Get user-friendly message
- `getTechnicalMessage(error)`: Get technical details for logging
- `isRetryable(error)`: Check if error is retryable
- `getRetrySuggestion(error)`: Get retry suggestion message

**Usage:**

```dart
final userMessage = ErrorMessages.getUserMessage(error);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(userMessage)),
);
```

## Error Handling Patterns

### Pattern 1: Local Storage Operations

```dart
try {
  _logger.debug('Saving local profile for user: $userId');

  // Validate before saving
  final validationError = profile.validate();
  if (validationError != null) {
    throw ValidationException(validationError);
  }

  final success = await _prefs.setString(key, jsonString);
  if (!success) {
    throw LocalStorageException('SharedPreferences returned false');
  }

  _logger.info('Successfully saved local profile');
} on ValidationException {
  rethrow;
} catch (e, stackTrace) {
  _logger.error('Error saving local profile', error: e, stackTrace: stackTrace);
  throw LocalStorageException(
    'Failed to save profile to local storage',
    originalError: e,
    stackTrace: stackTrace,
  );
}
```

### Pattern 2: Backend Operations

```dart
try {
  _logger.debug('Fetching backend profile for user: $userId');

  final response = await _supabase
      .from('user_profiles')
      .select()
      .eq('user_id', userId)
      .maybeSingle()
      .timeout(const Duration(seconds: 10));

  _logger.info('Successfully fetched backend profile');
  return UserProfile.fromJson(response);
} on TimeoutException catch (e, stackTrace) {
  _logger.warning('Backend request timed out', error: e, stackTrace: stackTrace);
  throw BackendSyncException(
    'Request timed out',
    originalError: e,
    stackTrace: stackTrace,
    isTimeout: true,
  );
} on SocketException catch (e, stackTrace) {
  _logger.warning('Network error', error: e, stackTrace: stackTrace);
  throw BackendSyncException(
    'Network error: ${e.message}',
    originalError: e,
    stackTrace: stackTrace,
    isNetworkError: true,
  );
} on PostgrestException catch (e, stackTrace) {
  _logger.error('Supabase error', error: e, stackTrace: stackTrace);
  throw BackendSyncException(
    'Backend error: ${e.message}',
    originalError: e,
    stackTrace: stackTrace,
  );
}
```

### Pattern 3: Graceful Degradation

```dart
try {
  // Try primary operation
  final backendProfile = await _repository.getBackendProfile(userId);
  state = AsyncValue.data(backendProfile);
} on BackendSyncException catch (e, stackTrace) {
  // Backend failed, but we have local data
  if (localProfile != null) {
    _logger.warning('Backend fetch failed, using local data', error: e);
    // Keep showing local data
  } else {
    // No fallback available
    _logger.error('No local profile and backend fetch failed', error: e);
    rethrow;
  }
}
```

### Pattern 4: User-Facing Error Messages

```dart
try {
  await handler.completeSurvey(userId, surveyData);

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Profile saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
} catch (e) {
  if (mounted) {
    final errorMessage = ErrorMessages.getUserMessage(e);
    final isRetryable = ErrorMessages.isRetryable(e);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: isRetryable
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _handleComplete,
              )
            : null,
      ),
    );
  }
}
```

## Edge Cases Handled

### 1. Null Data

- All methods check for null values before processing
- Default values provided via `UserProfile.withDefaults()`
- Graceful handling of missing optional fields

### 2. Invalid Formats

- JSON parsing errors caught with `FormatException`
- Validation performed before saving
- Corrupted data cleared and logged

### 3. Network Issues

- Timeout handling with configurable durations
- Network error detection via `SocketException`
- Automatic queuing for retry when offline

### 4. Concurrent Operations

- Sync queue prevents concurrent processing
- State management ensures UI consistency
- Last-write-wins conflict resolution

### 5. Storage Failures

- SharedPreferences failures logged and thrown
- Fallback to backend when local storage fails
- Queue persistence for retry operations

## Logging Strategy

### Development

- All log levels enabled
- Detailed stack traces
- Debug information for troubleshooting

### Production

- Info, Warning, Error, and Critical levels
- Sanitized error messages (no PII)
- Integration with analytics services (future)

## Testing Error Handling

### Unit Tests

```dart
test('handles local storage exception', () async {
  // Arrange
  when(() => prefs.setString(any(), any())).thenThrow(Exception('Storage full'));

  // Act & Assert
  expect(
    () => repository.saveLocalProfile(profile),
    throwsA(isA<LocalStorageException>()),
  );
});
```

### Integration Tests

```dart
testWidgets('shows error message on save failure', (tester) async {
  // Arrange
  when(() => handler.completeSurvey(any(), any())).thenThrow(
    LocalStorageException('Failed to save'),
  );

  // Act
  await tester.tap(find.text('COMPLETE & START APP'));
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Failed to save profile'), findsOneWidget);
});
```

## Best Practices

1. **Always log errors** with context (user ID, operation, etc.)
2. **Use specific exception types** for different error scenarios
3. **Provide user-friendly messages** in the UI
4. **Include retry mechanisms** for transient errors
5. **Validate data** before operations
6. **Handle edge cases** explicitly
7. **Test error paths** thoroughly
8. **Monitor logs** in production

## Future Enhancements

1. **Analytics Integration**: Send error logs to Firebase Crashlytics
2. **Error Reporting**: User-initiated error reports
3. **Offline Queue UI**: Show pending sync items to users
4. **Advanced Retry**: Configurable retry strategies per operation
5. **Error Recovery**: Automatic recovery from common errors
