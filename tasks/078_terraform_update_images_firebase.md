# Terraform の Cloud Run/Firebase 設定見直し

## 背景 / 事象
- GAR へのイメージ push は完了したが、Terraform はダミーイメージのままになっている
- Cloud Run Job/Backend に必要な環境変数（`PROJECT_ID`/`ENABLE_JOB_ENDPOINTS`/ADK・OSM 連携）が Terraform 側に反映されていない
- Firebase/FCM 周りの API 有効化や IAM が現状の実装に合っているか再確認が必要
- `terraform.tfvars.example` に本番向けのイメージ指定や ADK 設定が不足している

## 目的
- Terraform 定義を現在の運用（GAR イメージ / Firebase / Cloud Run 設定）に揃え、apply だけで本番稼働に必要な設定が揃う状態にする

## 方針
- GAR の最新タグ（`REGION-docker.pkg.dev/PROJECT/REPO/<image>:latest`）を Cloud Run に反映する
- Backend/Job は同一イメージにし、Job では `ENABLE_JOB_ENDPOINTS=true` を明示する
- ADK/OSM の URL/APP 名など実行に必要な env を Terraform で設定する
- Firebase/FCM の API/IAM を再確認し、不足があれば Terraform に追加する
- 変数追加時は `terraform.tfvars.example` を更新する

## 要件
1. Cloud Run (backend/job/adk/osm) が GAR の実イメージを参照し、ダミーイメージが残っていない
2. Backend/Job が同一イメージを参照し、Job で `ENABLE_JOB_ENDPOINTS=true` が設定されている
3. Backend/Job に `PROJECT_ID` と ADK/OSM 連携用 env（`ADK_BASE_URL`/`ADK_APP_NAME`/`OSM_BASE_URL` など）が設定されている
4. Firebase/FCM に必要な API 有効化/IAM が Terraform に反映されている
5. 追加した変数が `infrastructure/terraform/terraform.tfvars.example` に追記されている
6. `terraform plan` の差分が意図通りで、apply 後に Cloud Run が起動できる状態になっている

## テスト
- `terraform plan` でイメージ/環境変数/サービス有効化の差分が確認できる
- `terraform apply` 後に Cloud Run の revision に反映されていることを確認する
