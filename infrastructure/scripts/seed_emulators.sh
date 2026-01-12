#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-demo-project}"
AUTH_HOST="${AUTH_HOST:-localhost:9099}"
FIRESTORE_HOST="${FIRESTORE_HOST:-localhost:8080}"

EMAIL="${TEST_USER_EMAIL:-test@example.com}"
PASSWORD="${TEST_USER_PASSWORD:-password123}"

echo "Seeding Auth emulator user..."
curl -sS -X POST "http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"returnSecureToken\":true}" \
  >/dev/null

echo "Seeding Firestore emulator data..."
curl -sS -X POST "http://${FIRESTORE_HOST}/v1/projects/${PROJECT_ID}/databases/(default)/documents/walks?documentId=seed" \
  -H "Content-Type: application/json" \
  -d '{"fields":{"status":{"stringValue":"seed"},"createdAt":{"timestampValue":"2026-01-10T00:00:00Z"}}}' \
  >/dev/null

echo "Done."
