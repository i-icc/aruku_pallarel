# Cloud Tasks スタブで enqueue/dispatch フローを模擬（ローカル完結）

## 背景 / 事象
- 本番は Cloud Tasks 経由で Cloud Run Job を起動するため、ローカルでも enqueue → HTTP ターゲット呼び出しを模擬できるスタブが必要
- 後続のバックエンドやフロントの結合テストで、非同期ジョブ呼び出しの経路を確認したい

## 目的
- Cloud Tasks スタブを使い、enqueue からバックエンド/ジョブエンドポイントへの HTTP 呼び出しをローカルで再現する

## 方針
- シンプルな REST インターフェース（enqueue/list）を用意し、ターゲット URL への即時 HTTP POST で代替する
- ターゲット先は Backend 内のテストエンドポイントで良い（実処理は不要）

## 要件
1. Tasks スタブに enqueue API（例: `POST /tasks`）があり、payload と target URL を受け取れる
2. enqueue 受信後に target URL へ HTTP POST が行われることがログで確認できる
3. Backend にテスト用の受け皿エンドポイントがあり、呼び出しを受信できる

## テスト
- `curl` などで enqueue API を叩き、Backend の受け皿エンドポイントにリクエストが届くことをログで確認する
