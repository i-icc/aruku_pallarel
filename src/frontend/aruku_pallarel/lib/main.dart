import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'features/share/providers/app_initialization_provider.dart';
import 'router/app_router.dart';
import 'router/auth_guard.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AppRoot()));
}

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(authGuard: AuthGuard());
  }

  @override
  Widget build(BuildContext context) {
    final initialization = ref.watch(appInitializationProvider);

    return initialization.when(
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Initialization failed: $error'),
          ),
        ),
      ),
      data: (_) => MaterialApp.router(
        title: 'Aruku Parallel',
        theme: AppTheme.light,
        routerConfig: _appRouter.config(),
      ),
    );
  }
}
