# 位置情報取得ライブラリを locus v2 に置き換える

## 背景 / 事象
- 位置情報取得で geolocator を想定していたが、要件的には locus v2 の distanceFilter が適している
- ポーリング実装を避け、移動距離に応じた記録とバックグラウンド対応を簡素化したい

## 目的
- Flutter 側の位置情報取得を locus v2 に統一し、distanceFilter に基づいた取得に切り替える

## 方針
- geolocator 依存を削除し、locus v2 を追加する
- distanceFilter を用いて一定距離移動時のみ位置更新を発火させる
- 背景取得の設定は locus の推奨構成に合わせる

## 要件
1. Flutter の依存関係に locus v2 を追加する
2. 位置取得は distanceFilter で移動距離閾値を設定する
3. バックグラウンド取得が必要な場合は locus の推奨設定を採用する

## テスト
- distanceFilter の距離設定を超える移動時に位置更新が発生すること
