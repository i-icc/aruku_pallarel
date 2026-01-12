# Flutter analyze の CI を差分があるときだけ実行する

## 背景
- PR で Flutter 変更がない場合も `flutter analyze` が走る

## 目的
- Flutter 関連の変更があるときだけ CI を実行し、無駄なジョブを減らす

## 方針
- GitHub Actions の `pull_request` に `paths` フィルタを設定する
- 対象は `src/frontend/aruku_pallarel/**` と該当ワークフロー自身の変更とする

## 要件
1. Flutter 関連の変更がある PR でのみ `Flutter Analyze` が走る
2. ワークフロー変更時は常に `Flutter Analyze` が走る

## テスト
- Flutter 以外の変更 PR ではジョブが走らないことを確認する
- Flutter 配下の変更 PR でジョブが走ることを確認する
