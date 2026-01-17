import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/history/provider/walk_history_provider.dart';
import '../../router/app_router.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: historyAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text('No history yet.'),
              );
            }
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(walkHistoryListNotifierProvider.notifier).refresh(),
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text('Walk ID: ${item.walkId}'),
                    subtitle: Text(
                      'Status: ${item.status}\n'
                      'Started: ${_formatDate(item.startedAt)}\n'
                      'Finished: ${_formatDate(item.finishedAt)}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.router.push(
                        HistoryDetailRoute(walkId: item.walkId),
                      );
                    },
                  );
                },
              ),
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
