# docker compose で Backend + Firebase Emulator + Tasks スタブを起動

## 背景 / 事象
- ローカル開発を docker compose で完結させ、Backend・Firestore/Auth Emulator・Cloud Tasks スタブをまとめて起動したい
- Compose のネットワークとポートを先に固めないと、以降の設定（バックエンド環境変数や Flutter 接続先）が決められない

## 目的
- ローカルで docker compose を実行し、Backend/Firestore Emulator/Auth Emulator/Tasks スタブが同一ネットワークで起動する状態を作る

## 方針
- Backend はダミーのヘルスチェックだけでよい。後続タスクで本処理を追加する
- Tasks スタブは HTTP ターゲットを模倣する薄い API だけ用意する

## 要件
1. `infrastructure/docker-compose.yml` で Backend/Firestore Emulator/Auth Emulator/Tasks スタブを定義し、同一ネットワークで起動できる
2. Backend のヘルスチェックエンドポイントが 200 を返す
3. 各サービスのポートとホスト名が固定され、後続タスクで参照できる

## テスト
- `docker compose up backend` で全コンテナが起動し、Backend のヘルスチェックが 200 を返す
