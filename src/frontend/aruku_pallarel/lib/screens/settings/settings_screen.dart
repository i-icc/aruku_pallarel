import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/walk/provider/location_spoof_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_styles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';

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
      body: AppBackground(
        safeAreaTop: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: AppColors.inkMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Spoofing',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spoofState.enabled
                              ? 'Mock the map location for testing.'
                              : 'Use live GPS from your device.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: spoofState.enabled,
                    activeThumbColor: AppColors.accentCool,
                    onChanged: (value) {
                      ref
                          .read(locationSpoofNotifierProvider.notifier)
                          .setEnabled(value);
                    },
                  ),
                ],
              ),
            ),
            if (spoofState.enabled) ...[
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spoofState.location == null
                          ? 'Hold 2s on the map to set a mock location.'
                          : 'Mocked: '
                              '${spoofState.location!.latitude.toStringAsFixed(5)}, '
                              '${spoofState.location!.longitude.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (spoofState.location != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          ref
                              .read(locationSpoofNotifierProvider.notifier)
                              .clear();
                        },
                        child: const Text('Clear Mock Location'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Sign Out',
              icon: Icons.logout,
              backgroundColor: AppColors.danger,
              onPressed: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}
