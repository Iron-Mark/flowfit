/// Base exception for profile-related errors
class ProfileException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  ProfileException(this.message, {this.originalError, this.stackTrace});

  @override
  String toString() => 'ProfileException: $message';
}

/// Exception thrown when local storage operations fail
class LocalStorageException extends ProfileException {
  LocalStorageException(super.message, {super.originalError, super.stackTrace});

  @override
  String toString() => 'LocalStorageException: $message';
}

/// Exception thrown when backend operations fail
class BackendSyncException extends ProfileException {
  final bool isNetworkError;
  final bool isTimeout;

  BackendSyncException(
    super.message, {
    super.originalError,
    super.stackTrace,
    this.isNetworkError = false,
    this.isTimeout = false,
  });

  @override
  String toString() => 'BackendSyncException: $message';
}

/// Exception thrown when data validation fails
class ValidationException extends ProfileException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    super.message, {
    super.originalError,
    super.stackTrace,
    this.fieldErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception thrown when data migration fails
class DataMigrationException extends ProfileException {
  DataMigrationException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'DataMigrationException: $message';
}

/// Exception thrown when survey completion fails
class SurveyCompletionException extends ProfileException {
  SurveyCompletionException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'SurveyCompletionException: $message';
}
