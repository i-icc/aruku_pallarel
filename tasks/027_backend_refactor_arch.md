# Backend 構造整理と ADC 設定

## 背景 / 事象
- `app.py` に API/インフラの処理が集中しており見通しが悪い
- ローカルでエミュレーターにアクセスする際、ADC 不足で 500 が発生する

## 目的
- なんちゃってクリーンアーキテクチャ/DDD で責務を分離する
- Docker Compose で ADC を渡せるようにする

## 方針
- `api/` `usecases/` `domain/` `infrastructure/` に分割
- Firestore/Tasks 連携は `infrastructure/` に集約する
- `GOOGLE_APPLICATION_CREDENTIALS` を env と volume で渡す

## 要件
1. 既存 API の挙動・レスポンスが変わらない
2. `docker-compose.yml` で ADC を渡せる
3. `README.md` と `.env.example` を更新する

## テスト
- `PYTHONPATH=. uv run pytest`
- `infrastructure/scripts/enqueue_test_task.sh` で dispatch ログ確認
