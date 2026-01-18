import 'package:flutter/material.dart';

import '../theme/app_styles.dart';
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
                  'Map tiles are provided by the sources below.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < mapThemeOptions.length; i++) ...[
                  _AttributionItem(
                    themeId: mapThemeOptions[i],
                    isActive: mapThemeOptions[i] == activeTheme,
                  ),
                  if (i != mapThemeOptions.length - 1)
                    const Divider(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttributionItem extends StatelessWidget {
  const _AttributionItem({
    required this.themeId,
    required this.isActive,
  });

  final MapThemeId themeId;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                themeId.label,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Current',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.ink,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          themeId.theme.attribution,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
