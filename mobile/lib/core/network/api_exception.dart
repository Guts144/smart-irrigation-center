import 'package:dio/dio.dart';

/// A user-presentable API failure.
///
/// The backend answers errors with Spring's ProblemDetail JSON:
/// `{ "title": ..., "status": 401, "detail": "Invalid email or password" }`.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isPaymentRequired => statusCode == 402;
  bool get isConflict => statusCode == 409;

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('The server took too long to respond. Please try again.');
      case DioExceptionType.connectionError:
        return const ApiException('Cannot reach the AquaSense server. Check your connection.');
      default:
        break;
    }

    final response = error.response;
    final status = response?.statusCode;
    final data = response?.data;
    if (data is Map && data['detail'] is String && (data['detail'] as String).isNotEmpty) {
      return ApiException(data['detail'] as String, statusCode: status);
    }
    return ApiException(_fallbackMessage(status), statusCode: status);
  }

  static String _fallbackMessage(int? status) => switch (status) {
        400 => 'The request was invalid.',
        401 => 'Your session has expired. Please sign in again.',
        402 => 'A Pro subscription is required.',
        403 => 'You are not allowed to do that.',
        404 => 'Not found.',
        409 => 'That already exists.',
        503 => 'The service is temporarily unavailable.',
        _ => 'Something went wrong. Please try again.',
      };

  @override
  String toString() => 'ApiException($statusCode): $message';
}
