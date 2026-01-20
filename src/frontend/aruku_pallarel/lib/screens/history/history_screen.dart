import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/history/provider/walk_history_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_styles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';

@RoutePage()
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(walkHistoryListNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: AppBackground(
        safeAreaTop: false,
        child: historyAsync.when(
          data: (items) {
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(walkHistoryListNotifierProvider.notifier).refresh(),
              color: AppColors.accent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'Walking history',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('No history yet.'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                _HistoryRow(
                                  walkId: items[i].walkId,
                                  status: items[i].status,
                                  startedAt: _formatDate(items[i].startedAt),
                                  finishedAt: _formatDate(items[i].finishedAt),
                                  onTap: () {
                                    context.router.push(
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
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
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
