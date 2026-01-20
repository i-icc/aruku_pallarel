# Backend のホットリロード対応（Docker Compose）

## 背景 / 事象
- Backend のコード変更を反映するたびにコンテナ再起動が必要

## 目的
- Docker Compose でホットリロードを使えるようにする

## 方針
- `infrastructure/docker-compose.yml` でコードを bind mount
- Flask debug reloader で自動再起動する
- venv はコンテナ内の `/opt/venv` に固定して、mount の影響を受けないようにする

## 要件
1. Backend コンテナでコード変更が自動反映される
2. Suggestion Job も同様にホットリロードする
3. 既存の起動コマンドは Docker Compose を継続使用する

## テスト
- `docker compose -f infrastructure/docker-compose.yml up -d --build backend`
- `docker compose -f infrastructure/docker-compose.yml logs -f backend`
- `app.py` を編集して reload が走ることを確認する
