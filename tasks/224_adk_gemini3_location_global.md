# ADK の Gemini 3 利用で region=global に切り替える

## 背景
- ADK で `gemini-3-flash-preview` を使用したいが 404（model not found）が発生
- Vertex AI で Gemini 3 preview を使うには location=global が必要

## 目的
- ADK の `GOOGLE_CLOUD_LOCATION` を `global` に変更し、Gemini 3 preview を利用可能にする

## 対応内容
1. Terraform の Cloud Run ADK 環境変数を `GOOGLE_CLOUD_LOCATION=global` に変更
2. 仕様書（`spec/ai.md`）に Gemini 3 preview と location=global の前提を追記
3. Cloud Run の Revision 設定で環境変数が反映されていることを確認

## 完了条件
- ADK が `gemini-3-flash-preview` で 404 にならない
- Cloud Run ADK の `GOOGLE_CLOUD_LOCATION` が `global`
- 仕様書と Terraform が一致している
