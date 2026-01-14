import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../env/env.dart';

part 'app_initialization_provider.g.dart';

@Riverpod(keepAlive: true)
Future<void> appInitializationFuture(Ref ref) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: Platform.isIOS
            ? '1:1234567890:ios:abcdef1234567890'
            : '1:1234567890:android:abcdef1234567890',
        messagingSenderId: '1234567890',
        projectId: Env.firebaseProjectId,
        iosBundleId: Platform.isIOS ? 'com.example.arukuPallarel' : null,
      ),
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
}
