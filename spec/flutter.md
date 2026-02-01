# Flutter 技術仕様

## 技術スタック
- Flutter (最新 stable, FVM で管理)
- 状態管理: Riverpod + コード生成 (`riverpod_generator`)
- ルーティング: auto_route + 認証ガード
- API 通信: Dio + Interceptor
- データモデル: Freezed + json_serializable
- 環境変数: envied
- 地図: flutter_map + OpenStreetMap タイル
- 位置情報: location

## 開発ルール
- Flutter/Dart のコマンドは必ず `fvm` 経由で実行する

## ディレクトリ構造
```
lib/
├── main.dart
├── env/
│   └── env.dart
├── router/
│   ├── app_router.dart
│   └── auth_guard.dart
├── theme/
│   └── app_theme_provider.dart
├── screens/
│   ├── base.dart
│   ├── authentication/
│   ├── home/
│   ├── walk/
│   ├── chat/
│   ├── history/
│   └── settings/
└── features/
    ├── share/
    │   ├── domains/
    │   │   ├── data/
    │   │   ├── entities/
    │   │   └── repositories/
    │   ├── infrastructure/
    │   │   └── api/
    │   ├── presentation/
    │   ├── provider/
    │   ├── services/
    │   └── utils/
    ├── authentication/
    ├── walk/
    ├── chat/
    └── history/
```

## 主要パッケージ
| カテゴリ | パッケージ |
|---------|-----------|
| 状態管理 | `hooks_riverpod`, `riverpod_annotation`, `flutter_hooks` |
| ルーティング | `auto_route` |
| API | `dio` |
| モデル | `freezed_annotation`, `json_annotation` |
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging` |
| 地図/位置 | `flutter_map`, `latlong2`, `location` |
| UI | `gap`, `loading_animation_widget`, `url_launcher` |
| dev | `build_runner`, `riverpod_generator`, `auto_route_generator`, `freezed`, `json_serializable`, `envied_generator` |

## コード生成
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 初期化フロー
1. WidgetsFlutterBinding.ensureInitialized()
2. FlutterNativeSplash.preserve()
3. Firebase.initializeApp()
4. 認証トークン確認
5. FCM 初期化
6. FlutterNativeSplash.remove()

---

## 関連ドキュメント
- → [システム構成](./system.md): アーキテクチャ全体像
- → [UX仕様](./ux.md): 画面構成とユーザーフロー
- → [API設計](./api.md): バックエンドとの通信仕様
