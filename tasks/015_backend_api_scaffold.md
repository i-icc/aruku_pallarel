# Backend の /v1 基盤とエラーレスポンス整備

## 背景 / 事象
- Backend は `/health` など最低限のみで、API 仕様の `/v1` が未整備
- エラーレスポンスのフォーマットが未統一

## 目的
- `/v1` プレフィックスの API 基盤を用意し、エラー形式を spec に合わせる

## 方針
- Flask の Blueprint で `/v1` を切り出す
- 失敗時は `{ "error": { "code": "...", "message": "..." } }` を必ず返す

## 要件
1. `/v1` のルーティングが用意されている
2. 4xx/5xx は統一した JSON エラー形式で返る
3. 既存の `/health` は引き続き利用できる

## テスト
- `curl http://localhost:8000/v1/not-found` で JSON エラーが返ることを確認する
