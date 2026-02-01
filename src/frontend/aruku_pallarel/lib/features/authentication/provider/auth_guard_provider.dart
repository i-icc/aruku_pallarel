import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../share/services/backend_exception.dart';
import 'user_profile_provider.dart';

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
    try {
      final profile = await ref.read(userProfileNotifierProvider.future);
      if (profile == null) {
        await FirebaseAuth.instance.signOut();
        return false;
      }
    } on BackendException catch (error) {
      if (error.code == 'UNAUTHORIZED' ||
          error.code == 'HTTP_401' ||
          error.code == 'HTTP_403') {
        await FirebaseAuth.instance.signOut();
        return false;
      }
    } catch (_) {
      // Keep navigation when profile fetch fails for non-auth reasons.
    }
    return true;
  } catch (_) {
    await FirebaseAuth.instance.signOut();
    return false;
  }
}
