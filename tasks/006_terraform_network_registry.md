# VPC / Subnet / Artifact Registry を Terraform で作成（Direct VPC Egress）

## 背景 / 事象
- Direct VPC Egress の network interface で VPC/サブネットを参照するため、VPC とサブネットが必要
- Serverless VPC Connector / Cloud NAT は使わない方針
- コンテナ配信用の Artifact Registry も先に作成しておく

## 目的
- VPC/サブネットと Artifact Registry を Terraform で定義し、Cloud Run/Job が Direct VPC Egress を使える基盤を整える

## 方針
- 005 のブートストラップを前提にネットワークをコード化する
- リージョンは 005 で決めた値を使用する

## 要件
1. VPC とサブネットを作成し、リージョン/アドレスレンジを明示する
2. サブネットは Direct VPC Egress の network interface で参照できる状態にする
3. Artifact Registry リポジトリを作成し、Backend/ADK/OSM/Job 用のリポジトリ名を決定する
4. `terraform plan` で差分が出ない状態にする

## テスト
- `terraform apply` 後に VPC/サブネットと Artifact Registry が作成されていることを GCP コンソールまたは `gcloud` で確認
