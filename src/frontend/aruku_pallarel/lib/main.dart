import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'features/share/provider/app_initialization_provider.dart';
import 'features/share/services/fcm_messaging.dart';
import 'features/share/provider/overlay_loading_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final initialization = ref.watch(appInitializationFutureProvider);
    final appRouter = useMemoized(AppRouter.new);

    return initialization.when(
      loading: () => _buildLoading(theme),
      error: (error, _) => _buildApp(appRouter, theme, ref),
      data: (_) => _buildApp(appRouter, theme, ref),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return MaterialApp(
      title: 'Aruku Parallel',
      themeMode: ThemeMode.light,
      theme: theme,
      home: const _InitializationLoadingScreen(),
    );
  }

  Widget _buildApp(AppRouter appRouter, ThemeData theme, WidgetRef ref) {
    final isLoading = ref.watch(overlayLoadingProvider);
    return MaterialApp.router(
      title: 'Aruku Parallel',
      themeMode: ThemeMode.light,
      theme: theme,
      routerConfig: appRouter.config(),
      builder: (context, router) {
        if (!isLoading) {
          return router!;
        }
        return Stack(
          children: [
            router!,
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      },
    );
  }
}

class _InitializationLoadingScreen extends StatelessWidget {
  const _InitializationLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '準備中...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
