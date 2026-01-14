import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_guard_provider.g.dart';

@Riverpod(keepAlive: true)
Future<bool> authGuard(Ref ref) async {
  return FirebaseAuth.instance.currentUser != null;
}
