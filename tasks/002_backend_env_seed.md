# Backend 環境変数とエミュレーター初期化（ローカル完結）

## 背景 / 事象
- Compose のポートを基に Backend の環境変数を整理し、エミュレーター接続情報を `.env.example`/`.env.local` に明示する必要がある
- Firestore/Auth Emulator に最小限の初期データとテストユーザーを投入しておくと、後続のログイン確認が簡単になる

## 目的
- Backend のローカル設定を確定し、エミュレーター初期化スクリプトを用意する

## 方針
- `.env.example` に必須キーとデフォルト値を記載し、`.env.local` をコピーして使う運用
- エミュレーター初期化スクリプトを `infrastructure/scripts/` などに配置し、Compose 起動後に一発で流せるようにする

## 要件
1. Backend 用 `.env.example` と `.env.local` を作成し、Firestore/Auth Emulator、Tasks スタブの URL/ポートを記載する
2. Firestore/Auth Emulator を初期化するスクリプト（例: コレクション雛形、Auth のテストユーザー作成）が存在する
3. 初期化スクリプトを実行後、Backend のヘルスチェックが引き続き成功する

## テスト
- Compose 起動後に初期化スクリプトを実行し、Auth Emulator にテストユーザーが存在すること、Firestore に指定のコレクションが作成されることを確認
