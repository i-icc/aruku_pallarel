import 'package:auto_route/auto_route.dart';
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
}
