# Terraform で Firestore ルール/インデックス管理へ移行

## 背景 / 事象
- Firestore ルール/インデックスの反映が Firebase CLI 前提になっている
- 本番環境の設定は Terraform で統一したい

## 目的
- Firestore ルール/インデックスを Terraform 管理に切り替える
- `infrastructure/firebase` のファイルを Terraform のソースとして使う

## 方針
- `google_firebaserules_ruleset` / `google_firebaserules_release` でルールを管理する
- `google_firestore_index` で複合インデックスを管理する
- 既存の release/index は import して state に取り込む
- Firebaserules API を有効化する

## 要件
- `infrastructure/firebase/firestore.rules` が Terraform の ruleset に反映される
- `infrastructure/firebase/firestore.indexes.json` の複合インデックスが Terraform 管理になる
- 既存リソースの import 手順が明確で、`terraform plan` が差分なしになる

## テスト
- `terraform plan` が差分なしになる
