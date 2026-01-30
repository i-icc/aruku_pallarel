# Firestore FieldValue 未定義で ingest が落ちる問題

## 背景
- `firebase_admin.firestore` に `FieldValue` が無く、`append_location_points` が例外になる
- `test_walks_locations_ingest_stores_points` が 500 で失敗する

## ゴール
- FieldValue が無い環境でも increment/arrayUnion が動作する
- 位置情報の ingest テストが成功する

## ToDo
- [ ] increment/arrayUnion の互換ラッパーを追加する
- [ ] ingest の保存処理を互換ラッパー経由に変更する

## 受け入れ条件
- `FieldValue` が無い環境でも ingest が 500 にならない
- `test_walks_locations_ingest_stores_points` が通る
