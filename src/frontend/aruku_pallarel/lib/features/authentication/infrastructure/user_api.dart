import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../share/provider/dio_client_provider.dart';
import '../../share/services/backend_exception.dart';
import '../models/user_profile.dart';

part 'user_api.g.dart';

class UserApi {
  UserApi(this._dio);

  final Dio _dio;

  Future<UserProfile> fetchMe() async {
    try {
      final response = await _dio.get('/v1/users/me');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UserProfile.fromJson(data);
      }
      throw BackendException('INVALID_RESPONSE', 'Invalid response format.');
    } on DioException catch (error) {
      throw backendExceptionFromDio(error);
    }
  }

  Future<UserProfile> createUser(String nickname) async {
    try {
      final response = await _dio.post(
        '/v1/users',
        data: {'nickname': nickname},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UserProfile.fromJson(data);
      }
      throw BackendException('INVALID_RESPONSE', 'Invalid response format.');
    } on DioException catch (error) {
      throw backendExceptionFromDio(error);
    }
  }
}

@Riverpod(keepAlive: true)
UserApi userApi(Ref ref) {
  return UserApi(ref.read(dioClientProvider));
}
