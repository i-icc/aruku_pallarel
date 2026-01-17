import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/walk/provider/location_spoof_provider.dart';
import '../../router/app_router.dart';

@RoutePage()
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) {
      return;
    }
    context.router.replaceAll(const [LoginRoute()]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spoofState = ref.watch(locationSpoofNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Location Spoofing (dev)'),
              subtitle: Text(
                spoofState.enabled
                    ? 'Long-press 2s on the map to set a mock location.'
                    : 'Enable to set a mock location from the Walk map.',
              ),
              value: spoofState.enabled,
              onChanged: (value) {
                ref.read(locationSpoofNotifierProvider.notifier).setEnabled(
                      value,
                    );
              },
            ),
            if (spoofState.enabled && spoofState.location != null) ...[
              const SizedBox(height: 8),
              Text(
                'Mocked: '
                '${spoofState.location!.latitude.toStringAsFixed(5)}, '
                '${spoofState.location!.longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  ref
                      .read(locationSpoofNotifierProvider.notifier)
                      .clear();
                },
                child: const Text('Clear Mock Location'),
              ),
            ],
            const Divider(height: 32),
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
