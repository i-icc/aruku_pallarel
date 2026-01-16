import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/authentication/provider/user_profile_provider.dart';
import '../../features/share/services/backend_exception.dart';
import '../../features/walk/provider/active_walk_provider.dart';
import '../../router/app_router.dart';

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
    final docId = user?.uid ?? 'anonymous';
    try {
      await FirebaseFirestore.instance
          .collection('debug')
          .doc(docId)
          .set(
            {
              'updatedAt': FieldValue.serverTimestamp(),
              'client': Platform.operatingSystem,
            },
            SetOptions(merge: true),
          );
      return 'ok';
    } catch (error) {
      return 'error ($error)';
    }
  }

  Future<void> _startWalk() async {
    setState(() {
      _walkLoading = true;
    });

    try {
      const fallbackLat = 35.681236;
      const fallbackLon = 139.767125;
      await ref.read(activeWalkNotifierProvider.notifier).startWalk(
            lat: fallbackLat,
            lon: fallbackLon,
          );
      if (!mounted) {
        return;
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Home (empty)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            profile.when(
              data: (value) {
                if (value == null) {
                  return const Text('Nickname: -');
                }
                return Text('Nickname: ${value.nickname}');
              },
              loading: () => const Text('Nickname: loading...'),
              error: (error, _) => Text('Nickname: error (${error.toString()})'),
            ),
            const SizedBox(height: 12),
            if (activeWalk != null) ...[
              Text('Active Walk: ${activeWalk.walkId}'),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _walkLoading
                  ? null
                  : () async {
                      if (activeWalk != null) {
                        await context.router.push(const WalkRoute());
                        return;
                      }
                      await _startWalk();
                    },
              child: _walkLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(activeWalk == null ? 'Start Walk' : 'Continue Walk'),
            ),
            const SizedBox(height: 12),
            Text('Firestore: $_firestoreStatus'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _refreshStatus,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
