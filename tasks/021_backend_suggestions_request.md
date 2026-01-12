# 提案リクエスト API（Cloud Tasks スタブ連携）

## 背景 / 事象
- 提案生成は非同期で行う想定だが、Backend からのキュー投入が未実装
- ローカルでは Cloud Tasks スタブを利用する方針

## 目的
- `POST /v1/walks/{walkId}/suggestions:request` を実装し、キュー投入までを確認する

## 方針
- クールダウン（5分）と散歩の `active` 状態をチェックする
- ローカルは `TASKS_STUB_URL` に HTTP で enqueue する

## 要件
1. `POST /v1/walks/{walkId}/suggestions:request` が `result: ok/ng` を返す
2. `lastSuggestionAt` が更新される
3. クールダウン中は `ng` を返す
4. ローカルで Cloud Tasks スタブに enqueue される

## テスト
- `TASKS_STUB_URL` が起動している状態で enqueue ログが出ることを確認する
