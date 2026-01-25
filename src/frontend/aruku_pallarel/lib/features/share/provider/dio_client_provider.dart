import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../env/env.dart';

part 'dio_client_provider.g.dart';

@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
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
Interceptor authTokenInterceptor(Ref ref) {
  return QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final token = await user.getIdToken().timeout(
                const Duration(seconds: 8),
              );
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            await FirebaseAuth.instance.signOut();
          }
        } catch (_) {
          await FirebaseAuth.instance.signOut();
        }
      }
      handler.next(options);
    },
  );
}
