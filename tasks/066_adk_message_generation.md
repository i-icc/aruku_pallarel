# ADK メッセージ生成連携

## 背景 / 事象
- ADK スタブは health のみで、座標から文言生成ができない
- Job から ADK 呼び出しを行う必要がある

## 目的
- ADK の入力/出力を実装し、Job からメッセージ取得できるようにする

## 方針
- ADK に生成エンドポイントを追加し、`lat` / `lon` を受け取る
- 返却は `{"message": "..."}` のみとする
- リトライは Cloud Tasks に委ね、Job 側は失敗時に request を failed に更新する

## 要件
1. ADK サービスに生成エンドポイントを追加する
2. 入力バリデーション（lat/lon 必須）を行う
3. Job から ADK を呼び出し message を取得できる
4. 失敗時は `requests.status=failed` に更新する

## テスト
- ADK 単体で生成 API の疎通を確認する
- Job から ADK を呼び出して message が取れることを確認する
