# Firebase Auth の Email/Password 有効化とログイン状態整理

## 背景 / 事象
- ログアウト後に `The given sign-in provider is disabled...` が表示される
- 初回起動時にログイン画面が出ず、ログイン済み画面に遷移する
  - FirebaseAuth は Keychain にセッションを保持するため、以前のログインが残っている可能性がある

## 目的
- Email/Password ログインが有効であること
- ログイン状態の挙動を仕様として整理し、迷わない導線にする

## ToDo
- [ ] Terraform で Email/Password を有効化する（`google_identity_platform_config`）
- [ ] 既存設定がある場合は `terraform import google_identity_platform_config.default projects/<project>/config` を実行する
- [ ] ログイン状態の期待挙動を決める（自動ログイン維持/毎回ログイン画面）
- [ ] 自動ログインを維持する場合、サインアウト導線/テスト方法を README に追記する
- [ ] ログアウト後にログイン画面へ戻ることを確認する
- [ ] 必要ならデバッグ用のセッションリセット導線を用意する

## 受け入れ条件
- Email/Password でログイン/再ログインができる
- 期待するログイン状態の挙動が明文化されている
- ログアウト後にログイン画面へ戻れる
