# Firebase ID Token 検証ミドルウェアの追加

## 背景 / 事象
- API は Firebase ID Token 認証が必須だが、現状は未実装
- 認証済みユーザーの UID を後続処理に渡したい

## 目的
- `Authorization: Bearer <token>` を検証し、UID を取得できるようにする

## 方針
- 検証に失敗した場合は `401` を返す
- 検証済み UID を request コンテキストに保持する

## 要件
1. Authorization ヘッダーが無い場合は `401` を返す
2. 不正なトークンは `401` を返す
3. 検証済み UID が API 実装側で参照できる

## テスト
- Auth Emulator で取得した ID Token を付けてリクエストし、`uid` が取得できることを確認する
