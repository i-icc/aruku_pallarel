# Info ボタンを左下角に寄せ、現在タイルのみ表示する

## 背景 / 事象
- Info ボタンが角から少し離れている
- Map Info で全テーマ一覧が表示されている
- Settings の Map Info は不要になった

## 目的
- Info ボタンを左下の角に寄せる
- Map Info は現在使用中のタイル情報のみ表示する
- Settings から Map Info 導線を削除する

## 方針
- Info ボタンの位置を SafeArea の角寄せに変更する
- ボトムシートは現在テーマのみ表示する
- Settings から Map Info セクションを削除する

## 要件
1. 散歩中/履歴詳細の左下に Info ボタンが配置されること
2. Map Info は現在のタイル情報のみ表示すること
3. Settings から Map Info が削除されていること

## テスト
- Info ボタン位置が左下角に寄っている
- Map Info が現在テーマのみ表示される
- Settings に Map Info が出ない
