# Backend を uv で起動できるようにする

## 背景 / 事象
- Python の実行環境が pip ベースのみで、ローカル開発の統一ができていない
- uv を使って依存管理と実行を揃えたい

## 目的
- Backend を uv で起動できる状態にする

## 方針
- `pyproject.toml` を追加し、`uv run` で実行できるようにする
- README/AGENTS に実行方法を記載する

## 要件
1. `src/backend/pyproject.toml` が存在する
2. `uv run` で Backend を起動できる手順が README/AGENTS にある

## テスト
- `cd src/backend && uv run -- python main-backend-server/app.py` が起動できることを確認する
