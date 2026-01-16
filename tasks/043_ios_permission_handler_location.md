# iOS 位置情報の権限ダイアログが出ない問題の修正

## 背景 / 事象
- Locus は内部で permission_handler を使用する
- iOS では Podfile に権限のプリプロセッサ定義がないと権限ダイアログが出ない

## 目的
- iOS で位置情報の権限ダイアログが正しく表示されるようにする

## 方針
- Podfile に permission_handler 用の定義を追加する

## 要件
1. `PERMISSION_LOCATION=1` と `PERMISSION_SENSORS=1` を追加する
2. `pod install` で反映されること

## テスト
- iOS Simulator で権限ダイアログが表示されること
- 設定で許可後に位置情報が取得できること
