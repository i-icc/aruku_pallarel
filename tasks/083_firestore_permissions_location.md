# Firestore 権限エラーと現在地フォールバックの調査/修正

## 背景 / 事象
- 実機で Firestore の `[cloud_firestore/permission-denied]` が発生する
- 位置情報許可済みでも東京駅固定のフォールバックになる
- suggestion_request が `ng` になり続ける

## 目的
- 本番 Firestore で認証済みユーザーの読み書きが成功する
- 現在地が取得できる場合は実測位置で開始し、フォールバックは必要時のみ使う

## ToDo
- [ ] ログイン直後の UID を確認し、Firestore クエリが正しいパス（`users/{uid}`）を参照しているか確認する
- [ ] 本番 Firestore ルール/インデックスの適用状況を確認する（Firebase Console or CLI）
- [ ] `infrastructure/firebase/firestore.rules` と `infrastructure/firebase/firestore.indexes.json` を本番へ反映する
- [ ] `users/{uid}` や `users/{uid}/walks` が作成される導線（Backend 連携）が動いているか確認する
- [ ] `status == active` のクエリで必要なインデックスが不足していないか確認する
- [ ] 位置情報許可と Locus の位置更新が実際に流れているかログで確認する
- [ ] 位置偽装トグルが無効であることを確認する
- [ ] 位置取得前の画面挙動（ローディング/最後の位置/フォールバック）を整理し、必要なら実装する
- [ ] suggestion_request の `ng` が Firestore/active walk 未作成に起因していないか確認する

## 受け入れ条件
- ログイン後に Firestore の権限エラーが発生しない
- Active walk 取得が成功し、フォールバックではなく現在地で開始する
- suggestion_request が `ng` 連発しない
