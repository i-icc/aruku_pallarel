# Flutter アプリ基盤の整備（Riverpod / auto_route）

## 背景 / 事象
- 現状は `main.dart` に UI とロジックが集中している
- 仕様とテンプレートでは Riverpod + auto_route を前提にしている
- ディレクトリ構成・初期化フロー・コード生成の前提が揃っていない

## 目的
- 仕様/テンプレートのディレクトリ構成に沿って Flutter 基盤を整える

## 方針
- Riverpod の `ProviderScope`、auto_route のルーティング/ガードを導入
- テンプレートの構成に合わせて `screens/` と `features/` を整理
- `theme`/`router`/`gen` を追加し、コード生成の入口を整える
- 既存のログイン/ホーム画面は崩さず移行する

## 依存（基盤で導入する想定）
- 状態管理: `hooks_riverpod`, `riverpod_annotation`, `riverpod_generator`, `flutter_hooks`
- ルーティング: `auto_route`, `auto_route_generator`
- アセット: `flutter_gen_runner`, `flutter_svg`
- 初期化: `flutter_native_splash`

## 要件
1. `lib/` 配下を以下の構成に整理する
   - `env/`, `gen/`, `router/`, `theme/`, `screens/`, `features/`
   - `router` に `app_router.dart`, `auth_guard.dart`, `route_extensions.dart`
   - `screens/base.dart` に BottomNavigationBar を持つベース画面
2. auto_route で Auth / Home / Walk / History / Settings / Chat の骨組みルートを用意する
   - Auth ガードで認証済み/未認証の遷移制御を行う
3. Riverpod の ProviderScope と初期化フローを `main.dart` に導入する
   - Firebase 初期化 / セッション検証 / FCM 初期化のフックポイントを用意
4. `features/share` を作成し、共通 provider/services/utils を配置できる土台を作る
5. `flutter_gen` による `lib/gen/assets.gen.dart` の生成導線を整える
6. 既存のログイン/ホーム機能が破綻しないこと

## テスト
- `fvm dart run build_runner build --delete-conflicting-outputs` が通ること
- `fvm flutter run` でログイン → ホームに遷移できることを確認する
