# Backend CI の setup-uv 警告を解消する

## 背景 / 事象
- `backend-tests` workflow で `setup-uv` に未対応の入力があり警告が出る

## 目的
- CI 実行時の警告を解消し、設定を正しくする

## 方針
- `setup-uv` の入力を正しいキーに置き換える

## 要件
1. CI 実行時に `Unexpected input(s)` の警告が出ない

## テスト
- PR で `backend-tests` が警告なしで実行されることを確認する
