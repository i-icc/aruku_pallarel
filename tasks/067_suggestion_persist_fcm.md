# 提案保存と FCM 通知

## 背景 / 事象
- 生成した提案を Firestore に保存し、通知する処理が未実装

## 目的
- Job が chat → suggests 保存、request 完了、FCM 通知まで行えるようにする

## 方針
- Google Maps URL は DMS 形式で組み立てる
- chat を先に作成し、その `messageId` を suggests に紐付ける
- `requests` に `suggestId` / `messageId` を保存して完了状態にする
- FCM 失敗時はログのみ残し、データは保持する

## 要件
1. chat を作成して `messageId` を取得する
2. suggests を作成し chat と紐付ける
3. `requests.status=done` を更新し `suggestId` / `messageId` を記録する
4. FCM payload に `message` / `walkId` / `suggestId` / `messageId` / `lat` / `lon` を含める
5. FCM 送信失敗でもデータが残る

## テスト
- Firestore Emulator で chat/suggests/requests の書き込み順を確認する
- FCM クライアントのモックで payload 内容を確認する
