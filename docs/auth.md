# Auth and Security Model / 認証とセキュリティモデル

JPYC Manager MCP は OAuth で保護された HTTP MCP service です。  
The JPYC Manager MCP is an OAuth-protected HTTP MCP service.

## 公開エンドポイント / Public Endpoints

- MCP resource: `https://jpyc-info.com/api/jpyc-manager-mcp`
- OAuth issuer base: `https://jpyc-info.com/api/jpyc-manager-oauth`
- Resource metadata: `https://jpyc-info.com/api/jpyc-manager-oauth/resource-metadata`
- Authorization server metadata: `https://jpyc-info.com/api/jpyc-manager-oauth/metadata`

## クライアント要件 / Expected Client Capabilities

MCP client 側には次が必要です。  
Your MCP client should support:

- HTTP MCP transport
- bearer token authentication
- OAuth authorization flow
- structured tool input and output handling

## セキュリティ境界 / Security Boundaries

- すべての wallet action はサインイン中ユーザーに紐づく  
  every wallet action is bound to the signed-in user
- tool は signer private key を返さない  
  tools do not expose signer private keys
- state-changing operation は quote then execute を要求する  
  state-changing operations require explicit quote then execute steps
- backend-managed signing / sponsorship の運用詳細はここでは公開しない  
  backend-managed signing and sponsorship are intentionally not described in operational detail here

## Ownership Rules / 所有権ルール

- `list_*` は current user 所有の object のみ返す  
  `list_*` only returns objects owned by the current user
- `get_*_status` も ownership check を通す  
  `get_*_status` checks ownership before returning details
- wallet id や quote id だけでは不十分で、ownership context が必要  
  wallet ids and quote ids are not enough without matching ownership context

## Contract Call Rules / コントラクト call ルール

- `read_contract` は `view` / `pure` のみ許可  
  `read_contract` accepts only `view` and `pure` function fragments
- `quote_contract_write` は `nonpayable` / `payable` のみ許可  
  `quote_contract_write` accepts only `nonpayable` and `payable` function fragments
- `execute_contract_write` は live な既存 quote に対してのみ動く  
  `execute_contract_write` only works with a live, previously issued quote

## Secret Handling / 秘密情報の扱い

- plugin sample に secret は含めない  
  plugin samples contain no secrets
- runtime secret は secret manager または deployment environment に置く  
  runtime secrets should live in your secret manager or deployment environment
- backend key、sponsor credential、signer material を public config repo に置かない  
  do not publish backend keys, sponsor credentials, or signer material in an MCP config repository
