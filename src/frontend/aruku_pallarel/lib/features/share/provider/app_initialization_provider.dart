import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../firebase_options.dart';
import '../../../env/env.dart';
import '../../authentication/infrastructure/user_api.dart';

part 'app_initialization_provider.g.dart';

@Riverpod(keepAlive: true)
Future<void> appInitializationFuture(Ref ref) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  if (Env.useEmulators) {
    FirebaseAuth.instance.useAuthEmulator(
      Env.firebaseAuthEmulatorHost,
      Env.firebaseAuthEmulatorPort,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      Env.firestoreEmulatorHost,
      Env.firestoreEmulatorPort,
    );
  }

  await _setupMessaging(ref);
}

Future<void> _setupMessaging(Ref ref) async {
  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    String? lastToken;
    Future<void> syncToken(String? token) async {
      if (token == null || token.isEmpty) {
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || token == lastToken) {
        return;
      }
      lastToken = token;
      try {
        await ref.read(userApiProvider).updateUser(fcmToken: token);
      } catch (_) {
        // Ignore sync errors to avoid blocking app launch.
      }
    }

    await syncToken(await messaging.getToken());

    final tokenSub = messaging.onTokenRefresh.listen(syncToken);
    final authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        return;
      }
      await syncToken(await messaging.getToken());
    });
    ref.onDispose(() {
      tokenSub.cancel();
      authSub.cancel();
    });
  } catch (_) {
    // Ignore messaging setup errors to avoid blocking app launch.
  }
}
