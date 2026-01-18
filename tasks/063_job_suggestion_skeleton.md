# 提案生成 Job の基盤と request status 管理

## 背景 / 事象
- 提案生成を実行する Job サービスが存在しない
- `requests` の status を用いた冪等処理の土台が必要

## 目的
- Cloud Run Job 相当の HTTP サービスを追加し、request status を安全に遷移できるようにする

## 方針
- `src/backend/suggestion-job` を新設し、uv / Docker で起動可能にする
- `POST /jobs/suggestions` で `requestId` を受け取り、`queued` → `running` を許可する
- `running` / `done` / `failed` の場合は 200 で終了する

## 要件
1. health endpoint と suggestions endpoint を持つサービスを追加する
2. `requestId` が存在しない場合は 400 を返す
3. status 遷移は `queued` → `running` のみ許可する
4. 未実装段階は `failed` と `error=not_implemented` を記録して完了させる
5. `infrastructure/docker-compose.yml` から起動できるようにする

## テスト
- Firestore Emulator で request status の遷移を確認する
- `docker compose -f infrastructure/docker-compose.yml up` で health が取れることを確認する
