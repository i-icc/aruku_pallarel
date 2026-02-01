import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/authentication/provider/auth_guard_provider.dart';
import 'app_router.dart';

class AuthGuard extends AutoRouteGuard {
  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final context = router.navigatorKey.currentContext;
    if (context == null) {
      final isAuthenticated = await _checkAuthFallback();
      if (!isAuthenticated) {
        await router.replaceAll([const LoginRoute()]);
        return;
      }
      resolver.next();
      return;
    }

    final container = ProviderScope.containerOf(context);
    final isAuthenticated = await container.read(authGuardProvider.future);

    if (!isAuthenticated) {
      await router.replaceAll([const LoginRoute()]);
      return;
    }

    resolver.next();
  }

  Future<bool> _checkAuthFallback() async {
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
}
