# History 画面の Polyline NaN エラー修正

## 背景 / 事象
- History 画面で `Unsupported operation: Infinity or NaN toInt` が発生
- `flutter_map` の polyline 描画で無効な値が混入している可能性が高い

## 目的
- History 画面で例外が出ずにルートを描画できる

## ToDo
- [ ] History のルート描画に使う座標リストを調査し、NaN/Infinity が混入しないようにする
- [ ] Firestore の位置データの欠損/不正値を除外する
- [ ] 経路データが空の場合は polyline を描画しない
- [ ] `flutter_map` の polyline 生成前に値検証を追加する
- [ ] 例外再現手順を残す（データ欠損時の挙動も含む）

## 受け入れ条件
- History 画面でクラッシュしない
- 有効な座標のみで polyline が描画される
