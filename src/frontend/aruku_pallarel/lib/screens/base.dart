import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/share/providers/firebase_providers.dart';
import '../router/app_router.dart';

@RoutePage()
class BaseScreen extends ConsumerWidget {
  const BaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateChangesProvider, (previous, next) {
      if (next.isLoading) {
        return;
      }
      final user = next.valueOrNull;
      if (user == null && context.router.current.name != LoginRoute.name) {
        context.router.replace(const LoginRoute());
      }
    });

    return AutoTabsRouter(
      routes: const [
        HomeRoute(),
        WalkRoute(),
        HistoryRoute(),
        SettingsRoute(),
        ChatRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_walk_outlined),
                label: 'Walk',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Chat',
              ),
            ],
          ),
        );
      },
    );
  }
}
