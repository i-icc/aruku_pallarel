import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../share/services/backend_exception.dart';
import '../infrastructure/walk_api.dart';
import '../models/walk_session.dart';

part 'active_walk_provider.g.dart';

@Riverpod(keepAlive: true)
class ActiveWalkNotifier extends _$ActiveWalkNotifier {
  @override
  WalkSession? build() => null;

  Future<WalkSession?> loadActiveWalk() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = null;
      return null;
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('walks')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        state = null;
        return null;
      }
      rethrow;
    }
    if (snapshot.docs.isEmpty) {
      state = null;
      return null;
    }
    final doc = snapshot.docs.first;
    final data = doc.data();
    final startedAt = data['startedAt'];
    String? startedAtIso;
    if (startedAt is Timestamp) {
      startedAtIso = startedAt.toDate().toIso8601String();
    }
    final session = WalkSession(
      walkId: doc.id,
      status: data['status'] as String? ?? 'active',
      startedAt: startedAtIso,
      finishedAt: null,
    );
    state = session;
    return session;
  }

  Future<WalkSession> startWalk({
    required double lat,
    required double lon,
  }) async {
    final api = ref.read(walkApiProvider);
    try {
      final session = await api.startWalk(lat: lat, lon: lon);
      state = session;
      return session;
    } on BackendException {
      rethrow;
    }
  }

  Future<WalkSession?> finishWalk() async {
    final current = state;
    if (current == null) {
      return null;
    }
    final api = ref.read(walkApiProvider);
    try {
      final finished = await api.finishWalk(current.walkId);
      state = null;
      return finished;
    } on BackendException {
      rethrow;
    }
  }
}
