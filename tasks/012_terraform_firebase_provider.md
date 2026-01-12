# Terraform で Firebase プロジェクト作成が失敗する

## 背景 / 事象
- `terraform plan` 実行時に `google_firebase_project` が未対応というエラーになる
- google provider ではなく google-beta provider を使う必要がある

## 目的
- Firebase プロジェクト作成が `terraform plan` でエラーにならない状態にする

## 方針
- `google_firebase_project` を google-beta provider で実行する

## 要件
1. `google_firebase_project` に `provider = google-beta` が指定されている
2. `terraform plan` で provider 未対応エラーが出ない

## テスト
- `terraform plan` を実行してエラーが出ないことを確認する
