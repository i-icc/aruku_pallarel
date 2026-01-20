# 認証後のプロフィール取得と Backend 連携

## 背景 / 事象
- Firebase Auth でログインできるが、Backend の `/v1/users` 連携が未実装
- ホーム画面でユーザー情報を表示できていない

## 目的
- 認証後に Backend のユーザープロフィールを作成/取得できるようにする

## 方針
- Dio + Interceptor で ID Token を付与して Backend を呼び出す
- `/v1/users/me` が 404 の場合は `/v1/users` を作成する

## 要件
1. ID Token を `Authorization: Bearer` で送信する
2. サインアップ時に `/v1/users` を作成する
3. ログイン時に `/v1/users/me` を取得し、無い場合は作成する
4. ホーム画面に nickname を表示する

## テスト
- Auth Emulator で新規登録 → ホーム表示時に nickname が表示されること
