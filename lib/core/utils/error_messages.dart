import '../exceptions/profile_exceptions.dart';

/// Helper class for generating user-friendly error messages
class ErrorMessages {
  /// Get user-friendly error message from exception
  static String getUserMessage(Object error) {
    if (error is LocalStorageException) {
      return 'Failed to save data locally. Please check your device storage.';
    }

    if (error is BackendSyncException) {
      if (error.isNetworkError) {
        return 'No internet connection. Your changes are saved locally and will sync when online.';
      }
      if (error.isTimeout) {
        return 'Request timed out. Please check your internet connection.';
      }
      return 'Failed to sync with server. Your changes are saved locally.';
    }

    if (error is ValidationException) {
      return error.message;
    }

    if (error is DataMigrationException) {
      return 'Failed to process your data. Please try again.';
    }

    if (error is SurveyCompletionException) {
      return 'Failed to complete survey. Please try again.';
    }

    if (error is ProfileException) {
      return error.message;
    }

    // Generic error message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Get technical error message for logging
  static String getTechnicalMessage(Object error) {
    if (error is ProfileException) {
      final buffer = StringBuffer();
      buffer.write(error.message);
      if (error.originalError != null) {
        buffer.write(' | Original error: ${error.originalError}');
      }
      return buffer.toString();
    }

    return error.toString();
  }

  /// Check if error is retryable
  static bool isRetryable(Object error) {
    if (error is BackendSyncException) {
      return error.isNetworkError || error.isTimeout;
    }

    if (error is LocalStorageException) {
      return false; // Local storage errors are not retryable
    }

    if (error is ValidationException) {
      return false; // Validation errors need user correction
    }

    return false;
  }

  /// Get retry suggestion message
  static String? getRetrySuggestion(Object error) {
    if (error is BackendSyncException) {
      if (error.isNetworkError) {
        return 'Please check your internet connection and try again.';
      }
      if (error.isTimeout) {
        return 'The request took too long. Please try again.';
      }
      return 'Please try again in a few moments.';
    }

    if (isRetryable(error)) {
      return 'Please try again.';
    }

    return null;
  }
}
