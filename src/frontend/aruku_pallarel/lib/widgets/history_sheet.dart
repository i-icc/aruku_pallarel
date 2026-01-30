import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/history/provider/walk_history_provider.dart';
import '../router/app_router.dart';
import '../theme/app_styles.dart';
import '../widgets/app_card.dart';

class HistorySheet extends ConsumerWidget {
  const HistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(walkHistoryListNotifierProvider);
    final theme = Theme.of(context);

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
                        '履歴',
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
                              Center(child: Text('No history yet.')),
                            ],
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                            children: [
                              AppCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    for (var i = 0; i < items.length; i++) ...[
                                      _HistoryRow(
                                        walkId: items[i].walkId,
                                        status: items[i].status,
                                        startedAt:
                                            _formatDate(items[i].startedAt),
                                        finishedAt:
                                            _formatDate(items[i].finishedAt),
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
                                        const Divider(height: 1),
                                    ],
                                  ],
                                ),
                              ),
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
                        Text('Failed to load history: $error'),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref
                              .read(walkHistoryListNotifierProvider.notifier)
                              .refresh(),
                          child: const Text('Retry'),
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

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.walkId,
    required this.status,
    required this.startedAt,
    required this.finishedAt,
    required this.onTap,
  });

  final String walkId;
  final String status;
  final String startedAt;
  final String finishedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.route, size: 20, color: AppColors.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Walk ID: $walkId', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Status: $status', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('Started: $startedAt', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('Finished: $finishedAt', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
