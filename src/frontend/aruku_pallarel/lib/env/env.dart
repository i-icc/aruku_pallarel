import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'BACKEND_BASE_URL')
  static const String backendBaseUrl = _Env.backendBaseUrl;

  @EnviedField(varName: 'FIREBASE_PROJECT_ID')
  static const String firebaseProjectId = _Env.firebaseProjectId;

  @EnviedField(varName: 'FIREBASE_AUTH_EMULATOR_HOST')
  static const String firebaseAuthEmulatorHost = _Env.firebaseAuthEmulatorHost;

  @EnviedField(varName: 'FIREBASE_AUTH_EMULATOR_PORT')
  static const int firebaseAuthEmulatorPort = _Env.firebaseAuthEmulatorPort;

  @EnviedField(varName: 'FIRESTORE_EMULATOR_HOST')
  static const String firestoreEmulatorHost = _Env.firestoreEmulatorHost;

  @EnviedField(varName: 'FIRESTORE_EMULATOR_PORT')
  static const int firestoreEmulatorPort = _Env.firestoreEmulatorPort;

  @EnviedField(varName: 'USE_EMULATORS')
  static const bool useEmulators = _Env.useEmulators;
}
