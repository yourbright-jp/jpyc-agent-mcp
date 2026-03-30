# JPYC Agent MCP

JPYC Agent MCP can be used both as a public MCP endpoint and as a Codex plugin bundle.
This repository now uses the repository root as the plugin root so Codex can discover it directly.

## What It Supports

- Polygon agent wallet creation and lookup
- Wallet balance inspection
- JPYC transfer quote and execution flows
- Contract read calls
- Contract write quote and execution flows
- Transfer and contract call status tracking

## Plugin Layout

Codex should discover the plugin from the repository root via the files below:

- [`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json)
- [`.mcp.json`](./.mcp.json)
- [`skills/jpyc-agent-mcp/SKILL.md`](./skills/jpyc-agent-mcp/SKILL.md)
- [`skills/jpyc-agent-mcp/agents/openai.yaml`](./skills/jpyc-agent-mcp/agents/openai.yaml)
- [`config/default.json`](./config/default.json)

## Public Endpoint

- MCP endpoint: `https://jpyc-info.com/api/jpyc-agent-mcp`
- OAuth issuer: `https://jpyc-info.com/api/jpyc-agent-oauth`
- Resource metadata: `https://jpyc-info.com/api/jpyc-agent-oauth/resource-metadata`

The endpoint is OAuth-protected. Users must log in and grant consent before private wallet operations can run.
If ChatGPT/Codex does not surface a full authorization URL automatically, use the manual fallback at `https://jpyc-info.com/api/jpyc-agent-oauth/start` to create an auth session, open the returned `authorization_url`, then poll `https://jpyc-info.com/api/jpyc-agent-oauth/auth-session?auth_session_id=...` until it becomes authorized.

## Main Tools

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

Detailed request and response examples are in [`docs/tools.md`](./docs/tools.md).

## Recommended Flow

1. Check `auth_status`
2. Inspect wallets with `list_agent_wallets`
3. Create a wallet only if needed with `create_agent_wallet`
4. Check balances before transfers
5. Use quote-first execution for transfers and contract writes

Transfer flow:

1. `quote_transfer`
2. `transfer_jpyc`

Contract write flow:

1. `quote_contract_write`
2. `execute_contract_write`

## Notes

- This repo does not include secrets.
- This repo does not include private keys or signer material.
- The bundled skill is intended to keep Codex inside the JPYC Agent MCP tool surface.
- For more details, see [`docs/auth.md`](./docs/auth.md) and [`docs/openai-and-mcp.md`](./docs/openai-and-mcp.md).
