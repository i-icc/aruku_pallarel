# PR 作成時に Flutter analyze を実行する CI を追加

## 背景
- PR で静的解析が走らず品質ゲートがない

## 目的
- PR 作成時に `fvm flutter analyze` を CI で実行し、早期に問題を検知する

## 方針
- GitHub Actions で Dart/FVM をセットアップし、`src/frontend/aruku_pallarel` で解析を実行する

## 要件
1. PR 作成時に `flutter analyze` が走る
2. コマンドは `fvm` 経由で実行する
3. `src/frontend/aruku_pallarel` を対象にする

## テスト
- PR 作成時に GitHub Actions の `Flutter Analyze` が成功することを確認する
