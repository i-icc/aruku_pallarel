# Backend/ADK サーバーの配置見直し

## 背景 / 事象
- Backend の実装が `src/backend/app.py` 直下にあり、今後の分離運用がしづらい
- `main-backend-server` と `sanpo-agent` に分けて実装したい

## 目的
- Backend を `src/backend/main-backend-server` に移動する
- ADK サーバーのベースを `src/backend/sanpo-agent` に用意する

## 方針
- Backend の既存実装を移設し、Dockerfile の参照先を更新する
- ADK は最小の Flask サーバーで stub を作成する

## 要件
1. Backend 実装が `src/backend/main-backend-server/app.py` にある
2. ADK stub が `src/backend/sanpo-agent/app.py` にある
3. Dockerfile が新しい配置を参照する

## テスト
- `docker compose -f infrastructure/docker-compose.yml up` で Backend が起動できることを確認する
