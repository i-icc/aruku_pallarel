import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'map_tiles.dart';

part 'map_theme_provider.g.dart';

@Riverpod(keepAlive: true)
class MapThemeNotifier extends _$MapThemeNotifier {
  @override
  MapThemeId build() => MapThemeId.cartoPositronNoLabels;

  void setTheme(MapThemeId theme) {
    if (state == theme) {
      return;
    }
    state = theme;
  }
}
