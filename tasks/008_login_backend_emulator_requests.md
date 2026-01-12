# ログイン後に Backend/Emulator へ通信が発生しない

## 背景 / 事象
- ログインは成功しているように見えるが、Backend や Firebase Emulator にリクエストが飛んでいるログが確認できない
- ローカル統合確認のため、ログイン後に明示的な疎通が必要

## 目的
- ログイン後に Backend と Firestore Emulator への通信を実行し、ログで確認できる状態にする

## 方針
- Home 画面で Backend 健康チェックと Firestore 書き込みを行い、結果を画面に表示する
- iOS でも HTTP ローカルアクセスできるよう ATS 例外を追加する

## 要件
1. Home 画面で Backend `/health` にリクエストを送信すること
2. Home 画面で Firestore Emulator に書き込みを行うこと
3. 結果が画面に表示され、再試行できること
4. iOS で `http://localhost` にアクセスできるよう ATS 例外が設定されていること

## テスト
- `make flutter-run` で起動し、ログイン後に Backend/Firestore Emulator のログにリクエストが出ることを確認する
