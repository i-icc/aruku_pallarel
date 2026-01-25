# Repository Guidelines

## Agent Obligations
- 作業開始前に最新の `README.md` を読む
- 仕様・ワークフローの変更が入る場合は `AGENTS.md` も更新する
- チャットの返答は日本語で行う
- チャットでは不要な自己メモ（「整理しました」など）を省き、必要な変更点と次アクションのみ伝える
- CI の WIF 条件はリポジトリ単位で制限し、ブランチ制限は設けない
- GAR Push の差分判定は push の commit 範囲で行い、手動実行は全ビルドする

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
- Firebase Auth のサインイン方式は Terraform で管理する
- バグ修正時は `tasks/` にチケットを起票してから対応する
