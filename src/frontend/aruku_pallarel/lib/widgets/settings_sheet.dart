import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/walk/provider/location_spoof_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_styles.dart';
import '../../theme/map_theme_provider.dart';
import '../../theme/map_tiles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

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
    final selectedTheme = ref.watch(mapThemeNotifierProvider);
    final themeNotifier = ref.read(mapThemeNotifierProvider.notifier);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      // Allow the sheet to be dragged up to 90% of screen height,
      // starts at 50%, minimum 30%.
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
              // Header with Drag Handle and Close Button
              SizedBox(
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Drag Handle
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
                    // Close Button
                    Positioned(
                      left: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    // Title
                    Positioned(
                      top: 28,
                      child: Text(
                        '設定',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36), // Adjusted top padding
                  children: [
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _SectionHeader(
                            icon: Icons.map_outlined,
                            title: 'Map Theme',
                          ),
                          const Divider(height: 1),
                          RadioGroup<MapThemeId>(
                            groupValue: selectedTheme,
                            onChanged: (value) {
                              if (value != null) {
                                themeNotifier.setTheme(value);
                              }
                            },
                            child: Column(
                              children: [
                                for (var i = 0; i < mapThemeOptions.length; i++) ...[
                                  _ThemeOption(value: mapThemeOptions[i]),
                                  if (i != mapThemeOptions.length - 1)
                                    const Divider(height: 1),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  spoofState.enabled
                                      ? 'Mock the map location for testing.'
                                      : 'Use live GPS from your device.',
                                  style: theme.textTheme.bodySmall,
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
                              style: theme.textTheme.bodySmall,
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
                    const SizedBox(height: 16),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          const _SectionHeader(
                            icon: Icons.info_outline,
                            title: 'ライセンス',
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('オープンソースライセンス'),
                            subtitle: const Text('使用しているライブラリのライセンスを表示します。'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showLicensePage(
                                context: context,
                                applicationName: 'あるくパラレル',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Sign Out',
                      icon: Icons.logout,
                      backgroundColor: AppColors.danger,
                      onPressed: () => _signOut(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.inkMuted),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.value,
  });

  final MapThemeId value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<MapThemeId>(
      value: value,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(value.label),
      subtitle: Text(value.subtitle),
    );
  }
}
