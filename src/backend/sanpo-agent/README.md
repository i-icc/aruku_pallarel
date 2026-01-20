# Sanpo Agent (ADK)

## Local Run (Docker Compose)
```bash
docker compose -f infrastructure/docker-compose.yml up -d sanpo-agent
```

## Agent Config
- `sanpo_agent/agent.py` is the entry-point agent definition.

## Environment
- `src/backend/sanpo-agent/.env.local` に `GOOGLE_API_KEY` を設定する
- ローカルは Vertex AI を使わない（`GOOGLE_GENAI_USE_VERTEXAI=false`）
