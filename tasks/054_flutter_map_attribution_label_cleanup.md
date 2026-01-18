# マップの flutter_map 表記を非表示にする

## 背景 / 事象
- 画面上の地図に flutter_map の表記が出て見た目がノイジー

## 目的
- 地図のアトリビューションをシンプルにし、flutter_map の表記を外す

## 方針
- flutter_map の SimpleAttributionWidget を使わず、独自表示に置き換える

## 要件
1. flutter_map の表記が表示されないこと
2. Carto/OSM のクレジットは表示されること

## テスト
- 散歩中マップでアトリビューションの表示を確認
- 履歴詳細マップでアトリビューションの表示を確認
