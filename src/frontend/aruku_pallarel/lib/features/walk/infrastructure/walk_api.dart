import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../share/provider/dio_client_provider.dart';
import '../../share/services/backend_exception.dart';
import '../models/walk_session.dart';

part 'walk_api.g.dart';

class WalkApi {
  WalkApi(this._dio);

  final Dio _dio;

  Future<WalkSession> startWalk({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _dio.post(
        '/v1/walks',
        data: {
          'startLocation': {'lat': lat, 'lon': lon},
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return WalkSession.fromJson(data);
      }
      throw BackendException('INVALID_RESPONSE', 'Invalid response format.');
    } on DioException catch (error) {
      throw backendExceptionFromDio(error);
    }
  }

  Future<WalkSession> finishWalk(String walkId) async {
    try {
      final response = await _dio.post('/v1/walks/$walkId:finish');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return WalkSession.fromJson(data);
      }
      throw BackendException('INVALID_RESPONSE', 'Invalid response format.');
    } on DioException catch (error) {
      throw backendExceptionFromDio(error);
    }
  }
}

@Riverpod(keepAlive: true)
WalkApi walkApi(WalkApiRef ref) {
  return WalkApi(ref.read(dioClientProvider));
}
