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
- Resource metadata: `https://jpyc-info.com/.well-known/oauth-protected-resource`
- Authorization server metadata: `https://jpyc-info.com/.well-known/oauth-authorization-server`
- OpenID configuration: `https://jpyc-info.com/.well-known/openid-configuration`
- Human sign-in page: `https://jpyc-info.com/mcp/connect`
- MCP Registry auth file: `https://jpyc-info.com/.well-known/mcp-registry-auth`

The endpoint is OAuth-protected. Users must log in and grant consent before private wallet operations can run.
If you open the MCP endpoint directly in a browser, it redirects to `https://jpyc-info.com/mcp/connect`.
If an MCP client receives `401 unauthorized`, it should follow `WWW-Authenticate` and the resource metadata above to discover the OAuth flow.
If ChatGPT/Codex does not surface a full authorization URL automatically, open `https://jpyc-info.com/mcp/connect` in the browser as the canonical human fallback. Low-level manual auth with `/api/jpyc-agent-oauth/start` remains available for debugging, but it is not the primary documented path.

For the complete OAuth contract and exact URLs, see [`docs/auth.md`](./docs/auth.md) and [`config/oauth.json`](./config/oauth.json).

## Claude Code

Add the following to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "jpyc-agent-mcp": {
      "type": "streamable-http",
      "url": "https://jpyc-info.com/api/jpyc-agent-mcp"
    }
  }
}
```

## Client Token Persistence

This repository defines the OAuth-protected MCP endpoint and the plugin metadata needed for Codex discovery. It does not implement client-side credential storage on behalf of Codex, ChatGPT, or any other MCP client.

Expected client behavior:

1. Start the OAuth flow against the JPYC Agent OAuth issuer
2. Receive the issued bearer token or equivalent session credential
3. Persist that credential in the client's local secure storage
4. Reuse it on subsequent MCP calls to `https://jpyc-info.com/api/jpyc-agent-mcp`
5. Verify the recovered session with `auth_status`

If a client can complete browser login but cannot persist and reuse the issued credential locally, the MCP integration is incomplete from the user's point of view. In that case, the fix belongs in the MCP client implementation rather than this repository's server-side OAuth protocol.

## MCP Registry

This repository includes [`server.json`](./server.json) for publishing the remote server to the public MCP Registry using the domain-based namespace `com.jpyc-info/jpyc-agent-mcp`.

For HTTP-based domain verification, host the exact text value `v=MCPv1; k=...; p=...` at `https://jpyc-info.com/.well-known/mcp-registry-auth`. In the `jpyc-info` deployment, that endpoint is served from the `MCP_REGISTRY_AUTH` environment variable.

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
- For more details, see [`docs/auth.md`](./docs/auth.md), [`config/oauth.json`](./config/oauth.json), and [`docs/openai-and-mcp.md`](./docs/openai-and-mcp.md).
