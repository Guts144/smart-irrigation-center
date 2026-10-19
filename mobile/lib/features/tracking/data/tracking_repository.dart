import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'tracking_models.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository(ref.watch(dioProvider));
});

class TrackingRepository {
  final Dio _dio;

  TrackingRepository(this._dio);

  Future<TrackingInfoResponse?> getActiveSession() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/tracking/active');
      if (response.statusCode == 204 || response.data == null) {
        return null;
      }
      return TrackingInfoResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return null;
      throw ApiException.fromDio(e);
    }
  }

  Future<TrackingInfoResponse> getTrackingInfo(int sessionId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/tracking/$sessionId');
      return TrackingInfoResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StartTrackingResponse> startTracking(StartTrackingRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/tracking/start',
        data: request.toJson(),
      );
      return StartTrackingResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> sendLocationUpdate(LocationUpdateRequest request) async {
    try {
      await _dio.post(
        '/api/tracking/location',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markArrived(int sessionId, {String? token}) async {
    try {
      await _dio.post(
        '/api/tracking/$sessionId/arrived',
        queryParameters: token != null ? {'token': token} : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
