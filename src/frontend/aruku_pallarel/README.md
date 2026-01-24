# aruku_pallarel

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

Flutter/Dart のコマンドは必ず `fvm` 経由で実行する。

## Firebase/FCM (iOS) セットアップ
- `ios/Runner/GoogleService-Info.plist` を配置（git 管理可）
- FlutterFire CLI で `flutterfire configure` を実行し、`lib/firebase_options.dart` を生成（git 管理可）
- APNs 認証キー (`.p8`) は git 管理しない
- Xcode の Runner ターゲットで Push Notifications / Background Modes (Remote notifications) を有効化
- Firebase コンソールの Cloud Messaging で APNs Key を登録
