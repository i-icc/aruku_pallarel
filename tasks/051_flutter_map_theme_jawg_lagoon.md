# マップテーマを Jawg Lagoon に切り替える

## 背景 / 事象
- Map の見た目を Jawg Lagoon へ変更したい
- flutter_map のタイル設定と Jawg のスタイル情報を調査する必要がある

## 調査結果
### flutter_map (Context7)
- `TileLayer.urlTemplate` でタイルサーバーを指定できる
- attribution は `SimpleAttributionWidget` / `RichAttributionWidget` を利用

### Jawg Docs (Static Maps)
- `jawg-lagoon` を含むスタイル一覧が公式ドキュメントに掲載されている
  - `jawg-streets`, `jawg-lagoon`, `jawg-terrain`, `jawg-sunny`, `jawg-dark`, `jawg-light`
- Static Maps の例では `layer=jawg-lagoon` で指定できることを確認
- Tile エンドポイントは `https://tile.jawg.io/jawg-lagoon/{z}/{x}/{y}.png?access-token=...` で 403 を返すため、実在することを確認

## 方針
- Jawg Lagoon のタイル URL を使用する
- Access Token を環境変数 `JAWG_ACCESS_TOKEN` で管理する
- attribution は `© Jawg Maps © OpenStreetMap contributors` を表示する

## 要件
1. 散歩/履歴のマップタイルを Jawg Lagoon に切り替える
2. attribution を表示する
3. Access Token を環境変数で受け取る

## テスト
- タイルが Jawg Lagoon に切り替わる
- attribution 表示が出る
