import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

/// Centralized, production-grade helper for executing Supabase queries with
/// standardized logging, error translation, retry boundaries, and pagination calculations.
class SupabaseQueryHelper {
  /// Executes a database or RPC query safely.
  /// If an error occurs, it is logged with [AppLogger.error].
  /// If [fallback] is provided and an exception occurs, [fallback] is returned cleanly.
  /// Otherwise, friendly user messages are rethrown for UI layers.
  static Future<T> runQuery<T>(
    String operationName,
    Future<T> Function() queryFn, {
    T? fallback,
    bool rethrowFriendly = true,
  }) async {
    try {
      return await queryFn();
    } on PostgrestException catch (e, st) {
      AppLogger.error('[$operationName] Postgrest error (${e.code}): ${e.message}', e, st);
      if (fallback != null) return fallback;
      if (rethrowFriendly) {
        throw _translatePostgrestError(e);
      }
      rethrow;
    } catch (e, st) {
      AppLogger.error('[$operationName] Unexpected query failure', e, st);
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  /// Retries a query up to [maxAttempts] times with exponential backoff on transient network failures.
  static Future<T> retryQuery<T>(
    String operationName,
    Future<T> Function() queryFn, {
    int maxAttempts = 2,
    Duration delay = const Duration(milliseconds: 300),
    T? fallback,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await queryFn();
      } catch (e, st) {
        if (attempt >= maxAttempts) {
          AppLogger.error('[$operationName] Failed after $maxAttempts attempts', e, st);
          if (fallback != null) return fallback;
          if (e is PostgrestException) {
            throw _translatePostgrestError(e);
          }
          rethrow;
        }
        await Future.delayed(delay * attempt);
      }
    }
  }

  /// Calculates exact SQL range start offset.
  static int calcOffset(int page, int pageSize) {
    return page * pageSize;
  }

  /// Calculates exact SQL range end boundary for Postgrest `.range(start, end)`.
  static int calcEndRange(int offset, int limit) {
    return offset + limit - 1;
  }

  /// Translates technical Supabase codes into clean user-facing error messages.
  static String _translatePostgrestError(PostgrestException e) {
    if (e.code == '42501' || e.message.toLowerCase().contains('permission denied')) {
      return 'Access denied. You do not have permission to perform this action or view this data.';
    }
    if (e.code == '23505' || e.message.toLowerCase().contains('duplicate key')) {
      return 'This record or reaction already exists.';
    }
    if (e.code == '23503' || e.message.toLowerCase().contains('foreign key')) {
      return 'Related record not found. Please refresh and try again.';
    }
    return e.message.isNotEmpty ? e.message : 'Database query failed.';
  }
}
