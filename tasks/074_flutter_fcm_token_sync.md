# FCM トークン同期

## 背景 / 事象
- Job で FCM 通知を送るために `users.fcmToken` が必要
- 現状はクライアントからトークンを保存していない

## 目的
- ログイン/サインイン時に FCM トークンを Backend へ同期する

## 方針
- `firebase_messaging` でトークンを取得する
- `PATCH /v1/users/me` に `fcmToken` を送信する
- トークン取得/送信に失敗した場合はログのみ残す

## 要件
1. Firebase Messaging から FCM トークンを取得する
2. サインイン後にトークンを Backend へ送信する
3. `fcmToken` が未取得の場合はスキップする
4. `PATCH /v1/users/me` が `fcmToken` を受け付ける

## テスト
- ログイン後に `users/{userId}.fcmToken` が更新される
- `fcmToken` 未取得時に更新がスキップされる
