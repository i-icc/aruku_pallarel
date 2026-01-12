# syntax=docker/dockerfile:1

FROM ghcr.io/astral-sh/uv:python3.12-bookworm

WORKDIR /app

ENV UV_PROJECT_ENVIRONMENT=/app/.venv \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1

COPY . .

RUN uv sync --no-dev --no-install-project

ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "uv run -- python app.py"]
