# API設計（Cloud Run）

## 共通
- **フレームワーク**: Flask（Python）
- Base URL: `/v1`
- 認証: Firebase ID Token（`Authorization: Bearer <token>`）
- Content-Type: `application/json`
- 失敗時は `{ "error": { "code": "...", "message": "..." } }` を返す

> 位置情報の書き込みや履歴の読み取りはクライアントから Firestore へ直接行う（MVP）。

---

## User

### POST /v1/users
ユーザー登録（Firebase Auth 経由で作成後、サーバーにプロフィール情報を保存）。

#### Request
```json
{
  "nickname": "まちだん太郎"
}
```

#### Response
```json
{
  "userId": "firebase-uid-xxx",
  "nickname": "まちだん太郎",
  "createdAt": "2025-01-03T09:00:00Z"
}
```

### GET /v1/users/me
現在のユーザー情報を取得。

#### Response
```json
{
  "userId": "firebase-uid-xxx",
  "nickname": "まちだん太郎",
  "createdAt": "2025-01-03T09:00:00Z",
  "totalWalks": 12,
  "totalDistanceKm": 34.5
}
```

### PATCH /v1/users/me
ユーザー情報を更新。

#### Request
```json
{
  "nickname": "新しいニックネーム"
}
```

#### Response
```json
{
  "userId": "firebase-uid-xxx",
  "nickname": "新しいニックネーム",
  "updatedAt": "2025-01-03T10:00:00Z"
}
```

### DELETE /v1/users/me
ユーザーアカウントと関連データの削除（退会）。

#### Response
```json
{
  "result": "ok"
}
```

> 退会時は位置情報・散歩履歴などを含む全データを削除する。

---

## Walk

### POST /v1/walks
散歩開始。

> 1ユーザーにつき `active` な walk は 1 件まで。既存の active walk がある場合は `WALK_ALREADY_ACTIVE` エラーを返す。

### Request
```json
{
  "startLocation": { "lat": 35.0, "lon": 139.0 }
}
```

### Response
```json
{
  "walkId": "01JABCDEFG...",
  "status": "active",
  "startedAt": "2025-01-03T09:00:00Z"
}
```

### POST /v1/walks/{walkId}:finish
散歩終了。

### Response
```json
{
  "walkId": "01JABCDEFG...",
  "status": "finished",
  "finishedAt": "2025-01-03T10:00:00Z"
}
```

### POST /v1/walks/{walkId}/suggestions:request
提案生成のリクエスト（非同期）。

### Request
```json
{
  "requestedAt": "2025-01-03T09:20:00Z"
}
```

### Response
```json
{
  "result": "ok",
  "requestId": "01JABCDEFG..."
}
```

`result: ng` の場合は理由は返さず、ログのみ残す。

#### 判定条件
- 前回の `result: ok` リクエストから 5 分未満なら `ng`（設定値 / 初期値: 5分）
- 前回の `result: ok` リクエスト（初回は散歩開始）からの移動距離が 250m 未満なら `ng`（設定値 / 初期値: 250m）
- `result: ok` の場合は `requests/{requestId}` を作成し、Cloud Tasks に `requestId` を渡す

## レート制御（推奨）
- 提案リクエストは 5 分に 1 回まで（基準は直近の `result: ok`）
- 連続リクエストはサーバー側で `ng` 返却

---

## 関連ドキュメント
- → [システム構成](./system.md): アーキテクチャ全体像
- → [データ設計](./data-model.md): Firestore スキーマ
- → [UX仕様](./ux.md): 画面とユーザーフロー
- → [AI設計](./ai.md): LLM による提案生成
