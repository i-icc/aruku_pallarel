# GAR Push CI のジョブ分割と latest タグ運用

## 背景 / 事象
- GAR Push が backend/sanpo-agent を毎回まとめてビルドしている
- 対象フォルダに差分がない場合もビルドが走る
- sha タグは不要で `latest` のみで運用したい

## 目的
- 変更があるイメージだけをビルド・push し、タグを `latest` に統一する

## 方針
- `paths-filter` で backend / sanpo-agent の変更を検出する
- 2 ジョブに分割し、該当変更時のみ実行する
- タグは `latest` のみにする

## 要件
1. GAR Push workflow を変更検知で分岐させる
2. backend/sanpo-agent を独立ジョブで build/push する
3. イメージタグは `latest` のみを push する
4. `workflow_dispatch` でも実行できるようにする

## テスト
- backend のみ変更した push で backend job のみ走る
- sanpo-agent のみ変更した push で sanpo-agent job のみ走る
