import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/profile_exceptions.dart';
import 'logger.dart';

/// Helper class for retrying operations with exponential backoff
class RetryHelper {
  static final _logger = Logger('RetryHelper');

  /// Retry an operation with exponential backoff
  ///
  /// Parameters:
  /// - [operation]: The async operation to retry
  /// - [maxAttempts]: Maximum number of retry attempts (default: 3)
  /// - [initialDelay]: Initial delay before first retry (default: 1 second)
  /// - [maxDelay]: Maximum delay between retries (default: 10 seconds)
  /// - [shouldRetry]: Optional function to determine if error is retryable
  ///
  /// Returns the result of the operation if successful
  /// Throws the last error if all retries fail
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
    bool Function(Object error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;

      try {
        _logger.debug('Attempting operation (attempt $attempt/$maxAttempts)');
        return await operation();
      } catch (error, stackTrace) {
        final isLastAttempt = attempt >= maxAttempts;
        final isRetryable =
            shouldRetry?.call(error) ?? _isRetryableError(error);

        _logger.warning(
          'Operation failed (attempt $attempt/$maxAttempts)',
          error: error,
          stackTrace: stackTrace,
        );

        if (isLastAttempt || !isRetryable) {
          _logger.error(
            'Operation failed after $attempt attempts',
            error: error,
            stackTrace: stackTrace,
          );
          rethrow;
        }

        // Wait before retrying with exponential backoff
        _logger.debug('Retrying after ${delay.inSeconds}s delay');
        await Future.delayed(delay);

        // Increase delay for next retry (exponential backoff)
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(
            initialDelay.inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
  }

  /// Determine if an error is retryable
  static bool _isRetryableError(Object error) {
    // Network errors are retryable
    if (error is SocketException) {
      return true;
    }

    // Timeout errors are retryable
    if (error is TimeoutException) {
      return true;
    }

    // Supabase errors - check if retryable
    if (error is PostgrestException) {
      // Server errors (5xx) are retryable
      if (error.code != null && error.code!.startsWith('5')) {
        return true;
      }
      // Rate limiting (429) is retryable
      if (error.code == '429') {
        return true;
      }
      // Client errors (4xx) are generally not retryable
      return false;
    }

    // Backend sync exceptions - check if retryable
    if (error is BackendSyncException) {
      return error.isNetworkError || error.isTimeout;
    }

    // Other errors are not retryable by default
    return false;
  }

  /// Check if device has internet connectivity
  static Future<bool> hasConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _logger.debug('Connectivity check failed', error: e);
      return false;
    }
  }
}
