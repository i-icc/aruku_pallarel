import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:locus/locus.dart' as locus;

import '../../features/authentication/provider/user_profile_provider.dart';
import '../../features/share/services/backend_exception.dart';
import '../../features/walk/provider/active_walk_provider.dart';
import '../../features/walk/provider/location_spoof_provider.dart';
import '../../features/walk/provider/walk_tracking_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_styles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_reveal.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenBody();
  }
}

class _HomeScreenBody extends ConsumerStatefulWidget {
  const _HomeScreenBody();

  @override
  ConsumerState<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends ConsumerState<_HomeScreenBody> {
  String _firestoreStatus = 'pending';
  bool _loading = false;
  bool _walkLoading = false;

  Future<LatLng?> _fetchLastKnownLocation() async {
    try {
      final state = await locus.Locus.getState();
      final location = state.location;
      final coords = location?.coords;
      if (coords != null && coords.isValid) {
        return LatLng(coords.latitude, coords.longitude);
      }
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(activeWalkNotifierProvider.notifier).loadActiveWalk();
    });
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _loading = true;
    });

    final firestoreStatus = await _pingFirestore();

    if (!mounted) {
      return;
    }

    setState(() {
      _firestoreStatus = firestoreStatus;
      _loading = false;
    });
  }

  Future<String> _pingFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'signed-out';
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return 'ok';
    } catch (error) {
      return 'error ($error)';
    }
  }

  Future<void> _startWalk() async {
    setState(() {
      _walkLoading = true;
    });

    final trackingNotifier = ref.read(walkTrackingNotifierProvider.notifier);
    final wasTracking = ref.read(walkTrackingNotifierProvider).isTracking;
    var stopTrackingOnFailure = false;
    var navigated = false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          await context.router.replaceAll([const LoginRoute()]);
        }
        return;
      }
      try {
        final token = await user.getIdToken().timeout(
              const Duration(seconds: 8),
            );
        if (token == null || token.isEmpty) {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            await context.router.replaceAll([const LoginRoute()]);
          }
          return;
        }
      } catch (_) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          await context.router.replaceAll([const LoginRoute()]);
        }
        return;
      }

      final spoofState = ref.read(locationSpoofNotifierProvider);
      final spoofLocation = spoofState.enabled ? spoofState.location : null;
      LatLng? startLocation = spoofLocation;
      if (startLocation == null) {
        bool granted = false;
        try {
          granted = await trackingNotifier
              .startTracking()
              .timeout(const Duration(seconds: 10));
        } on TimeoutException {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location setup timed out. Try again.'),
              ),
            );
          }
          return;
        }
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required.'),
              ),
            );
          }
          return;
        }
        stopTrackingOnFailure = !wasTracking;
        try {
          final current = await locus.LocusLocation.getCurrentPosition(
            timeout: 15,
            maximumAge: 0,
          ).timeout(const Duration(seconds: 10));
          final coords = current.coords;
          if (coords.isValid) {
            startLocation = LatLng(coords.latitude, coords.longitude);
          }
        } on TimeoutException {
          startLocation = await _fetchLastKnownLocation();
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to get current location: $error')),
            );
          }
          startLocation = await _fetchLastKnownLocation();
        }
      }
      if (startLocation == null) {
        const fallbackLat = 35.681236;
        const fallbackLon = 139.767125;
        startLocation = const LatLng(fallbackLat, fallbackLon);
      }
      await ref.read(activeWalkNotifierProvider.notifier).startWalk(
            lat: startLocation.latitude,
            lon: startLocation.longitude,
          );
      if (!mounted) {
        return;
      }
      navigated = true;
      await context.router.push(const WalkRoute());
    } on BackendException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.code == 'WALK_ALREADY_ACTIVE') {
        final session =
            await ref.read(activeWalkNotifierProvider.notifier).loadActiveWalk();
        if (!mounted) {
          return;
        }
        if (session != null) {
          await context.router.push(const WalkRoute());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Active walk not found.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (!navigated && stopTrackingOnFailure) {
        await trackingNotifier.stopTracking();
      }
      if (mounted) {
        setState(() {
          _walkLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileNotifierProvider);
    final activeWalk = ref.watch(activeWalkNotifierProvider);
    final spoofState = ref.watch(locationSpoofNotifierProvider);
    final theme = Theme.of(context);
    final serifTitle = GoogleFonts.shipporiMincho(
      textStyle: theme.textTheme.displayMedium,
      fontWeight: FontWeight.w600,
      height: 1.1,
      color: AppColors.ink,
    );
    final serifTagline = GoogleFonts.shipporiMincho(
      textStyle: theme.textTheme.titleMedium,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: AppColors.ink,
    );

    final nickname = profile.when(
      data: (value) => value?.nickname ?? 'Guest',
      loading: () => 'Loading...',
      error: (error, stackTrace) => 'Unavailable',
    );

    final walkValue = activeWalk == null ? 'Idle' : 'Active';
    final walkSubtitle =
        activeWalk == null ? 'No active session' : 'ID: ${activeWalk.walkId}';

    final locationValue = spoofState.enabled ? 'Mocked' : 'Live';
    final locationSubtitle = spoofState.enabled
        ? (spoofState.location == null ? 'Set from map' : 'Pinned on map')
        : 'Tracking on device';
    final walkHeadline =
        activeWalk == null ? 'Ready for the next session?' : 'Active walk running';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => context.router.push(const HistoryRoute()),
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
        ],
      ),
      body: AppBackground(
        safeAreaTop: false,
        child: RefreshIndicator(
          onRefresh: _refreshStatus,
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: AppReveal(
                    delay: const Duration(milliseconds: 80),
                    child: _HeroPanel(
                      nickname: nickname,
                      headline: walkHeadline,
                      locationValue: locationValue,
                      walkValue: walkValue,
                      serifTitle: serifTitle,
                      serifTagline: serifTagline,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: AppPrimaryButton(
                    label: activeWalk == null ? 'Start Walk' : 'Continue Walk',
                    icon: activeWalk == null
                        ? Icons.play_arrow
                        : Icons.directions_walk,
                    isLoading: _walkLoading,
                    onPressed: _walkLoading
                        ? null
                        : () async {
                            if (activeWalk != null) {
                              await context.router.push(const WalkRoute());
                              return;
                            }
                            await _startWalk();
                          },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: const _SectionHeader(
                    title: 'STATUS',
                    caption: 'SYSTEM CHECK',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _StatusRow(
                          icon: Icons.person_outline,
                          title: 'Account',
                          value: nickname,
                          subtitle: 'Signed in',
                        ),
                        const _SlantedDivider(),
                        _StatusRow(
                          icon: Icons.directions_walk,
                          title: 'Walk',
                          value: walkValue,
                          subtitle: walkSubtitle,
                        ),
                        const _SlantedDivider(),
                        _StatusRow(
                          icon: Icons.cloud_outlined,
                          title: 'Firestore',
                          value: _firestoreStatus,
                          subtitle: _loading ? 'Checking...' : 'Pull to refresh',
                        ),
                        const _SlantedDivider(),
                        _StatusRow(
                          icon: Icons.my_location,
                          title: 'Location',
                          value: locationValue,
                          subtitle: locationSubtitle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: const _SectionHeader(
                    title: 'SHORTCUTS',
                    caption: 'QUICK ACCESS',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ShortcutRow(
                          icon: Icons.map_outlined,
                          title: 'History',
                          subtitle: 'Past routes',
                          onTap: () =>
                              context.router.push(const HistoryRoute()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.nickname,
    required this.headline,
    required this.locationValue,
    required this.walkValue,
    required this.serifTitle,
    required this.serifTagline,
  });

  final String nickname;
  final String headline;
  final String locationValue;
  final String walkValue;
  final TextStyle serifTitle;
  final TextStyle serifTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.small),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('WALK BRIEFING', style: theme.textTheme.labelLarge),
                  const SizedBox(width: 8),
                  const _MicroCaption(text: 'ACADEMIC FILE'),
                ],
              ),
              const SizedBox(height: 14),
              Text('Hello, $nickname', style: serifTitle),
              const SizedBox(height: 6),
              Text(headline, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text('The next page belongs to you.', style: serifTagline),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InfoChip(label: 'Walk', value: walkValue),
                  _InfoChip(label: 'Location', value: locationValue),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -12,
          left: 12,
          child: _SlantedAccent(
            width: 140,
            height: 28,
            color: AppColors.accent.withValues(alpha: 0.18),
          ),
        ),
        const Positioned(
          right: 12,
          bottom: -10,
          child: _MicroCaption(text: 'PREMIUM PROSPECTUS'),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(width: 8),
            _MicroCaption(text: caption),
          ],
        ),
        const SizedBox(height: 8),
        const _SlantedLine(),
      ],
    );
  }
}

class _MicroCaption extends StatelessWidget {
  const _MicroCaption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 6),
        Text('+', style: theme.textTheme.labelSmall),
        const SizedBox(width: 4),
        Text('+', style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _SlantedLine extends StatelessWidget {
  const _SlantedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Transform.rotate(
              angle: -math.pi / 12,
              child: Container(
                width: constraints.maxWidth * 0.6,
                height: 1,
                color: AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlantedDivider extends StatelessWidget {
  const _SlantedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Transform.rotate(
              angle: -math.pi / 12,
              child: Container(
                width: constraints.maxWidth,
                height: 1,
                color: AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlantedAccent extends StatelessWidget {
  const _SlantedAccent({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -math.pi / 12,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.inkMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.inkMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
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
