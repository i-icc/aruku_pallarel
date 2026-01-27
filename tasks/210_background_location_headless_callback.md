# バックグラウンド位置同期方針の更新（iOS）

## 背景
- 既存のヘッドレス API 名が現行 Locus と不一致
- ヘッドレスで Firestore 直書きは不安定になりやすい
- 対応プラットフォームは iOS のみを前提にする

## ゴール
- Locus の正しいヘッドレス同期 API に合わせた方針へ更新する
- バックグラウンド同期は Locus HTTP 同期 → Backend → Firestore とする
- 仕様・ルールに iOS 前提を明記する

## 対応内容
- `spec/system.md` にバックグラウンド同期フローを追記
- `spec/api.md` に `/v1/locations:sync` を追加
- `spec/flutter.md` にヘッドレス同期の方針を記載
- `spec/overview.md` に iOS 前提を明記
- `AGENTS.md` に iOS 前提を明記

## 受け入れ条件
- ヘッドレス同期の API 名と責務が仕様に記載されている
- iOS のみ前提であることが仕様・ルールに明記されている

## 次のステップ
- Flutter 側の Locus 設定を HTTP 同期前提で更新
- Backend に `/v1/locations:sync` 実装を追加
