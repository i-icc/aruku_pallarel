# Repository Guidelines

## Agent Obligations
- 作業開始前に最新の `README.md` を読む
- 仕様・ワークフローの変更が入る場合は `AGENTS.md` も更新する
- チャットの返答は日本語で行う

## Documentation Ownership
- `README.md`: セットアップと主要コマンドの概要のみ掲載する
- `spec/`: 仕様と詳細設計の一次情報（入口は `spec/README.md`）
- `AGENTS.md`: エージェント向けの作業ルールと注意事項
- `tasks/`: タスク定義と履歴（完了済みタスク本文は変更しない）
- `tmp/` : git 管理しないがメモしておきたいものなど

## Task Management
- 管理は `tasks/PROGRESS.md` と `tasks/` 配下のタスクファイルで行う
- 仕様変更や追加作業は `spec/` を更新しつつ新しいタスクを起票する
- 既存タスク本文は書き換えない

## Working Conventions
- 仕様変更は `spec/` を先に更新し、`README.md` は概要とリンクのみに反映する
- `spec/` 内に新規ドキュメントを追加したら `spec/README.md` に追記する
- ローカルの Backend/Emulator/Tasks スタブは `infrastructure/docker-compose.yml` を使用する
- Backend/ADK は `uv` で依存管理し、起動・開発は Docker Compose を優先する
- Backend/ADK の `pyproject.toml`/`README.md` は各ディレクトリで独立管理する
- Backend エミュレーター利用時は ADC を用意し、`GOOGLE_APPLICATION_CREDENTIALS` と gcloud 設定のマウントを行う
- Flutter/Dart のコマンドは必ず `fvm` 経由で実行する（例: `fvm flutter`, `fvm dart`）
- バグ修正時は `tasks/` にチケットを起票してから対応する
- Dependabot はセキュリティ更新を優先し、minor/patch 更新はグルーピングでまとめる
