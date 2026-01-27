import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../share/provider/dio_client_provider.dart';
import '../../share/services/backend_exception.dart';
import '../models/location_append_point.dart';
import '../models/location_append_result.dart';
import '../models/suggestion_request_result.dart';
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

  Future<SuggestionRequestResult> requestSuggestion(String walkId) async {
    try {
      final response =
          await _dio.post('/v1/walks/$walkId/suggestions:request');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return SuggestionRequestResult.fromJson(data);
      }
      throw BackendException('INVALID_RESPONSE', 'Invalid response format.');
    } on DioException catch (error) {
      throw backendExceptionFromDio(error);
    }
  }

  Future<LocationAppendResult> appendLocations({
    required String walkId,
    required List<LocationAppendPoint> points,
    String source = 'foreground',
  }) async {
    try {
      final response = await _dio.post(
        '/v1/walks/$walkId/locations:append',
        data: {
          'points': points.map((point) => point.toJson()).toList(),
          'source': source,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return LocationAppendResult.fromJson(data);
      }
      throw BackendException('INVALID_RESPONSE', 'Invalid response format.');
    } on DioException catch (error) {
      throw backendExceptionFromDio(error);
    }
  }
}

@Riverpod(keepAlive: true)
WalkApi walkApi(Ref ref) {
  return WalkApi(ref.read(dioClientProvider));
}
