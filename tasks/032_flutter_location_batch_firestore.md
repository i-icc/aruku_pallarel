# 位置情報のバッチ保存（Firestore）

## 背景 / 事象
- 仕様では 20 秒ごとの位置情報を Firestore に保存する
- 1 ドキュメントの上限を考慮しバッチ化が必要

## 目的
- 散歩中の位置情報を `locations` サブコレクションへ記録する

## 方針
- 20 秒間隔で現在地を取得し、移動がある場合のみ追加
- 50〜100 件でバッチを切って保存する

## 要件
1. `users/{uid}/walks/{walkId}/locations/{batchId}` に保存する
2. `points` には `timestamp` と `geo` を入れる
3. `createdAt` を server timestamp で記録する
4. 散歩終了時にバッファがあればフラッシュする

## テスト
- 散歩中に Firestore に location ドキュメントが追加されること
