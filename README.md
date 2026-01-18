# あるく🚶パラレル (machi-danjon)
散歩の未知性を壊さず、あとから“もしも”を楽しめるAIエージェントを目指すハッカソン向けプロジェクトです。

## ドキュメント
- `spec/README.md` 仕様書の入口（一次情報）
- `spec/overview.md` プロダクト概要/スコープ
- `spec/ux.md` ユーザーフロー
- `spec/system.md` システム構成
- `spec/data-model.md` Firestore設計
- `spec/api.md` API設計
- `spec/ai.md` エージェント設計
- `tasks/PROGRESS.md` タスク管理

## クイックスタート（Flutter）
前提:
- Flutter SDK
- iOS: Xcode / Android: Android Studio
- Firebase設定ファイル（`google-services.json`, `GoogleService-Info.plist`）※必要な場合

```bash
cd src/frontend/aruku_pallarel
fvm flutter pub get
fvm flutter run
```

必要な場合のコード生成:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

テスト:

```bash
fvm flutter test
```

バックエンドは仕様整備を優先しており、実装はこれからです。詳細は `spec/` を参照してください。

## クイックスタート（Backend）
```bash
docker compose -f infrastructure/docker-compose.yml up -d backend
```
ADC の設定が必要です。詳細は `src/backend/main-backend-server/README.md` を参照してください。

## リポジトリ構成
- `src/frontend/aruku_pallarel` Flutterアプリ
- `spec/` 仕様書
- `tasks/` タスク管理

## 全体像（概要）

![architecture](./spec/images/machi-dan.drawio.png)