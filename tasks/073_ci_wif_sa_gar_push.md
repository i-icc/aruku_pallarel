# GAR Push CI 用 Workload Identity Provider / SA 作成

## 背景 / 事象
- 035 の GAR Push CI は GitHub Actions の OIDC 認証を前提としている
- 現状 Terraform に WIF プール/プロバイダと CI 用サービスアカウントが定義されていない

## 目的
- GitHub Actions から OIDC で認証し、GAR に push できる土台を用意する

## 方針
- `infrastructure/terraform/` に WIF プール/プロバイダと SA を追加する
- `attribute_condition` で対象リポジトリ/ブランチを限定する
- GAR は既存の `artifact_registry_repo` を利用する

## 要件
1. Workload Identity Pool と Provider を作成する
2. GitHub Actions 用 SA を作成し、`roles/artifactregistry.writer` を付与する
3. Provider principal に `roles/iam.workloadIdentityUser` を付与する
4. WIF Provider 名と SA email を `terraform output` で参照できるようにする
5. 新規変数があれば `terraform.tfvars.example` に追記する

## テスト
- `terraform apply` 後に WIF/SA が作成されていることを確認する
- `google-github-actions/auth` の dry-run で `gcloud auth list` が通ることを確認する
