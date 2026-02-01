# ビルドエラー: ChatRoute の const 解除

## 背景
- `const ChatRoute()` が非 const コンストラクタになりビルドエラーになる

## ゴール
- ビルドが通る

## ToDo
- [x] `const ChatRoute()` を通常コンストラクタ呼び出しに変更する

## 受け入れ条件
- iOS シミュレータでビルドが通る
