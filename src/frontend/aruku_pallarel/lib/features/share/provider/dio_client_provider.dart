import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../env/env.dart';

part 'dio_client_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dioClient(DioClientRef ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.backendBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(ref.read(authTokenInterceptorProvider));
  return dio;
}

@Riverpod(keepAlive: true)
Interceptor authTokenInterceptor(AuthTokenInterceptorRef ref) {
  return QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final token = await user.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {
          // Allow request to continue without token if retrieval fails.
        }
      }
      handler.next(options);
    },
  );
}
