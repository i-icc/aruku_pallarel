# Flutter をローカル Backend/Firebase Emulator に接続し、ログイン〜ホーム表示まで確認

## 背景 / 事象
- ローカル Backend と Firebase Emulator を対象に Flutter を接続し、ログインフローとホーム表示を確認したい
- エミュレーター接続設定と環境変数を整備する

## 目的
- ローカル環境で Flutter アプリを起動し、Auth Emulator のテストユーザーでログイン → 空のホーム画面を表示する

## 方針
- Backend baseUrl と Firebase Emulator のホスト/ポートを環境変数で切り替えられるようにする
- コード生成（build_runner）が通る状態で確認する

## 要件
1. Flutter の環境設定に Backend (compose) と Firebase Auth/Firestore Emulator のホスト/ポートが追加されている
2. Auth Emulator に投入したテストユーザーの資格情報でログインできる
3. ログイン後、空のホーム画面が表示される（最低限の UI で可）
4. `flutter pub get` と必要なコード生成が成功する

## テスト
- ローカル compose を起動した状態で Flutter アプリを実行し、テストユーザーでログイン → ホーム画面表示を手動確認
