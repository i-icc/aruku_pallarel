# 設定画面のハーフモーダル化 (Task 105)

## 背景
- 設定画面 (`SettingsScreen`) を独立したページではなく、ホーム画面下部から表示されるハーフモーダルに変更する
- `spec/images/setting.PNG` のモダンな UI に合わせる (既存のリストベースでもOKだが、表示形式をシートにする)

## ゴール
- 「設定」ボタンを押すと、画面遷移ではなくハーフモーダル (`showModalBottomSheet`) が表示される
- モーダル内で既存の設定項目（マップテーマ、位置偽装、ログアウト）が操作できる
- `SettingsScreen` (ページ) と `SettingsRoute` (ルート) を廃止する

## ToDo
- [x] `SettingsSheet` ウィジェットの作成
  - [x] `SettingsScreen` の内容を移植し、スクロール可能なシートとして実装する
  - [x] ヘッダーには「ドラッグハンドル」などを配置してシートらしくする
- [x] `HomeScreen` の修正
  - [x] 設定ボタン (`AppFloatingButton`) の `onTap` 処理を変更
  - [x] `context.router.push` ではなく `showModalBottomSheet` を呼び出す
- [x] 不要コードの削除
  - [x] `SettingsScreen` ファイルを削除
  - [x] `AppRouter` から `SettingsRoute` を削除

## 受け入れ条件
- ホーム画面の「設定」ボタンを押すと、下から設定シートが出てくる
- シート内でマップテーマ変更、位置偽装、ログアウトが正常に動作する
- シートを閉じる操作（ドラッグや外部タップ）ができる
- `/settings` ルートが存在しなくなっている（`flutter analyze` でエラーが出ないこと）
