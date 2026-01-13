import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../env/env.dart';

final appInitializationProvider = FutureProvider<void>((ref) async {
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

  await _verifySession();
  await _initializeFcm();
});

Future<void> _verifySession() async {
  await Future<void>.delayed(Duration.zero);
}

Future<void> _initializeFcm() async {
  await Future<void>.delayed(Duration.zero);
}
