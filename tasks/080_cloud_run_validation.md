# Cloud Run / Cloud Tasks / OSRM デプロイ動作確認

## 背景 / 事象
- Cloud Run の backend/adk/osm/suggestion-job と Cloud Tasks を反映済み
- 正しくデプロイできているかを CLI/curl とコンソールで確認したい
- ADK/OSM は認証が必要なため、トークン付きの確認手順が必要

## 目的
- 各サービスのイメージ・環境変数・疎通を確認する
- Cloud Tasks から suggestion-job が呼び出せる前提を確認する

## ToDo
- [ ] `terraform output` で `backend_url`/`adk_url`/`osm_url` を取得する
- [ ] Cloud Run コンソールで各サービスの Revision と image/tag を確認する
- [ ] backend の `/health` と `/` を curl で確認する
- [ ] adk の `/health` を ID トークン付きで確認する
- [ ] osm の `/nearest/v1/driving/{lon},{lat}?number=1` を ID トークン付きで確認する
- [ ] suggestion-job の `/jobs/suggestions` に ID トークン付きで `requestId` 未指定の 400 が返ることを確認する
- [ ] Cloud Run の環境変数で `ADK_BASE_URL`/`OSM_BASE_URL`/`TASKS_TARGET_URL`/`TASKS_QUEUE` が期待通りになっているか確認する
- [ ] Cloud Tasks キュー `suggest-jobs` が作成済みであることを確認する
- [ ] curl だけで判断しづらい場合は Cloud Logging で各サービスの受信ログを確認する

## コンソール確認手順
1. Cloud Run > backend/adk/osm/suggestion-job を開き、Revisions の image/tag を確認
2. Cloud Run > backend/suggestion-job の `Variables & secrets` で env を確認
3. Cloud Tasks > キュー `suggest-jobs` を開き、キューが存在することを確認
4. Cloud Logging で `cloud_run_revision` のログを確認（/health と /nearest のアクセスが記録されること）

## テスト
```bash
BACKEND_URL="$(terraform -chdir=infrastructure/terraform output -raw backend_url)"
ADK_URL="$(terraform -chdir=infrastructure/terraform output -raw adk_url)"
OSM_URL="$(terraform -chdir=infrastructure/terraform output -raw osm_url)"
REGION="us-central1"
SUGGEST_JOB_URL="$(gcloud run services describe suggestion-job --region "$REGION" --format='value(status.url)')"

curl -sS "$BACKEND_URL/health"
curl -sS "$BACKEND_URL/"

ADK_TOKEN="$(gcloud auth print-identity-token --audiences="$ADK_URL")"
curl -sS -H "Authorization: Bearer $ADK_TOKEN" "$ADK_URL/health"

OSM_TOKEN="$(gcloud auth print-identity-token --audiences="$OSM_URL")"
curl -sS -H "Authorization: Bearer $OSM_TOKEN" \
  "$OSM_URL/nearest/v1/driving/139.767125,35.681236?number=1"

SUGGEST_TOKEN="$(gcloud auth print-identity-token --audiences="$SUGGEST_JOB_URL")"
curl -sS -H "Authorization: Bearer $SUGGEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$SUGGEST_JOB_URL/jobs/suggestions"
```

## 受け入れ条件
- backend/adk/osm/suggestion-job の image が期待通りである
- `/health` と `/nearest` が 200 で応答する
- suggestion-job に 400 が返り、到達できることが確認できる
- Cloud Tasks キューが存在し、backend の env で `TASKS_TARGET_URL` が suggestion-job を指している
