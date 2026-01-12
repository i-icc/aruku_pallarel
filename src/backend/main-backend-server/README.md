# Main Backend Server

## Local Run (uv)
```bash
cd src/backend/main-backend-server
uv sync
uv run -- python app.py
```

## Docker Run (compose)
```bash
docker compose -f infrastructure/docker-compose.yml up -d backend
```
