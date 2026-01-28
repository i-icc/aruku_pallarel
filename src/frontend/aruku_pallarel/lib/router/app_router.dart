import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import '../screens/authentication/login_screen.dart';

import '../screens/chat/chat_screen.dart';
import '../screens/history/history_detail_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';

import '../screens/walk/walk_screen.dart';
import 'auth_guard.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: HomeRoute.page,
          initial: true,
          path: '/',
          guards: [AuthGuard()],
        ),

        AutoRoute(page: LoginRoute.page, path: '/login'),
        AutoRoute(page: WalkRoute.page, path: '/walk', guards: [AuthGuard()]),
        AutoRoute(
          page: HistoryRoute.page,
          path: '/history',
          guards: [AuthGuard()],
        ),
        AutoRoute(
          page: HistoryDetailRoute.page,
          path: '/history/:walkId',
          guards: [AuthGuard()],
        ),
        AutoRoute(page: ChatRoute.page, path: '/chat', guards: [AuthGuard()]),
      ];
}
