# Auth and Security Model

The JPYC Agent MCP is an OAuth-protected HTTP MCP service.

## Public Endpoints

- MCP resource: `https://jpyc-info.com/api/jpyc-agent-mcp`
- Human sign-in page: `https://jpyc-info.com/mcp/connect`
- OAuth issuer base: `https://jpyc-info.com/api/jpyc-agent-oauth`
- Resource metadata: `https://jpyc-info.com/.well-known/oauth-protected-resource`
- Authorization server metadata: `https://jpyc-info.com/.well-known/oauth-authorization-server`
- OpenID configuration: `https://jpyc-info.com/.well-known/openid-configuration`
- Low-level manual auth start: `POST https://jpyc-info.com/api/jpyc-agent-oauth/start`
- Manual auth poll: `GET https://jpyc-info.com/api/jpyc-agent-oauth/auth-session?auth_session_id=...&auth_session_secret=...`

The exact public OAuth coordinates are also published in [`../config/oauth.json`](../config/oauth.json).

## Expected Client Capabilities

Your MCP client should support:

- HTTP MCP transport
- bearer token authentication
- OAuth authorization flow
- structured tool input and output handling

After connecting, it is recommended to call `auth_status` first to confirm the session is valid.

Unauthenticated non-browser requests receive `401 unauthorized` and should discover OAuth through `WWW-Authenticate` plus the resource metadata.

If you open `https://jpyc-info.com/api/jpyc-agent-mcp` directly in a browser, it will send you to `https://jpyc-info.com/mcp/connect`.

## Recommended Human Fallback

The canonical human fallback is `https://jpyc-info.com/mcp/connect`.

Open `mcp/connect` first when:

- the MCP client does not surface a full OAuth URL
- the client does not handle `401` plus `WWW-Authenticate`
- you want a human-visible browser flow

## Token Lifecycle And Local Persistence

OAuth login is only the first half of the integration. After the issuer authorizes the user, the MCP client is expected to retain the issued credential and reuse it on later MCP requests.

- The OAuth server is responsible for issuing credentials
- The MCP client is responsible for storing credentials in local secure storage
- The MCP client is responsible for attaching the stored credential to later MCP requests
- A healthy integration should still be able to call `auth_status` after the client restarts and reloads its saved credentials

This repository documents the protocol and endpoint behavior, but it does not prescribe where a specific client such as Codex Desktop stores its local tokens. If the browser login succeeds but later MCP calls cannot recover the credential, the defect is in the client integration layer rather than in the JPYC Agent MCP OAuth protocol itself.

## Manual Fallback

Low-level manual auth remains available for debugging or client compatibility:

1. `POST /api/jpyc-agent-oauth/start` to create an auth session
2. Open the returned `authorization_url` in the browser
3. Complete JPYC Info login and consent
4. Keep the returned `auth_session_secret` private on the client side
5. Poll `/api/jpyc-agent-oauth/auth-session?auth_session_id=...&auth_session_secret=...`
6. When the response becomes `authorized`, reuse the returned bearer token for MCP calls

## Security Boundaries

- every wallet action is bound to the signed-in user
- tools do not expose signer private keys
- state-changing operations require explicit quote then execute steps
- backend-managed signing and sponsorship are intentionally not described in operational detail here

## Ownership Rules

- `list_*` only returns objects owned by the current user
- `get_*_status` checks ownership before returning details
- wallet ids and quote ids are not enough without matching ownership context

## Contract Call Rules

- `read_contract` accepts only `view` and `pure` function fragments
- `quote_contract_write` accepts only `nonpayable` and `payable` function fragments
- `execute_contract_write` only works with a live, previously issued quote

## Secret Handling

- plugin samples contain no secrets
- runtime secrets should live in your secret manager or deployment environment
- do not publish backend keys, sponsor credentials, or signer material in an MCP config repository
