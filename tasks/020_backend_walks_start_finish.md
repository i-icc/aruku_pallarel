# Walks 開始/終了 API の実装

## 背景 / 事象
- 散歩開始/終了 API が未実装
- `active` な散歩は 1 件までという制約がある

## 目的
- `POST /v1/walks` と `POST /v1/walks/{walkId}:finish` を実装する

## 方針
- `users/{uid}/walks/{walkId}` に保存する
- `active` の重複はトランザクションで防止する

## 要件
1. `POST /v1/walks` が `startLocation` を受け取り walk を作成する
2. 既に `active` がある場合は `WALK_ALREADY_ACTIVE` を返す
3. `POST /v1/walks/{walkId}:finish` で `status=finished` と `finishedAt` を更新する
4. 認証必須である

## テスト
- `POST /v1/walks` を連続で実行すると 2 回目がエラーになることを確認する
- `finish` 実行後に `status=finished` になることを確認する
