import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../features/history/provider/walk_history_provider.dart';
import '../router/app_router.dart';
import '../theme/app_styles.dart';
import '../theme/map_theme_provider.dart';
import '../theme/map_tiles.dart';

class HistorySheet extends ConsumerWidget {
  const HistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(walkHistoryListNotifierProvider);
    final theme = Theme.of(context);
    final mapThemeId = ref.watch(mapThemeNotifierProvider);
    final mapTheme = mapThemeId.theme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 12,
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Positioned(
                      top: 28,
                      child: Text(
                        '今までの散歩',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: historyAsync.when(
                  data: (items) {
                    final listView = items.isEmpty
                        ? ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('まだ散歩の記録がありません')),
                            ],
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                _HistoryRow(
                                  startedAt: items[i].startedAt,
                                  finishedAt: items[i].finishedAt,
                                  startLocation: items[i].startLocation,
                                  mapTheme: mapTheme,
                                  onTap: () {
                                    final router = context.router;
                                    Navigator.of(context).pop();
                                    router.push(
                                      HistoryDetailRoute(
                                        walkId: items[i].walkId,
                                      ),
                                    );
                                  },
                                ),
                                if (i != items.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          );

                    return RefreshIndicator(
                      onRefresh: () => ref
                          .read(walkHistoryListNotifierProvider.notifier)
                          .refresh(),
                      color: AppColors.accent,
                      child: listView,
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('履歴の取得に失敗しました: $error'),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref
                              .read(walkHistoryListNotifierProvider.notifier)
                              .refresh(),
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.startedAt,
    required this.finishedAt,
    required this.startLocation,
    required this.mapTheme,
    required this.onTap,
  });

  final DateTime? startedAt;
  final DateTime? finishedAt;
  final LatLng? startLocation;
  final MapTileTheme mapTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = _formatDateLabel(startedAt);
    final timeRange = _formatTimeRange(startedAt, finishedAt);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.small),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.small),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MapPreview(
                location: startLocation,
                mapTheme: mapTheme,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeRange,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateLabel(DateTime? value) {
    if (value == null) {
      return '散歩の記録';
    }
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '--:--';
    }
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeRange(DateTime? start, DateTime? end) {
    final startText = _formatTime(start);
    final endText = end == null ? '---' : _formatTime(end);
    return '$startText  -  $endText';
  }

}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.location,
    required this.mapTheme,
  });

  final LatLng? location;
  final MapTileTheme mapTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: location == null
            ? const Center(
                child: Icon(
                  Icons.map_outlined,
                  color: AppColors.inkMuted,
                ),
              )
            : FlutterMap(
                options: MapOptions(
                  initialCenter: location!,
                  initialZoom: 15,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapTheme.urlTemplate,
                    subdomains: mapTheme.subdomains,
                    userAgentPackageName: 'com.example.arukuPallarel',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location!,
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
