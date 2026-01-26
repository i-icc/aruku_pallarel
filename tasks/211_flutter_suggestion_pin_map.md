# 散歩中マップに提案ピンを表示する

## 背景
- 提案通知後にマップ上へピン表示する仕様だが、フロントで未実装
- 提案の場所が視覚的に分からず、チャットへ遷移しても文脈が弱い

## ゴール
- 散歩中マップに提案ピンが表示される
- ピン選択が共有状態に反映され、チャット側と連動できる

## 対象範囲
- 散歩中マップ（MarkerLayer 追加・選択・フォーカス）
- 提案取得の provider（Firestore から `suggests` を購読）
- 選択中 `suggestId` の共有状態
- FCM 受信時のピン選択反映

## 非対象
- 提案生成/Backend/Job の変更
- ピンのクラスタリング

## 仕様参照
- `spec/ux.md`（提案通知 → ピン表示）
- `spec/data-model.md`（suggests/chat スキーマ）
- `spec/system.md`（FCM payload）

## プラン
1. suggests 取得
   - active walkId を取得し、`users/{userId}/walks/{walkId}/suggests` を購読
   - `suggestedAt desc` で取得し、表示モデルへ変換（id/geo/messageId/created）
2. 共有選択状態
   - `selectedSuggestId` を保持する provider を追加
   - active walk 切替時はリセット、初期値は最新提案
3. マップ表示
   - MarkerLayer に提案ピンを追加
   - 選択中ピンはサイズ/色/影などで強調
   - missing geo は除外し、エラーはログのみ
4. インタラクション
   - ピンをタップすると `selectedSuggestId` を更新
   - 画面遷移はせず、チャット側のハイライトと連動
5. フォーカス挙動
   - 選択変更時にカメラを軽く寄せる（ユーザー操作中は抑制）
6. FCM 連動
   - onMessage/onMessageOpenedApp で `suggestId` と `walkId` を確認
   - 現在の active walk と一致する場合のみ選択状態を更新

## ToDo
- [ ] suggests の stream provider を追加
- [ ] 共有の `selectedSuggestId` provider を追加
- [ ] 散歩中マップに提案ピンを描画
- [ ] ピンタップで `selectedSuggestId` を更新
- [ ] 選択ピンを強調し、必要ならカメラを寄せる
- [ ] FCM 受信時に選択状態へ反映
- [ ] 空状態/データ欠損時の安全ハンドリング

## 受け入れ条件
- 提案がある場合、散歩中マップにピンが表示される
- ピンタップで `selectedSuggestId` が更新される
- FCM 受信後、対応するピンが選択状態になる

## テスト
- 散歩開始 → 提案生成 → ピン表示
- ピンタップで選択状態が更新される
- FCM 受信で選択ピンが切り替わる
