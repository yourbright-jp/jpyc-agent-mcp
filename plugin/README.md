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

## 利用できる主な tool

接続後に主に使う tool は次のとおりです。

- `auth_status`
- `list_agent_wallets`
- `get_agent_wallet`
- `create_agent_wallet`
- `get_agent_wallet_balance`
- `quote_transfer`
- `transfer_jpyc`
- `list_transactions`
- `get_transfer_status`
- `read_contract`
- `quote_contract_write`
- `execute_contract_write`
- `list_contract_call_history`
- `get_contract_call_status`

## 最初に試す順番

接続直後は、まず次の順番を推奨します。

1. `auth_status`
2. `list_agent_wallets`
3. 必要なら `create_agent_wallet`
4. `get_agent_wallet_balance`

送金したいときは次の順です。

1. `quote_transfer`
2. `transfer_jpyc`

contract write をしたいときは次の順です。

1. `quote_contract_write`
2. `execute_contract_write`

## 注意点

- これらはあくまでサンプルです
- 環境に応じて URL や runtime value は調整してください
- 認証は OAuth 前提です
- 利用前にサインインが必要です
- README に書かれている tool が実際に呼べるかどうかは、クライアントが MCP 接続を正しく有効化できているかに依存します
