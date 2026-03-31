# Local Token Cache

This repository can be used with a local helper that persists JPYC Agent MCP
OAuth credentials on the operator machine and reuses them across future Codex
sessions.

The helper lives at [`scripts/jpyc_oauth_cache.py`](../scripts/jpyc_oauth_cache.py).

## What It Does

- starts a new OAuth session
- waits for the browser login to complete
- stores the issued `refresh_token` locally
- encrypts the stored token with Windows DPAPI
- refreshes short-lived `access_token` values on demand
- calls `auth_status` or any other MCP tool with the refreshed bearer token

## Storage Location

By default the helper stores token metadata at:

- Windows: `~/.jpyc-agent-mcp/oauth-cache.json`

The `refresh_token` is encrypted for the current Windows user account before it
is written to disk. The encrypted cache is intended for reuse on the same
machine and under the same Windows user profile.

## First-Time Setup

Start a new auth session:

```powershell
python scripts/jpyc_oauth_cache.py start --open-browser
```

That prints:

- `authorization_url`
- `auth_session_id`

After login and consent complete in the browser, wait for authorization and
save the refresh token:

```powershell
python scripts/jpyc_oauth_cache.py wait --auth-session-id <auth_session_id>
```

## Reuse Across Future Sessions

Once the cache exists, future sessions can refresh access automatically without
opening the browser again:

```powershell
python scripts/jpyc_oauth_cache.py auth-status
```

```powershell
python scripts/jpyc_oauth_cache.py call-tool --tool list_agent_wallets --arguments "{\"limit\":20,\"chain\":\"polygon\"}"
```

```powershell
python scripts/jpyc_oauth_cache.py call-tool --tool create_agent_wallet --arguments "{\"agent_name\":\"codex-wallet\",\"chain\":\"polygon\"}"
```

## Notes

- This helper is a client-side fallback when the MCP client does not persist
  OAuth tokens reliably.
- The cache is local to the machine and Windows user account.
- Deleting `~/.jpyc-agent-mcp/oauth-cache.json` forces a fresh browser login.
- If the OAuth server rotates the refresh token, the helper updates the cache.
