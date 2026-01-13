import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenBody();
  }
}

class _HomeScreenBody extends StatefulWidget {
  const _HomeScreenBody();

  @override
  State<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<_HomeScreenBody> {
  String _firestoreStatus = 'pending';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
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
