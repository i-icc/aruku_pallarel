# ADK 呼び出しのタイムアウト対策

## 背景 / 事象
- suggestion-job 実行時に ADK 呼び出しで TimeoutError が発生する
- 例外が捕捉されず、ジョブが 500 で落ちる

## ゴール
- タイムアウトを適切にハンドリングできる
- 必要に応じてタイムアウトを延長できる

## ToDo
- [ ] ADK クライアントで TimeoutError を捕捉し、RuntimeError に変換する
- [ ] `ADK_TIMEOUT_SECONDS` の既定値を見直す
- [ ] suggestion-job の環境変数でタイムアウトを調整できるようにする
- [ ] 失敗時のログ（URL/timeout）を追える状態にする

## 受け入れ条件
- TimeoutError が 500 ではなく `adk_failed` として扱われる
- タイムアウト値の調整で再現が収束する
