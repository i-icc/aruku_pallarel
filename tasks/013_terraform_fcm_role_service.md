# Terraform apply が Firebase Messaging で失敗する

## 背景 / 事象
- `roles/firebase.messaging` が存在せず、IAM 付与でエラーになる
- `firebasecloudmessaging.googleapis.com` が有効化できず apply が失敗する

## 目的
- IAM/サービス有効化のエラーを解消し、`terraform apply` を完走できるようにする

## 方針
- FCM 向け IAM は `roles/firebase.growthAdmin` に置き換える
- 未対応の `firebasecloudmessaging.googleapis.com` を required services から除外する

## 要件
1. `roles/firebase.messaging` が Terraform から削除されている
2. `roles/firebase.growthAdmin` が Backend/Job に付与されている
3. `firebasecloudmessaging.googleapis.com` が required services から削除されている
4. `terraform apply` が失敗せず完走する

## テスト
- `terraform plan` と `terraform apply` が成功することを確認する
