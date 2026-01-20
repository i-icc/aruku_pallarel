# Main Backend Server

## Local Run (uv)
```bash
cd src/backend/main-backend-server
uv sync
uv run -- python app.py
```

## Emulator Credentials (ADC)
Firestore/Auth エミュレーターでも ADC が必要です。

1. `gcloud auth application-default login` を実行
2. `GOOGLE_CLOUD_PROJECT=demo-project` を `.env.local` に設定（警告回避）
3. `.env.local` に `GOOGLE_APPLICATION_CREDENTIALS=/app/.config/gcloud/application_default_credentials.json` を設定
4. `docker compose` 実行時に `${HOME}/.config/gcloud` が `/app/.config/gcloud` にマウントされる想定

## Docker Run (compose)
```bash
docker compose -f infrastructure/docker-compose.yml up -d backend
```
