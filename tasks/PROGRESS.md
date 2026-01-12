# 開発進捗

このファイルはタスクの進捗状況を管理します。各タスクの詳細は同じディレクトリ内の各タスクファイルを参照してください。
- ドキュメントの更新方針は `README.md` の「ドキュメント構成」セクションおよび `AGENTS.md` を参照してください。

##  完了済み

- 000: タスクタイトルサンプル
- 001: docker compose で Backend + Firebase Emulator + Tasks スタブを起動
- 002: Backend 環境変数とエミュレーター初期化（ローカル完結）
- 003: Cloud Tasks スタブで enqueue/dispatch フローを模擬（ローカル完結）
- 004: Flutter をローカル Backend/Firebase Emulator に接続し、ログイン〜ホーム表示まで確認
- 005: Terraform ブートストラップ (GCP プロジェクト手動作成後)
- 006: VPC / Serverless VPC Connector / NAT / Artifact Registry を Terraform で作成
- 007: Cloud Run (Backend/ADK/OSM) / Cloud Run Job / Cloud Tasks を Terraform で定義
- 008: ログイン後に Backend/Emulator へ通信が発生しない
- 009: ローカルでメール/パスワードのアカウント登録ができない
- 010: PR 作成時に Flutter analyze を実行する CI を追加
- 011: Flutter analyze の CI を差分があるときだけ実行する
- 012: Terraform で Firebase プロジェクト作成が失敗する
- 013: Terraform apply が Firebase Messaging で失敗する
- 014: Firestore ルール/インデックスを MVP 仕様に合わせる
- 015: Backend の /v1 基盤とエラーレスポンス整備
- 016: Backend の Firebase Admin / Firestore 初期化
- 017: Firebase ID Token 検証ミドルウェアの追加
- 018: Users 作成/取得 API の実装
- 019: Users 更新/削除 API の実装
- 020: Walks 開始/終了 API の実装
- 021: 提案リクエスト API（Cloud Tasks スタブ連携）
- 022: Backend/ADK サーバーの配置見直し
- 023: Backend を uv で起動できるようにする
- 024: Backend/ADK を uv + Docker 前提で再整備
- 025: Backend テストを GitHub Actions で実行する
- 026: Backend CI の setup-uv 警告を解消する
- 027: Backend 構造整理と ADC 設定

## 未着手(優先順位順)
- なし

## 最終更新
最終更新日: 2026-01-12
前回完了タスク: 027
