# ローカルでメール/パスワードのアカウント登録ができない

## 背景 / 事象
- ログインは可能だが、アカウント登録の導線がなく新規ユーザー作成ができない
- エミュレーター環境でも登録フローを確認できるようにしたい

## 目的
- ローカル環境でメール/パスワードのアカウント登録ができる UI を用意する

## 方針
- Login 画面に「Sign Up」ボタンを追加し、Firebase Auth Emulator に対して `createUserWithEmailAndPassword` を実行する
- 既存のログイン UI/実装は維持し、登録成功時は AuthGate によって Home へ遷移する

## 要件
1. Login 画面に Sign Up ボタンが表示される
2. Sign Up 実行時に Firebase Auth Emulator へアカウント登録が行われる
3. 失敗時はエラーメッセージが表示される
4. `flutter analyze` が通る

## テスト
- `make flutter-run` で起動し、Sign Up で新規ユーザーを作成できることを確認する
