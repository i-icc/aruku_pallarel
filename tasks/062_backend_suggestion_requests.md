# 提案リクエストの requests 化と判定強化

## 背景 / 事象
- 提案リクエストは `lastSuggestionAt` ベースだが、`requests` ドキュメントで冪等管理する方針に変更した
- 移動距離の閾値判定が未実装

## 目的
- `POST /v1/walks/{walkId}/suggestions:request` を requests ドキュメントと距離/時間判定で運用できる状態にする

## 方針
- `requests/{requestId}` を作成し、status を `queued` で保存する
- 判定は「前回の result: ok リクエスト」基準で時間・距離を計算する
- 閾値は設定値（初期値 5 分 / 250m）として定数化する

## 要件
1. `result: ok` の場合、`requests` を作成し `requestId` を返す
2. Cloud Tasks の payload に `requestId` / `userId` / `walkId` を含める
3. `result: ng` の場合は理由を返さず、ログのみ残す
4. 移動距離は locations を時系列にフラット化し、前回 ok 時点以降の合計距離で判定する
5. `lastSuggestionAt` / `suggestCount` には依存しない

## テスト
- Backend tests で `ng` 判定（時間/距離）と `requests` 作成を確認する
- `TASKS_STUB_URL` を使った enqueue が `requestId` を含むことを確認する
