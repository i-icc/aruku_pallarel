# 提案リクエスト ng の調査ログ追加

## 背景 / 事象
- 提案リクエストが `ng` になるが、原因がログから追えない

## 目的
- Backend/Frontend の両方にデバッグログを追加し、`ng` 理由を特定できるようにする

## 方針
- Backend は `ng` 理由・距離・ポイント数をログに出す
- Frontend は送信/結果のみを debug ログに出す（debug ビルド限定）

## 要件
1. Backend で `walk_inactive` / `cooldown` / `distance_short` / `enqueue_failed` をログ出力する
2. Frontend で送信時と結果を debug ログに出す
3. ログが出ることを確認できる

## テスト
- 250m 未満で `distance_short` がログ出力される
- 送信時に Frontend のログが出る
