# Locus の位置更新で Firestore に記録（distanceFilter 15m）

## 背景 / 事象
- 位置情報は Locus v2 を採用し、distanceFilter で更新を受ける方針に変更した
- 20 秒ポーリング前提の `032` は仕様が合わなくなった

## 目的
- 散歩中の位置情報を Locus の更新ストリームで取得し、Firestore に記録する

## 方針
- Locus の `location.stream` を購読し、distanceFilter 15m の更新だけを扱う
- 位置更新をバッファして一定件数でバッチ保存する
- 散歩終了時に残っているバッファをフラッシュする

## 要件
1. `users/{uid}/walks/{walkId}/locations/{batchId}` に保存する
2. `points` には `timestamp` と `geo`（lat/lon）を入れる
3. `createdAt` を server timestamp で記録する
4. バッファは 50〜100 件で切って保存する
5. 散歩終了時にバッファがあればフラッシュする

## テスト
- 位置偽装で 15m 以上移動すると Firestore に追加されること
- 散歩終了時にバッファが残っていれば保存されること

## 備考
- 本タスクは `032`（20 秒ポーリング）を置き換える
