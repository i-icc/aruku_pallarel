# Gitleaks の Podfile.lock 誤検知を除外

## 背景 / 事象
- Gitleaks が `Podfile.lock` の `SPEC CHECKSUMS` を `generic-api-key` として誤検知する

## 目的
- CI を通過させつつ、誤検知だけを除外する

## 方針
- `.gitleaks.toml` を追加し、`Podfile.lock` の 40 桁ハッシュのみ allowlist に入れる
- デフォルトの検出ルールは維持する

## 要件
1. `Podfile.lock` のチェックサムで Gitleaks が失敗しない
2. それ以外の検出は従来通り行われる

## テスト
- Gitleaks が Podfile.lock の checksum を検出しないこと
