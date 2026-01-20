# 散歩開始/終了の UI と Backend 連携

## 背景 / 事象
- Backend の散歩開始/終了 API は実装済みだが、アプリから呼ばれていない

## 目的
- ホーム画面から散歩開始/終了を操作できるようにする

## 方針
- Home → Walk 画面遷移時に `/v1/walks` を呼び出す
- 散歩終了時に `/v1/walks/{walkId}:finish` を呼び出す

## 要件
1. 散歩開始ボタンで `/v1/walks` を呼び出し walkId を保持する
2. 既存 active がある場合は `WALK_ALREADY_ACTIVE` を表示する
3. 散歩終了ボタンで `/v1/walks/{walkId}:finish` を呼び出す
4. 散歩終了後はホームへ戻る

## テスト
- 連続で開始すると 2 回目がエラーになること
- 終了後に Firestore の `status=finished` が確認できること
