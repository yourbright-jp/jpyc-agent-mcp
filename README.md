# JPYC Agent MCP

Public documentation and plugin samples for the JPYC Manager MCP.

This repository is intended for external agents, tool builders, and integration engineers who need enough public information to decide whether they can connect to the MCP and how to use it safely.

## What This MCP Does

The JPYC Manager MCP provides OAuth-protected HTTP MCP tools for:

- creating Polygon agent wallets
- checking JPYC and gas balances
- quoting and executing JPYC transfers
- reading arbitrary Polygon contracts
- quoting and executing contract writes through agent wallets
- listing transfer and contract call history

## What You Need Before Connecting

- an MCP client that supports HTTP MCP and OAuth
- a user account authorized to access the JPYC Manager deployment
- a Polygon-focused workflow
- acceptance of the quote-then-execute model for state-changing actions

## Core Constraints

- Polygon only
- user-owned wallets only
- contract writes require `quote_contract_write` before `execute_contract_write`
- JPYC transfers require `quote_transfer` before `transfer_jpyc`
- secrets and signer material are not distributed through this repository

## Hosted Endpoint Pattern

Current hosted endpoint pattern:

- MCP resource: `https://jpyc-info.com/api/jpyc-manager-mcp`
- OAuth issuer base: `https://jpyc-info.com/api/jpyc-manager-oauth`
- OAuth resource metadata: `https://jpyc-info.com/api/jpyc-manager-oauth/resource-metadata`

Use these as the public connection surface. Project-specific access policy still applies.

## Repository Layout

- [docs/tools.md](./docs/tools.md): tool catalog and request/response notes
- [docs/auth.md](./docs/auth.md): OAuth and security model
- [docs/openai-and-mcp.md](./docs/openai-and-mcp.md): OpenAI and MCP integration notes with official links
- [plugin/.codex-plugin/plugin.json](./plugin/.codex-plugin/plugin.json): public plugin manifest sample
- [plugin/.mcp.json](./plugin/.mcp.json): public MCP client sample
- [plugin/config/default.json](./plugin/config/default.json): non-secret runtime sample

## Who This Repo Is For

- external agent developers evaluating tool coverage
- teams integrating MCP tools into internal or hosted agents
- auditors reviewing the public action surface and security model

## What Is Intentionally Not Public Here

- Supabase internal implementation details
- secret names used only for private operations
- signer private key handling internals
- private infrastructure topology

## OpenAI References

For current OpenAI agent and tool calling behavior, use the official docs:

- Function calling: `https://platform.openai.com/docs/guides/function-calling`
- Using tools: `https://platform.openai.com/docs/guides/tools`
- Agents SDK: `https://platform.openai.com/docs/guides/agents-sdk/`
- Agent Builder: `https://platform.openai.com/docs/guides/agent-builder`

## Notes

This repository is the public-facing documentation surface for the JPYC Manager MCP. It is separate from the private implementation repository so that external agents can inspect the public contract without exposing private operational details.
