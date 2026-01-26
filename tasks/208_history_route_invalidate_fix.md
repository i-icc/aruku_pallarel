# History 詳細で provider invalidate の例外を解消する

## 背景
- History 詳細で ref.invalidate を initState で実行していた
- InheritedWidget 参照が initState 中に走り例外が発生する

## ゴール
- History 詳細を開いても例外が発生しない
- ルートの再取得は維持される

## ToDo
- [ ] invalidate を didChangeDependencies へ移動する
- [ ] 1回だけ invalidate するように制御する

## 受け入れ条件
- History 詳細の表示で例外が出ない
- ルート再取得が継続される
