# Terraform の OSRM カスタムイメージ（東京データ）反映

## 背景 / 事象
- backend/sanpo-agent のイメージは準備済みだが、OSM サービスは OSRM を使いたい
- OSRM は地図データを内包しないため、東京データ入りのカスタムイメージが必要
- Terraform の `osm_image` はダミーのままで、本番用の指定が未整理
- OSRM 公式イメージは GHCR (`ghcr.io/project-osrm/osrm-backend`) が正で、Docker Hub は旧版のみ

## 目的
- 東京データを内包した OSRM イメージを用意し、Cloud Run から参照できるようにする

## 方針
- 東京データは BBBike の Tokyo extract を使う（Make で再現）
- データは `tmp/osrm` 配下に置き、git 管理しない
- OSRM 公式イメージ（GHCR）をベースにカスタムイメージを作る
- Cloud Run は `linux/amd64` を想定するため、OSRM イメージは amd64 でビルドする
- カスタムイメージは GAR に push し、Terraform の `osm_image` で参照する
- Cloud Run で `PORT` を使って 8080 で起動できる entrypoint を用意する

## 要件
1. `tmp/osrm` に東京データを再現できる Make タスクがある（download/extract/partition/customize）
2. OSRM 公式イメージをベースにしたカスタム Dockerfile がある
3. GAR へ push する手順が定義されている（Terraform でなく Make で可）
4. `infrastructure/terraform/terraform.tfvars.example` に `osm_image` の例が追加されている
5. Cloud Run が 8080 で起動できるよう entrypoint/command が設定されている
6. OSRM イメージが `linux/amd64` でビルドされている
7. `terraform plan` で OSM サービスの差分が確認できる

## テスト
- `make osrm-download` / `make osrm-build` / `make osrm-image` が成功する
- `terraform plan` で OSM イメージ差し替えが確認できる
