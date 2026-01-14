import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/share/services/backend_exception.dart';
import '../../features/walk/provider/active_walk_provider.dart';

@RoutePage()
class WalkScreen extends ConsumerStatefulWidget {
  const WalkScreen({super.key});

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> {
  bool _finishLoading = false;

  Future<void> _finishWalk() async {
    setState(() {
      _finishLoading = true;
    });

    try {
      await ref.read(activeWalkNotifierProvider.notifier).finishWalk();
      if (!mounted) {
        return;
      }
      context.router.pop();
    } on BackendException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _finishLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeWalk = ref.watch(activeWalkNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Walk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (activeWalk == null) ...[
              const Text('No active walk.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.router.pop(),
                child: const Text('Back to Home'),
              ),
            ] else ...[
              Text('Walk ID: ${activeWalk.walkId}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _finishLoading ? null : _finishWalk,
                child: _finishLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Finish Walk'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
