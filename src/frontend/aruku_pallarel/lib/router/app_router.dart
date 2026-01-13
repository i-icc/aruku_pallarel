import 'package:auto_route/auto_route.dart';

import '../screens/auth/login_screen.dart';
import '../screens/base.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/walk/walk_screen.dart';
import 'auth_guard.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends _$AppRouter {
  AppRouter({required this.authGuard});

  final AuthGuard authGuard;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: '/login', page: LoginRoute.page),
        AutoRoute(
          path: '/',
          page: BaseRoute.page,
          guards: [authGuard],
          children: [
            AutoRoute(path: 'home', page: HomeRoute.page, initial: true),
            AutoRoute(path: 'walk', page: WalkRoute.page),
            AutoRoute(path: 'history', page: HistoryRoute.page),
            AutoRoute(path: 'settings', page: SettingsRoute.page),
            AutoRoute(path: 'chat', page: ChatRoute.page),
          ],
        ),
      ];
}
