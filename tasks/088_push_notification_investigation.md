# プッシュ通知が届かない問題の調査/切り分け

## 背景 / 事象
- 散歩中の提案通知が iOS に届かない
- クライアント送信 / ジョブ実行 / FCM 配信のどこがボトルネックか未特定

## ゴール
- 通知が届かない原因を特定し、解消する
- 送信パスのどこで失敗しているかログで追える状態にする

## ToDo
- [ ] クライアントの suggestion_request が送信されているかログで確認する
- [ ] Cloud Tasks の enqueue / dispatch / retry 状態を確認する
- [ ] Job の実行ログでメッセージ生成と FCM 送信結果を確認する
- [ ] Firestore の FCM トークン保存・更新が正しいか確認する
- [ ] iOS の通知許可 / APNs キー設定 / Firebase 設定を確認する
- [ ] 必要なら FCM 送信ログ（requestId/response）を詳細化する
- [ ] Firebase Console からテスト送信で到達確認を行う
- [ ] Backend エラー `TASKS_STUB_URL is not set` の原因を確認し、必要なら本番用の URL/ENV を設定する

## 受け入れ条件
- クライアント→Backend→Job→FCM の流れがログで追える
- 実機で通知が到達する
