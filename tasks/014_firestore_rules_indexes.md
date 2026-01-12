# Firestore ルール/インデックスを MVP 仕様に合わせる

## 背景 / 事象
- 現状の Firestore ルールが全許可で、ユーザー自身のデータに限定できていない
- MVP のデータ取得に必要なインデックスを明示したい

## 目的
- Firestore の読み書きが「ログイン済みユーザー本人のドキュメントのみ」に限定される
- `walks` 取得で使う基本インデックスを定義する

## 方針
- `users/{userId}` 配下のみアクセス可能にする
- `walks` の `status + startedAt` で並び替えるケースに備えてインデックスを追加する

## 要件
1. `infrastructure/firebase/firestore.rules` が本人のみ読み書き可になっている
2. `infrastructure/firebase/firestore.indexes.json` に `walks` のインデックスが追加されている

## テスト
- エミュレーターで自分の UID の配下は読めるが、他 UID では拒否されることを確認する
