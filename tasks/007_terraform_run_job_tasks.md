# Cloud Run (Backend/ADK/OSM) / Cloud Run Job / Cloud Tasks を Terraform で定義

## 背景 / 事象
- アプリ本番構成では Cloud Tasks 経由で Cloud Run Job を起動し、各 Run は Direct VPC Egress を利用する
- 2 つの内部サービス（ADK/OSM）は公開せず、IAM 認証でアクセス制御する
- サービスアカウント/IAM を整備し、必要な外部サービス（Firestore/FCM/Vertex 等）への到達を担保する必要がある

## 目的
- Cloud Run サービスと Job、Cloud Tasks キュー、実行サービスアカウントを Terraform で定義し、Direct VPC Egress（private ranges only）を有効にした状態を作る

## 方針
- 006 で作成した VPC/サブネットを network interface として参照する
- Direct VPC Egress は `PRIVATE_RANGES_ONLY` を基本とする（NAT は不要）
- 内部サービスは `no-allow-unauthenticated` + `roles/run.invoker` で制御する
- コンテナはダミーイメージで構わないが Artifact Registry を参照する形にする

## 要件
1. Cloud Run サービス (Backend/ADK/OSM) を定義し、Direct VPC Egress（network interface + PRIVATE_RANGES_ONLY）を有効にする
2. Backend は `allow-unauthenticated`、ADK/OSM は `no-allow-unauthenticated` とする
3. Cloud Run Job を定義し、Direct VPC Egress を有効にする
4. Cloud Tasks キューを定義し、HTTP ターゲットで Job を起動できる設定にする
5. 実行サービスアカウントを作成し、Run Invoker/Tasks Enqueuer/Firestore/FCM/Vertex/Logging 等の IAM を付与する
6. ADK/OSM への `roles/run.invoker` を Backend/Job の SA に付与する
7. `terraform plan` で差分が出ない状態にする

## テスト
- `terraform apply` 後に Run/Job/Tasks が作成されていることを GCP コンソールまたは `gcloud` で確認
