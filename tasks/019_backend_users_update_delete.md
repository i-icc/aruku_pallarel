# Users 更新/削除 API の実装

## 背景 / 事象
- ユーザー情報更新と退会削除が未実装
- spec では `PATCH /v1/users/me` と `DELETE /v1/users/me` が定義されている

## 目的
- ユーザー情報の更新と退会削除を Backend で実装する

## 方針
- 更新は `nickname` のみ対応する
- 削除は `users/{uid}` と配下の `walks/locations/suggests/chat` を削除する

## 要件
1. `PATCH /v1/users/me` で `nickname` を更新できる
2. `DELETE /v1/users/me` でユーザーと関連データが削除される
3. 認証必須である

## テスト
- `PATCH /v1/users/me` の結果が Firestore に反映されることを確認する
- `DELETE /v1/users/me` 実行後にユーザー配下ドキュメントが無いことを確認する
