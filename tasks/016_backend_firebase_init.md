# Backend の Firebase Admin / Firestore 初期化

## 背景 / 事象
- Firebase Auth/Firestore を使う API 実装の前提が未整備
- ローカル開発ではエミュレーターを優先して使う必要がある

## 目的
- Firebase Admin SDK を初期化し、Firestore クライアントを取得できる状態にする

## 方針
- `FIREBASE_AUTH_EMULATOR_HOST` / `FIRESTORE_EMULATOR_HOST` を利用し、ローカルではエミュレーターを使う
- `PROJECT_ID` を必須設定として扱う

## 要件
1. `firebase-admin` と Firestore クライアント依存が追加されている
2. Firebase 初期化が 1 回だけ行われる
3. エミュレーター環境変数が設定されていればローカルを参照する

## テスト
- `docker compose -f infrastructure/docker-compose.yml up` で Backend が起動し、初期化エラーが出ないことを確認する
