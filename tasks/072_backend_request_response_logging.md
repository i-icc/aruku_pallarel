# Backend のリクエスト/レスポンスログ追加

## 背景 / 事象
- 提案リクエストの挙動確認で、リクエスト/レスポンスのログが不足している

## 目的
- Backend/Suggestion Job でリクエストとレスポンスをログに残す

## 方針
- Flask の before/after フックで JSON payload をログ出力する
- 長い payload は上限でトリムする

## 要件
1. リクエストの method/path/payload をログ出力する
2. レスポンスの status/duration/payload をログ出力する
3. Suggestion Job でも同様にログが出る

## テスト
- API 呼び出しで request/response のログが出ること
