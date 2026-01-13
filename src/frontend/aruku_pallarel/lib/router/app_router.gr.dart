// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  _$AppRouter({super.navigatorKey});

  @override
  Map<String, PageFactory> get pagesMap => {
    LoginRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LoginScreen(),
      );
    },
    BaseRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const BaseScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomeScreen(),
      );
    },
    WalkRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const WalkScreen(),
      );
    },
    HistoryRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HistoryScreen(),
      );
    },
    SettingsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SettingsScreen(),
      );
    },
    ChatRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ChatScreen(),
      );
    },
  };
}

class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const PageInfo page = PageInfo(
    name,
    builder: (data) => const LoginScreen(),
  );
}

class BaseRoute extends PageRouteInfo<void> {
  const BaseRoute({List<PageRouteInfo>? children})
      : super(
          BaseRoute.name,
          initialChildren: children,
        );

  static const String name = 'BaseRoute';

  static const PageInfo page = PageInfo(
    name,
    builder: (data) => const BaseScreen(),
  );
}

class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const PageInfo page = PageInfo(
    name,
    builder: (data) => const HomeScreen(),
  );
}

class WalkRoute extends PageRouteInfo<void> {
  const WalkRoute({List<PageRouteInfo>? children})
      : super(
          WalkRoute.name,
          initialChildren: children,
        );

  static const String name = 'WalkRoute';

  static const PageInfo page = PageInfo(
    name,
    builder: (data) => const WalkScreen(),
  );
}

class HistoryRoute extends PageRouteInfo<void> {
  const HistoryRoute({List<PageRouteInfo>? children})
      : super(
          HistoryRoute.name,
          initialChildren: children,
        );

  static const String name = 'HistoryRoute';

  static const PageInfo page = PageInfo(
    name,
    builder: (data) => const HistoryScreen(),
  );
}

class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const PageInfo page = PageInfo(
    name,
    builder: (data) => const SettingsScreen(),
  );
}

class ChatRoute extends PageRouteInfo<void> {
  const ChatRoute({List<PageRouteInfo>? children})
      : super(
          ChatRoute.name,
          initialChildren: children,
        );

  static const String name = 'ChatRoute';

  static const PageInfo page = PageInfo(
    name,
    builder: (data) => const ChatScreen(),
  );
}
