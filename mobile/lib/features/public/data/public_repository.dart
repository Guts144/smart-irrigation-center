import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'public_models.dart';

final publicRepositoryProvider = Provider<PublicRepository>((ref) {
  return PublicRepository(ref.watch(dioProvider));
});

class PublicRepository {
  final Dio _dio;

  PublicRepository(this._dio);

  Future<ProjectInfo> getInfo() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/public/info');
      return ProjectInfo.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Plan>> getPricing() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/public/pricing');
      final plansJson = response.data?['plans'] as List<dynamic>? ?? [];
      return plansJson.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> sendContactMessage({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      await _dio.post(
        '/api/contact',
        data: {
          'name': name,
          'email': email,
          'message': message,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
