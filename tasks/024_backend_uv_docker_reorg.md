# Backend/ADK を uv + Docker 前提で再整備

## 背景 / 事象
- uv を使うが、起動/管理/開発は Docker を基本としたい
- `pyproject.toml` と README をサーバー単位で独立管理したい

## 目的
- Backend/ADK をそれぞれ独立した uv プロジェクトとして整理し、Docker で起動できる状態にする

## 方針
- `main-backend-server` と `sanpo-agent` に `pyproject.toml` と `README.md` を配置する
- Dockerfile を各ディレクトリに配置し、uv で依存を解決する
- `docker-compose.yml` の参照先を更新する

## 要件
1. `src/backend/main-backend-server` に `pyproject.toml`/`README.md`/`Dockerfile` がある
2. `src/backend/sanpo-agent` に `pyproject.toml`/`README.md`/`Dockerfile` がある
3. Docker Compose から Backend が起動できる

## テスト
- `docker compose -f infrastructure/docker-compose.yml up -d` で Backend が起動し、`/health` に応答する
