# JPYC Agent MCP - Claude Code Instructions

This repository is the JPYC Agent MCP plugin. It provides OAuth-protected
wallet, transfer, and contract tools on Polygon.

## Authentication

The MCP endpoint requires OAuth. Claude Code does not currently auto-handle
this flow for `streamable-http` servers.

Before using any JPYC tools, check whether the user has already authenticated:

```bash
test -f ~/.jpyc-agent-mcp/oauth-cache.json && echo "authenticated" || echo "not authenticated"
```

If **not authenticated**, guide the user through the helper script:

1. Start auth (opens browser):
   ```bash
   bash scripts/jpyc_oauth_cache.sh start --open-browser
   ```
2. User opens the `authorization_url` in browser and grants consent.
3. Save the token:
   ```bash
   bash scripts/jpyc_oauth_cache.sh wait --auth-session-id <id>
   ```

Alternative scripts are also available:
- PowerShell: `scripts/jpyc_oauth_cache.ps1` (requires ExecutionPolicy bypass)
- Python: `scripts/jpyc_oauth_cache.py` (requires Python + Windows DPAPI)

## Calling Tools

Use the helper script to call MCP tools:

```bash
bash scripts/jpyc_oauth_cache.sh call-tool --tool <tool_name> --arguments '<json>'
```

## Operational Rules

Follow the skill definition in `skills/jpyc-agent-mcp/SKILL.md`:

- Check `auth_status` before private wallet operations.
- Prefer `list_agent_wallets` before creating a new wallet.
- Use quote-first flows for state-changing actions:
  - Transfer: `quote_transfer` then `transfer_jpyc`
  - Contract write: `quote_contract_write` then `execute_contract_write`
- Do not invent tools, assume private keys, or bypass OAuth.

## Available Tools

auth_status, list_agent_wallets, get_agent_wallet, create_agent_wallet,
get_agent_wallet_balance, quote_transfer, transfer_jpyc, list_transactions,
get_transfer_status, read_contract, quote_contract_write,
execute_contract_write, list_contract_call_history, get_contract_call_status

## References

- Setup guide: `docs/claude-code.md`
- Token caching: `docs/local-token-cache.md`
- Full tool docs: `docs/tools.md`
- OAuth details: `docs/auth.md`
