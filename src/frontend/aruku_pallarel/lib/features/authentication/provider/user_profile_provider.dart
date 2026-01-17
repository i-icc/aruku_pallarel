import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../share/services/backend_exception.dart';
import '../infrastructure/user_api.dart';
import '../models/user_profile.dart';

part 'user_profile_provider.g.dart';

@Riverpod(keepAlive: true)
class UserProfileNotifier extends _$UserProfileNotifier {
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
      return await api.fetchMe();
    } on BackendException catch (error) {
      if (error.code == 'USER_NOT_FOUND') {
        final nickname = _normalizeNickname(fallbackNickname);
        return api.createUser(nickname);
      }
      rethrow;
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
