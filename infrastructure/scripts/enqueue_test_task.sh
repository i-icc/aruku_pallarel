#!/usr/bin/env bash
set -euo pipefail

TASKS_HOST="${TASKS_HOST:-localhost:7070}"
TARGET_URL="${TARGET_URL:-http://backend:8080/internal/task-handler}"

curl -sS -X POST "http://${TASKS_HOST}/tasks" \
  -H "Content-Type: application/json" \
  -d "{\"target_url\":\"${TARGET_URL}\",\"payload\":{\"message\":\"hello\"}}"
echo
