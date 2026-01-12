# Backend テストを GitHub Actions で実行する

## 背景 / 事象
- Backend の変更に対する自動テストがなく、回帰を検知しにくい
- `main-backend-server` 配下の差分時に pytest を回したい

## 目的
- PR 時に Backend テストが自動実行される状態にする

## 方針
- `src/backend/main-backend-server/**` に差分がある場合のみ workflow を実行する
- `uv sync` + `pytest` を実行する

## 要件
1. `main-backend-server` の差分で workflow が起動する
2. `uv sync --group dev --no-install-project` が実行される
3. `pytest` が実行される

## テスト
- PR 作成時に CI が実行されることを確認する
