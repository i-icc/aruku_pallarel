import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../share/services/backend_exception.dart';
import '../infrastructure/user_api.dart';
import '../models/user_profile.dart';

part 'user_profile_provider.g.dart';

@Riverpod(keepAlive: true)
class UserProfileNotifier extends _$UserProfileNotifier {
  String? _syncedFcmToken;
  bool _syncingFcmToken = false;

  @override
  Future<UserProfile?> build() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    final fallbackNickname = _fallbackNickname(user);
    return _fetchOrCreate(fallbackNickname: fallbackNickname);
  }

  Future<UserProfile> refreshProfile({String? fallbackNickname}) async {
    state = const AsyncLoading();
    try {
      final profile = await _fetchOrCreate(
        fallbackNickname: fallbackNickname,
      );
      state = AsyncData(profile);
      return profile;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<UserProfile> _fetchOrCreate({
    String? fallbackNickname,
  }) async {
    final api = ref.read(userApiProvider);
    try {
      final profile = await api.fetchMe();
      await _syncFcmToken();
      return profile;
    } on BackendException catch (error) {
      if (error.code == 'USER_NOT_FOUND') {
        final nickname = _normalizeNickname(fallbackNickname);
        final profile = await api.createUser(nickname);
        await _syncFcmToken();
        return profile;
      }
      rethrow;
    }
  }

  Future<void> _syncFcmToken() async {
    if (_syncingFcmToken) {
      return;
    }
    _syncingFcmToken = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('fcm_token_skip: token unavailable');
        return;
      }
      if (token == _syncedFcmToken) {
        return;
      }
      await ref.read(userApiProvider).updateUser(fcmToken: token);
      _syncedFcmToken = token;
    } catch (error, stackTrace) {
      debugPrint('fcm_token_sync_failed: $error');
      debugPrint('$stackTrace');
    } finally {
      _syncingFcmToken = false;
    }
  }

  String _fallbackNickname(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return _normalizeNickname(user.email);
  }

  String _normalizeNickname(String? candidate) {
    final value = candidate?.trim();
    if (value == null || value.isEmpty) {
      return 'user';
    }
    final atIndex = value.indexOf('@');
    if (atIndex <= 0) {
      return value;
    }
    return value.substring(0, atIndex);
  }
}
