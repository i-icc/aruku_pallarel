# Users 作成/取得 API の実装

## 背景 / 事象
- ユーザー登録後のプロフィール保存が未実装
- `/v1/users` と `/v1/users/me` が spec で定義済み

## 目的
- ユーザープロフィールを Firestore に保存し取得できるようにする

## 方針
- Firestore の `users/{uid}` に保存する
- `createdAt` / `lastLoginAt` を server timestamp で記録する

## 要件
1. `POST /v1/users` が `nickname` を受け取り、`users/{uid}` を作成する
2. `GET /v1/users/me` で現在ユーザー情報を返す
3. 認証必須である

## テスト
- Auth Emulator で取得した ID Token を付けて `POST /v1/users` を実行し、Firestore に保存されることを確認する
