# Flutter 本番接続準備（Firebase/環境変数/トークン）

## 背景 / 事象
- Flutter は emulator 向け `.env` とダミーの FirebaseOptions を使っている
- 本番 Cloud Run/Firebase に接続するための設定とファイルが未整備
- Firebase 設定ファイルや地図トークンのダウンロードが必要

## 目的
- 本番 Firebase/Backend に接続できる Flutter 設定をそろえる
- 必要な設定ファイル/トークンを揃える

## ToDo
- [ ] Android/iOS の applicationId/bundleId を確定し、`android/app/build.gradle.kts` と iOS の bundleId を揃える
- [ ] Firebase コンソールで Android/iOS アプリを登録する（bundleId/applicationId を一致させる）
- [ ] Firebase コンソールから `google-services.json` と `GoogleService-Info.plist` を取得して配置する
- [ ] FlutterFire CLI を導入し、`flutterfire configure` で `lib/firebase_options.dart` を生成する
- [ ] `app_initialization_provider.dart` を `DefaultFirebaseOptions.currentPlatform` で初期化する
- [ ] `.env` を本番値へ更新する（`BACKEND_BASE_URL`, `FIREBASE_PROJECT_ID`, `USE_EMULATORS=false`, `JAWG_ACCESS_TOKEN`）
- [ ] `firebase_messaging` を追加し、起動時に `requestPermission` を実行する
- [ ] FCM の background handler をトップレベル関数 + `@pragma('vm:entry-point')` で登録する（必要なら `Firebase.initializeApp` を呼ぶ）
- [ ] `onMessage` / `onMessageOpenedApp` / `getInitialMessage` を接続し、通知タップ時の導線を決める
- [ ] `FirebaseMessaging.instance.getToken()` と `onTokenRefresh` でトークンを取得し、`/v1/users/me` の `fcmToken` に同期する
- [ ] ログアウト時のトークン削除方針（API 仕様のままか拡張するか）を決める
- [ ] iOS: Push Notifications / Background Modes を有効化し、APNs キーを Firebase に登録する
- [ ] Android 13+: POST_NOTIFICATIONS 権限と通知チャネル（foreground 表示の方法）を確認する
- [ ] 実機でログイン/通知受信/トークン同期を確認する（iOS は実機必須）

## 注意点（FCM）
- iOS/Android 13 では `requestPermission` を明示的に実行しないと通知を受信できない
- background handler はトップレベル関数で、`@pragma('vm:entry-point')` が必要
- foreground では通知が自動表示されないため、表示方法（ローカル通知 or UI 表示）を決める
- data-only メッセージは OS 通知が出ないため、通知表示が必要なら通知ペイロード or ローカル通知が必要
- トークンは再インストールや更新で変わるため、`onTokenRefresh` で必ず同期する
- iOS は Simulator で Push を受け取れないため、実機確認が必須

## テスト
```bash
cd src/frontend/aruku_pallarel
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
```

## 受け入れ条件
- Firebase 設定ファイルと FirebaseOptions が本番値になっている
- `.env` が本番値になり、emulator を使わない設定になっている
- 実機でログインと backend API の疎通ができる
- FCM token がバックエンドに同期される
