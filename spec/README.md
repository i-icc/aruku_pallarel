# 仕様書インデックス
このディレクトリが一次情報です。`README.md` にはセットアップと主要コマンドの概要のみを記載します。

## 仕様一覧
| ドキュメント | 内容 |
|-------------|------|
| [overview.md](./overview.md) | プロダクト概要とスコープ |
| [ux.md](./ux.md) | ユーザーフローと画面構成 |
| [system.md](./system.md) | システム構成と処理フロー |
| [data-model.md](./data-model.md) | Firestore データ設計 |
| [api.md](./api.md) | API 設計（Flask / Cloud Run） |
| [ai.md](./ai.md) | エージェント / LLM 設計 |
| [flutter.md](./flutter.md) | Flutter 技術仕様 |
| [osrm.md](./osrm.md) | OSRM データ/イメージ運用 |

## 更新ルール
- 仕様変更は `spec/` を最初に更新する
- 仕様更新がタスクに影響する場合は `tasks/` に新規タスクを起票する
- 既存タスク本文は変更しない
