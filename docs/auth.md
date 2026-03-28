# Auth and Security Model

The JPYC Manager MCP is an OAuth-protected HTTP MCP service.

## Public Endpoints

- MCP resource: `https://jpyc-info.com/api/jpyc-manager-mcp`
- OAuth issuer base: `https://jpyc-info.com/api/jpyc-manager-oauth`
- Resource metadata: `https://jpyc-info.com/api/jpyc-manager-oauth/resource-metadata`
- Authorization server metadata: `https://jpyc-info.com/api/jpyc-manager-oauth/metadata`

## Expected Client Capabilities

Your MCP client should support:

- HTTP MCP transport
- bearer token authentication
- OAuth authorization flow
- structured tool input and output handling

## Security Boundaries

- every wallet action is bound to the signed-in user
- tools do not expose signer private keys
- state-changing operations require explicit quote then execute steps
- backend-managed signing and sponsorship are intentionally not described in operational detail here

## User Ownership Rules

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
