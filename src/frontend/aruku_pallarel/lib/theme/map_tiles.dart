import '../env/env.dart';

class MapTileTheme {
  const MapTileTheme({
    required this.name,
    required this.urlTemplate,
    required this.attribution,
    this.subdomains = const [],
  });

  final String name;
  final String urlTemplate;
  final String attribution;
  final List<String> subdomains;

  static const osmStandard = MapTileTheme(
    name: 'OpenStreetMap Standard',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
  );

  static const jawgLagoon = MapTileTheme(
    name: 'Jawg Lagoon',
    urlTemplate:
        'https://tile.jawg.io/jawg-lagoon/{z}/{x}/{y}.png?access-token=${Env.jawgAccessToken}',
    attribution: '© Jawg Maps © OpenStreetMap contributors',
  );

  static const cartoPositron = MapTileTheme(
    name: 'Carto Positron',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors © CARTO',
    subdomains: ['a', 'b', 'c', 'd'],
  );

  static const cartoPositronNoLabels = MapTileTheme(
    name: 'Carto Positron (No Labels)',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors © CARTO',
    subdomains: ['a', 'b', 'c', 'd'],
  );

  static const cartoDarkMatter = MapTileTheme(
    name: 'Carto Dark Matter',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors © CARTO',
    subdomains: ['a', 'b', 'c', 'd'],
  );

  static const cartoVoyager = MapTileTheme(
    name: 'Carto Voyager',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors © CARTO',
    subdomains: ['a', 'b', 'c', 'd'],
  );
}

enum MapThemeId {
  cartoPositronNoLabels,
  cartoDarkMatter,
  cartoPositron,
  cartoVoyager,
  osmStandard,
}

const List<MapThemeId> mapThemeOptions = [
  MapThemeId.cartoPositronNoLabels,
  MapThemeId.cartoDarkMatter,
  MapThemeId.cartoPositron,
  MapThemeId.cartoVoyager,
  MapThemeId.osmStandard,
];

extension MapThemeIdX on MapThemeId {
  String get label {
    switch (this) {
      case MapThemeId.cartoPositronNoLabels:
        return 'Carto Positron (No Labels)';
      case MapThemeId.cartoDarkMatter:
        return 'Carto Dark Matter';
      case MapThemeId.cartoPositron:
        return 'Carto Positron';
      case MapThemeId.cartoVoyager:
        return 'Carto Voyager';
      case MapThemeId.osmStandard:
        return 'OpenStreetMap Standard';
    }
  }

  String get subtitle {
    switch (this) {
      case MapThemeId.cartoPositronNoLabels:
        return 'No labels';
      case MapThemeId.cartoDarkMatter:
        return 'Dark mode';
      case MapThemeId.cartoPositron:
        return 'Light labels';
      case MapThemeId.cartoVoyager:
        return 'Vivid';
      case MapThemeId.osmStandard:
        return 'Classic';
    }
  }

  MapTileTheme get theme {
    switch (this) {
      case MapThemeId.cartoPositronNoLabels:
        return MapTileTheme.cartoPositronNoLabels;
      case MapThemeId.cartoDarkMatter:
        return MapTileTheme.cartoDarkMatter;
      case MapThemeId.cartoPositron:
        return MapTileTheme.cartoPositron;
      case MapThemeId.cartoVoyager:
        return MapTileTheme.cartoVoyager;
      case MapThemeId.osmStandard:
        return MapTileTheme.osmStandard;
    }
  }
}
