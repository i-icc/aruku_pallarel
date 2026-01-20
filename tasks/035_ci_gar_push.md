# main マージ後の GAR Push CI

## 背景 / 事象
- main マージ後に Cloud Run 用イメージが自動で GAR に上がらない
- デプロイ前に最新イメージを揃える手順が手作業になっている

## 目的
- main への push をトリガーに Docker イメージをビルドして GAR へ push する

## 方針
- GitHub Actions の OIDC で Google Cloud に認証する
- buildx を使って複数イメージをビルドする
- タグは `sha-<short>` と `latest` を付与する

## 要件
1. `.github/workflows/` に新規 workflow を追加する
2. `push` の `main` ブランチをトリガにする
3. 対象イメージは `backend` と `sanpo-agent` を最低限含める
4. GAR の `project`/`region`/`repository` は secrets/env から取得する
5. `REGION-docker.pkg.dev/PROJECT/REPO/<image>:<tag>` 形式で push する
6. 失敗時に原因が追えるログを残す

## テスト
- workflow の `workflow_dispatch` で dry-run し、ログで push 成否を確認する
