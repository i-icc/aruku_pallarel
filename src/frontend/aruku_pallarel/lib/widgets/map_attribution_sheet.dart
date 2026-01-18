import 'package:flutter/material.dart';

import '../theme/map_tiles.dart';
import 'app_card.dart';

void showMapAttributionSheet(BuildContext context, MapThemeId activeTheme) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => MapAttributionSheet(activeTheme: activeTheme),
  );
}

class MapAttributionSheet extends StatelessWidget {
  const MapAttributionSheet({
    super.key,
    required this.activeTheme,
  });

  final MapThemeId activeTheme;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: AppCard(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Map Info',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Map tiles are provided by the source below.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  activeTheme.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  activeTheme.theme.attribution,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
