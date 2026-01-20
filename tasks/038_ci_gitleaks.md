# Gitleaks チェックの GitHub Actions を追加

## 背景
誤ってシークレットがコミットされる事故を防ぐため、CI で検知できるようにする。

## ゴール
- PR と main push で Gitleaks が実行される
- 既存の CI と独立して動作する

## ToDo
- [ ] Gitleaks の GitHub Actions ワークフローを追加
- [ ] `tasks/PROGRESS.md` を更新
- [ ] ワークフロー変更に伴い `AGENTS.md` を更新

## 受け入れ条件
- PR で Gitleaks が実行され、漏洩検知時に失敗する
- `tasks/PROGRESS.md` にタスクが記載されている
- リポジトリルートに不要なキャッシュ/成果物が無い
