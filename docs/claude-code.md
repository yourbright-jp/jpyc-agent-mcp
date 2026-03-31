# Claude Code Setup Guide

Claude Code can connect to the JPYC Agent MCP endpoint, but the OAuth
authentication flow must be completed manually before tools become available.

## Prerequisites

- Claude Code (latest version recommended)
- Windows: PowerShell 5.1+ (pre-installed)
- macOS / Linux: Python 3.8+

## Step 1: Add MCP Configuration

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

> **Note:** Use `"type": "streamable-http"`, not `"http"`.

## Step 2: Complete OAuth Authentication

Claude Code does not currently auto-handle OAuth for `streamable-http` MCP
servers. You must authenticate using the helper script before tools will load.

### Windows (PowerShell)

```powershell
# 1. Start OAuth session (opens browser automatically)
powershell.exe -ExecutionPolicy Bypass -File scripts/jpyc_oauth_cache.ps1 start -OpenBrowser
```

The command prints `auth_session_id` and `authorization_url`. If the browser
does not open, copy the `authorization_url` and open it manually.

Log in and grant consent in the browser, then save the token:

```powershell
# 2. Wait for authorization and save tokens
powershell.exe -ExecutionPolicy Bypass -File scripts/jpyc_oauth_cache.ps1 wait -AuthSessionId <auth_session_id>
```

### macOS / Linux (Python)

```bash
# 1. Start OAuth session
python3 scripts/jpyc_oauth_cache.py start --open-browser

# 2. Wait for authorization and save tokens
python3 scripts/jpyc_oauth_cache.py wait --auth-session-id <auth_session_id>
```

## Step 3: Verify Authentication

```powershell
# Windows
powershell.exe -ExecutionPolicy Bypass -File scripts/jpyc_oauth_cache.ps1 auth-status
```

```bash
# macOS / Linux
python3 scripts/jpyc_oauth_cache.py auth-status
```

Expected output includes `"authenticated": true`.

## Step 4: Use Tools via Claude Code

Once authenticated, call JPYC Agent MCP tools from within a Claude Code
session using the helper script through the Bash tool:

```bash
# List wallets
powershell.exe -ExecutionPolicy Bypass -File scripts/jpyc_oauth_cache.ps1 call-tool -Tool list_agent_wallets -Arguments '{"limit":20,"chain":"polygon"}'

# Create a wallet
powershell.exe -ExecutionPolicy Bypass -File scripts/jpyc_oauth_cache.ps1 call-tool -Tool create_agent_wallet -Arguments '{"agent_name":"my-wallet","chain":"polygon"}'

# Check balance
powershell.exe -ExecutionPolicy Bypass -File scripts/jpyc_oauth_cache.ps1 call-tool -Tool get_agent_wallet_balance -Arguments '{"agent_wallet_id":"<wallet_id>"}'
```

The cached refresh token is encrypted with Windows DPAPI and persists across
sessions. You do not need to re-authenticate unless the token is revoked.

## Troubleshooting

### Tools do not appear after adding MCP config

This is expected. Claude Code cannot complete the OAuth handshake
automatically for this server. Complete Step 2 above, then use `call-tool`
through the Bash tool.

### Token expired or `401 Unauthorized`

The helper script refreshes the access token automatically. If the refresh
token itself has expired, delete the cache and re-authenticate:

```powershell
Remove-Item ~/.jpyc-agent-mcp/oauth-cache.json
# Then repeat Step 2
```

### Browser does not open with `-OpenBrowser`

Copy the `authorization_url` from the script output and open it manually in
your browser.

### PowerShell execution policy error

Use `-ExecutionPolicy Bypass` when invoking the script:

```powershell
powershell.exe -ExecutionPolicy Bypass -File scripts/jpyc_oauth_cache.ps1 start
```

## Token Cache Location

- Windows: `~/.jpyc-agent-mcp/oauth-cache.json`

The refresh token is encrypted with DPAPI (Windows) and is only usable by the
same Windows user account on the same machine.

## Known Limitations

- Tools are called via the helper script, not as native MCP tools in
  Claude Code. This is a workaround until Claude Code supports OAuth for
  `streamable-http` MCP servers natively.
- The PowerShell script requires Windows. macOS / Linux users should use the
  Python script.
