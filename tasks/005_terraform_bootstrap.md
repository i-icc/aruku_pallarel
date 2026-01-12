# Terraform ブートストラップ (GCP プロジェクト手動作成後)

## 背景 / 事象
- GCP プロジェクトは手動作成するため、Terraform で管理するための backend 設定と必要 API 有効化を整備する必要がある
- tfstate をリモート管理し、後続のネットワーク/Run 定義の土台を作る

## 目的
- `terraform init`/`validate` が通り、tfstate の保管先とプロバイダー設定が整った状態を作る

## 方針
- tfstate は GCS バケットでバージョニング付き管理
- 必要 API は Terraform で有効化しておく

## 要件
1. 手動で作成した `PROJECT_ID` とリージョンを決定・記録する
2. tfstate 用 GCS バケットを作成し、`backend.tf` で参照する
3. `providers.tf` に google/google-beta を設定し、project/region を指定する
4. `variables.tf` に `project_id`/`region`/`tfstate_bucket` などを定義する
5. 必要 API (Run, Cloud Tasks, Artifact Registry, Firestore, Vertex, Serverless VPC Access, IAM) を有効化する
6. `terraform fmt` / `terraform validate` が成功する

## テスト
- `terraform init`/`terraform validate` が成功する
- `terraform plan` で API 有効化以外のリソース差分がないことを確認する
