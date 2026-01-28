// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [ChatScreen]
class ChatRoute extends PageRouteInfo<void> {
  const ChatRoute({List<PageRouteInfo>? children})
    : super(ChatRoute.name, initialChildren: children);

  static const String name = 'ChatRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChatScreen();
    },
  );
}

/// generated route for
/// [HistoryDetailScreen]
class HistoryDetailRoute extends PageRouteInfo<HistoryDetailRouteArgs> {
  HistoryDetailRoute({
    Key? key,
    required String walkId,
    List<PageRouteInfo>? children,
  }) : super(
         HistoryDetailRoute.name,
         args: HistoryDetailRouteArgs(key: key, walkId: walkId),
         initialChildren: children,
       );

  static const String name = 'HistoryDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HistoryDetailRouteArgs>();
      return HistoryDetailScreen(key: args.key, walkId: args.walkId);
    },
  );
}

class HistoryDetailRouteArgs {
  const HistoryDetailRouteArgs({this.key, required this.walkId});

  final Key? key;

  final String walkId;

  @override
  String toString() {
    return 'HistoryDetailRouteArgs{key: $key, walkId: $walkId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HistoryDetailRouteArgs) return false;
    return key == other.key && walkId == other.walkId;
  }

  @override
  int get hashCode => key.hashCode ^ walkId.hashCode;
}

/// generated route for
/// [HistoryScreen]
class HistoryRoute extends PageRouteInfo<void> {
  const HistoryRoute({List<PageRouteInfo>? children})
    : super(HistoryRoute.name, initialChildren: children);

  static const String name = 'HistoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HistoryScreen();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginScreen();
    },
  );
}

/// generated route for
/// [SettingsScreen]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsScreen();
    },
  );
}

/// generated route for
/// [WalkScreen]
class WalkRoute extends PageRouteInfo<void> {
  const WalkRoute({List<PageRouteInfo>? children})
    : super(WalkRoute.name, initialChildren: children);

  static const String name = 'WalkRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const WalkScreen();
    },
  );
}
