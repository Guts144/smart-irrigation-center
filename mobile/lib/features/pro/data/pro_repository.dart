import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'sensor_models.dart';

final proRepositoryProvider = Provider<ProRepository>((ref) {
  return ProRepository(ref.watch(dioProvider));
});

class ProRepository {
  final Dio _dio;

  ProRepository(this._dio);

  Future<SensorPage> getSensors({int page = 0, int size = 50}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/pro/sensors',
        queryParameters: {'page': page, 'size': size},
      );
      return SensorPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConnectionStatus> getConnectionStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/pro/connection');
      return ConnectionStatus.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> sendValveCommand(String action) async {
    try {
      await _dio.post(
        '/api/pro/valve',
        data: {'action': action},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
