# plugin サンプル

このディレクトリには、JPYC Agent MCP をクライアントに登録するための公開サンプルを置いています。  
どのファイルにも secret は含まれていません。

## 含まれているもの

- `.codex-plugin/plugin.json`
  - Codex App 向けの plugin サンプルです
- `.mcp.json`
  - HTTP MCP クライアント向けの設定サンプルです
- `config/default.json`
  - 非 secret の既定値サンプルです

## 使い方

### Codex App で使う

`.codex-plugin/plugin.json` の内容をベースに、Codex 側へ登録してください。

### MCP クライアントで使う

`.mcp.json` の `url` を MCP endpoint として使ってください。

endpoint のパスには `jpyc-manager` が残っていますが、公開名称は `JPYC Agent MCP` です。

現在の公開 endpoint:

- `https://jpyc-info.com/api/jpyc-manager-mcp`

## 注意点

- これらはあくまでサンプルです
- 環境に応じて URL や runtime value は調整してください
- 認証は OAuth 前提です
- 利用前にサインインが必要です
