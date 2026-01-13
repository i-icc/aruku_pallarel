import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../share/services/backend_exception.dart';
import '../infrastructure/walk_api.dart';
import '../models/walk_session.dart';

part 'active_walk_provider.g.dart';

@Riverpod(keepAlive: true)
class ActiveWalkNotifier extends _$ActiveWalkNotifier {
  @override
  WalkSession? build() => null;

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
