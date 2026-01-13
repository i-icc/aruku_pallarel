import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

extension TabsRouterX on BuildContext {
  TabsRouter get tabsRouter => AutoTabsRouter.of(this);
}
