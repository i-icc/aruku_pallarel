# マップタイルテーマ調査と最小テーマの適用

## 背景 / 事象
- 散歩画面の地図情報が多く、視認性が低い
- タイルテーマを最もシンプルなものへ切り替えたい

## 調査結果 (flutter_map)
- flutter_map は `TileLayer.urlTemplate` でタイルサーバーを指定できる
- 例: OpenStreetMap 標準タイル `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- タイルサーバーの利用規約に従い、適切な attribution を表示する

### 使えるテーマ例 (タイルサーバー)
- OpenStreetMap Standard
  - URL: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
  - Attribution: `© OpenStreetMap contributors`
- Carto Positron (light)
  - URL: `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png`
  - Attribution: `© OpenStreetMap contributors © CARTO`
- Carto Positron (light, no labels)
  - URL: `https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png`
  - Attribution: `© OpenStreetMap contributors © CARTO`
- Carto Dark Matter
  - URL: `https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png`
  - Attribution: `© OpenStreetMap contributors © CARTO`
- Carto Voyager
  - URL: `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png`
  - Attribution: `© OpenStreetMap contributors © CARTO`

## 方針
- 最もシンプルな「Carto Positron (no labels)」を採用する
- Walk / History のマップを同一テーマに統一する
- attribution 表示を SimpleAttributionWidget で追加する

## 要件
1. 散歩画面のタイルを簡素テーマに差し替える
2. 履歴詳細のタイルも同テーマに差し替える
3. attribution を表示する

## テスト
- 画面に新しいタイルが表示される
- attribution が画面上に表示される
