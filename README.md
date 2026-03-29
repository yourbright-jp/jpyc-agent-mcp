# JPYC Agent MCP

JPYC Agent MCP を外部の MCP クライアントから使うための公開リポジトリです。  
このリポジトリでは、ユーザーが「何ができるか」「どうインストールするか」「接続前に何を知るべきか」をすぐ判断できるように、公開ドキュメントと設定サンプルだけをまとめています。

## できること

JPYC Agent MCP では、主に次の操作を MCP ツールとして使えます。

- Polygon 上の agent wallet の作成
- 自分の wallet 一覧の取得
- JPYC 残高 / gas 残高の確認
- JPYC 送金の quote と実行
- コントラクト read
- コントラクト write の quote と実行
- 送金履歴 / contract call 履歴の確認

## 使える tool 一覧

ユーザーが直接呼ぶ主な tool は次のとおりです。

### 認証

- `auth_status`
  - 現在の MCP session が認証済みか確認します

### wallet

- `list_agent_wallets`
  - 自分の wallet 一覧を返します
- `get_agent_wallet`
  - `agent_wallet_id` または `agent_name` で wallet を取得します
- `create_agent_wallet`
  - Polygon の agent wallet を作成または再利用します
- `get_agent_wallet_balance`
  - JPYC 残高、gas 残高、pending outbound を返します

### JPYC 送金

- `quote_transfer`
  - 送金前の quote を作成します
- `transfer_jpyc`
  - quote 済みの JPYC 送金を実行します
- `list_transactions`
  - wallet の送金履歴を返します
- `get_transfer_status`
  - 個別の送金状態を返します

### contract read / write

- `read_contract`
  - `view` / `pure` の contract call を実行します
- `quote_contract_write`
  - contract write の quote を作成します
- `execute_contract_write`
  - quote 済みの contract write を実行します
- `list_contract_call_history`
  - contract write の履歴を返します
- `get_contract_call_status`
  - 個別の contract write 状態を返します

詳しい request / response は [docs/tools.md](./docs/tools.md) を参照してください。

## インストール方法

### 1. Codex で使う

`plugin/.codex-plugin/plugin.json` を Codex App 向けのサンプルとして公開しています。  
Codex 側で plugin / MCP 設定を追加する場合は、この内容をベースにしてください。

関連ファイル:

- [plugin/.codex-plugin/plugin.json](./plugin/.codex-plugin/plugin.json)
- [plugin/.mcp.json](./plugin/.mcp.json)
- [plugin/config/default.json](./plugin/config/default.json)

### 2. MCP クライアントで使う

HTTP MCP に対応したクライアントでは、公開 endpoint を指定して接続します。

接続先の URL には歴史的な理由で `jpyc-manager` が残っていますが、公開名称は `JPYC Agent MCP` です。

- MCP endpoint: `https://jpyc-info.com/api/jpyc-manager-mcp`
- OAuth issuer: `https://jpyc-info.com/api/jpyc-manager-oauth`
- Resource metadata: `https://jpyc-info.com/api/jpyc-manager-oauth/resource-metadata`

OAuth 対応クライアントであれば、接続時にログインと認可フローが始まります。

## 最初の使い方

接続できたら、まずは次の順に試すのが安全です。

1. `auth_status` で認証状態を確認する
2. `list_agent_wallets` で既存 wallet を確認する
3. wallet がなければ `create_agent_wallet` を呼ぶ
4. `get_agent_wallet_balance` で残高を確認する
5. 送金や contract write は必ず quote を取ってから execute する

### wallet を作りたいとき

1. `auth_status`
2. `list_agent_wallets`
3. 必要なら `create_agent_wallet`

`create_agent_wallet` の主な入力:

```json
{
  "agent_name": "my-agent",
  "chain": "polygon",
  "metadata": {}
}
```

### JPYC を送金したいとき

1. `auth_status`
2. `list_agent_wallets` または `get_agent_wallet`
3. `get_agent_wallet_balance`
4. `quote_transfer`
5. `transfer_jpyc`

`quote_transfer` の主な入力:

```json
{
  "agent_wallet_id": "YOUR_AGENT_WALLET_ID",
  "to_address": "0x...",
  "amount_jpyc": "100"
}
```

`transfer_jpyc` の主な入力:

```json
{
  "agent_wallet_id": "YOUR_AGENT_WALLET_ID",
  "quote_id": "YOUR_QUOTE_ID",
  "signature_payload": {}
}
```

### contract write をしたいとき

1. `auth_status`
2. `get_agent_wallet`
3. `quote_contract_write`
4. `execute_contract_write`

state を変える操作は、送金も contract write も必ず quote-first です。

## 接続前に知っておくこと

- Polygon 前提です
- 操作できるのは、サインイン中ユーザーに紐づく wallet だけです
- state を変える操作は基本的に quote → execute の2段階です
- secret や signer private key はこのリポジトリでは配布しません
- README に tool 名が書かれていても、実際に呼べるかどうかはクライアント側で MCP 接続が有効になっているかに依存します

## インストールサンプル

`plugin` ディレクトリには、公開可能なサンプルだけを置いています。

- [plugin/README.md](./plugin/README.md): サンプルの見方
- [plugin/.codex-plugin/plugin.json](./plugin/.codex-plugin/plugin.json): Codex App 向けサンプル
- [plugin/.mcp.json](./plugin/.mcp.json): 汎用 HTTP MCP 設定サンプル
- [plugin/config/default.json](./plugin/config/default.json): 非 secret の既定値サンプル

## ドキュメント

より詳しい仕様は次を参照してください。

- [docs/tools.md](./docs/tools.md): 利用できる tool 一覧
- [docs/auth.md](./docs/auth.md): OAuth と権限制約
- [docs/openai-and-mcp.md](./docs/openai-and-mcp.md): OpenAI / MCP 関連メモ

## このリポジトリに含めないもの

このリポジトリは公開用です。次のものは含めません。

- 秘密情報
- signer private key
- private infrastructure の構成詳細
- Supabase 内部実装の private な運用詳細

## 補足

この repo は、JPYC Agent MCP を「利用者が接続するための入り口」として整理したものです。  
内部実装の説明よりも、ユーザーが迷わず導入できることを優先しています。
