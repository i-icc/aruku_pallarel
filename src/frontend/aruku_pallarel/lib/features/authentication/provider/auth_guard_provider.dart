import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_guard_provider.g.dart';

@Riverpod(keepAlive: true)
Future<bool> authGuard(Ref ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return false;
  }
  try {
    final token = await user.getIdToken().timeout(
          const Duration(seconds: 8),
        );
    if (token == null || token.isEmpty) {
      await FirebaseAuth.instance.signOut();
      return false;
    }
    return true;
  } catch (_) {
    await FirebaseAuth.instance.signOut();
    return false;
  }
}
