import 'package:flutter/widgets.dart';
import 'package:locus/locus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _userIdKey = 'walk_sync_user_id';
const _walkIdKey = 'walk_sync_walk_id';
const _lastSyncedAtKey = 'walk_sync_last_synced_at_ms';

Future<void> saveWalkSyncContext({
  required String userId,
  required String walkId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_userIdKey, userId);
  await prefs.setString(_walkIdKey, walkId);
  await prefs.remove(_lastSyncedAtKey);
}

Future<void> clearWalkSyncContext() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_userIdKey);
  await prefs.remove(_walkIdKey);
  await prefs.remove(_lastSyncedAtKey);
}

Future<void> updateLastSyncedAt(DateTime timestamp) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
    _lastSyncedAtKey,
    timestamp.toUtc().millisecondsSinceEpoch,
  );
}

Future<int?> loadLastSyncedAtMillis() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_lastSyncedAtKey);
}

@pragma('vm:entry-point')
Future<JsonMap> buildHeadlessLocationSyncBody(SyncBodyContext context) async {
  WidgetsFlutterBinding.ensureInitialized();
  return _buildLocationSyncBody(
    context.locations,
    context.extras,
  );
}

Future<JsonMap> buildForegroundLocationSyncBody(
  List<Location> locations,
  JsonMap extras,
) async {
  return _buildLocationSyncBody(locations, extras);
}

Future<JsonMap> _buildLocationSyncBody(
  List<Location> locations,
  JsonMap extras,
) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString(_userIdKey);
  final walkId = prefs.getString(_walkIdKey);
  final lastSyncedAtMs = prefs.getInt(_lastSyncedAtKey) ?? 0;

  final filtered = <JsonMap>[];
  for (final location in locations) {
    final coords = location.coords;
    if (!coords.isValid) {
      continue;
    }
    final timestamp = location.timestamp.toUtc();
    if (timestamp.millisecondsSinceEpoch <= lastSyncedAtMs) {
      continue;
    }
    filtered.add(
      {
        'timestamp': timestamp.toIso8601String(),
        'lat': coords.latitude,
        'lon': coords.longitude,
        if (location.uuid.isNotEmpty) 'uuid': location.uuid,
      },
    );
  }

  return {
    'userId': userId,
    'walkId': walkId,
    'locations': filtered,
    if (extras.isNotEmpty) 'extras': extras,
  };
}
