# Cloud Tasks から Cloud Run Job を直接起動する

## 背景 / 事象
- suggestion-job は Cloud Run Service 経由で実行している
- Cloud Run Job を直接起動する構成にしたい
- Service と Job が併存しており、運用が分かりにくい
- 現在は問題なく起動できているため、デグレコストなどを考え優先事項はかなり低い

## ゴール
- Cloud Tasks から Cloud Run Job を直接起動できる
- suggestion-job service を不要にできる
- ジョブ実行ログで追跡できる

## ToDo
- [ ] Cloud Tasks から Run Jobs API を叩く方式に切り替える
- [ ] Terraform で Cloud Tasks HTTP target を Run Jobs API に変更する
- [ ] IAM を整理（run.jobs.run / iam.serviceAccountUser など）
- [ ] job 起動用の env/vars を追加する（project/region/job name）
- [ ] 既存の service 経由パスを段階的に削除/無効化する
- [ ] Cloud Tasks -> Job 起動の疎通確認を行う

## 受け入れ条件
- Cloud Tasks から Job の run が成功する
- suggestion-job service を使わずに同等の機能が動く
