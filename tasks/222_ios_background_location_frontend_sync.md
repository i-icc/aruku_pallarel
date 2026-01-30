# iOSバックグラウンド位置更新のフロント同期対応

## 背景
- iOS バックグラウンド時の位置更新は Locus の同期で Backend に送る必要がある
- Backend の `locations:ingest` とは別タスクで対応する

## ゴール
- iOS バックグラウンド時に Locus の HTTP sync を有効化できる
- 位置更新が `locations:ingest` に送信される

## ToDo
- [ ] Locus の HTTP sync 設定（url/headers/extras/autoSync）を追加する
- [ ] `locations:ingest` に送るリクエストの形を決める（単発/配列）
- [ ] 送信 payload を実装する（`location` or `locations`）
- [ ] `Authorization: Bearer <token>` を付与する
- [ ] トークン更新時にヘッダーを更新できるようにする
- [ ] walkId を extras で渡す or URL パスに組み込む
- [ ] Locus の sync pause/resume を初期化後に呼ぶ
- [ ] iOS のバックグラウンド復帰時の同期を確認する

## リクエスト仕様（案）
### 単発
```json
{
  "location": {
    "timestamp": "2025-01-03T09:20:00Z",
    "coords": {
      "latitude": 35.0,
      "longitude": 139.0,
      "accuracy": 12.3
    }
  }
}
```

### バッチ
```json
{
  "locations": [
    {
      "timestamp": "2025-01-03T09:20:00Z",
      "coords": { "latitude": 35.0, "longitude": 139.0 }
    }
  ]
}
```

## 受け入れ条件
- バックグラウンドで取得した位置が Backend に届く
- 送信先が `POST /v1/walks/{walkId}/locations:ingest` になっている
