import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/walk_session.dart';
import '../models/walk_suggest.dart';
import 'active_walk_provider.dart';

part 'walk_suggestion_provider.g.dart';

class SelectedSuggestState {
  const SelectedSuggestState({
    this.walkId,
    this.suggestId,
    this.updatedAt,
  });

  final String? walkId;
  final String? suggestId;
  final DateTime? updatedAt;

  bool get hasSelection => suggestId != null && suggestId!.isNotEmpty;
}

@Riverpod(keepAlive: true)
class SelectedSuggestNotifier extends _$SelectedSuggestNotifier {
  @override
  SelectedSuggestState build() {
    ref.listen<WalkSession?>(activeWalkNotifierProvider, (prev, next) {
      final nextWalkId = next?.walkId;
      if (nextWalkId == null) {
        if (state.walkId != null || state.suggestId != null) {
          state = const SelectedSuggestState();
        }
        return;
      }
      if (state.walkId != nextWalkId) {
        state = SelectedSuggestState(walkId: nextWalkId);
      }
    });

    final active = ref.read(activeWalkNotifierProvider);
    return SelectedSuggestState(walkId: active?.walkId);
  }

  void select(String walkId, String suggestId) {
    if (walkId.isEmpty || suggestId.isEmpty) {
      return;
    }
    if (state.walkId == walkId && state.suggestId == suggestId) {
      return;
    }
    state = SelectedSuggestState(
      walkId: walkId,
      suggestId: suggestId,
      updatedAt: DateTime.now(),
    );
  }

  void selectLatest(String walkId, List<WalkSuggest> suggests) {
    if (walkId.isEmpty || suggests.isEmpty) {
      return;
    }
    if (state.walkId == walkId && state.suggestId != null) {
      return;
    }
    select(walkId, suggests.first.suggestId);
  }

  void clear() {
    if (state.suggestId == null) {
      return;
    }
    state = SelectedSuggestState(walkId: state.walkId);
  }
}

@Riverpod(keepAlive: true)
Stream<List<WalkSuggest>> walkSuggestList(
  Ref ref,
  String walkId,
) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || walkId.isEmpty) {
    return Stream.value(const <WalkSuggest>[]);
  }

  final query = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('walks')
      .doc(walkId)
      .collection('suggests')
      .orderBy('suggestedAt', descending: true);

  return query.snapshots().map((snapshot) {
    final result = <WalkSuggest>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final suggestId = data['suggestId'] as String? ?? doc.id;
      final position = _toLatLng(data['geo']);
      if (suggestId.isEmpty || position == null) {
        continue;
      }
      result.add(
        WalkSuggest(
          suggestId: suggestId,
          messageId: data['messageId'] as String?,
          position: position,
          suggestedAt: _toDateTime(data['suggestedAt']),
        ),
      );
    }
    return result;
  });
}

DateTime? _toDateTime(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

LatLng? _toLatLng(Object? value) {
  if (value is GeoPoint) {
    final lat = value.latitude;
    final lon = value.longitude;
    if (_isValidCoordinate(lat, lon)) {
      return LatLng(lat, lon);
    }
  }
  if (value is Map) {
    final lat = value['lat'] ?? value['latitude'];
    final lon = value['lon'] ?? value['longitude'];
    if (lat is num && lon is num && _isValidCoordinate(lat.toDouble(), lon.toDouble())) {
      return LatLng(lat.toDouble(), lon.toDouble());
    }
  }
  return null;
}

bool _isValidCoordinate(double lat, double lon) {
  if (!lat.isFinite || !lon.isFinite) {
    return false;
  }
  if (lat < -90 || lat > 90) {
    return false;
  }
  if (lon < -180 || lon > 180) {
    return false;
  }
  return true;
}
