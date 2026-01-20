# 位置情報権限フローの調整（iOS Simulator で許可が返らない問題）

## 背景 / 事象
- Locus の `requestPermission` は permission_handler の `requestAll` を呼ぶ
- iOS Simulator では motion/sensors が許可できず `requestAll` が false になりやすい
- 結果として位置情報の許可が取れているのに UI が未許可扱いになる

## 目的
- 位置情報の許可状態を正しく判定し、取得できる状況では追跡を開始する

## 方針
- `permission_handler` を直接使い、locationWhenInUse を必須、locationAlways は任意として扱う
- Locus の start は locationWhenInUse が許可されていれば進める
- 位置情報サービスの状態も UI に反映する

## 要件
1. locationWhenInUse が許可されていれば tracking を開始できる
2. locationAlways 未許可時は注意表示を出す
3. 位置情報サービスが OFF の場合は設定導線を表示する

## テスト
- iOS Simulator で locationWhenInUse が許可されていれば位置更新が開始されること
- locationAlways 未許可時に注意表示が出ること
