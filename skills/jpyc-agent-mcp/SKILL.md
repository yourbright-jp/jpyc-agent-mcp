---
name: jpyc-agent-mcp
description: Use when the user wants to work with JPYC Agent MCP wallets, balances, JPYC transfers, or contract calls on Polygon. Use this skill for safe operational guidance and tool sequencing with the JPYC Agent MCP plugin. Do not use it for generic blockchain education, private key management, or actions outside the JPYC Agent MCP tool surface.
---

# JPYC Agent MCP skill

Use this skill when the task is specifically about operating JPYC Agent MCP through Codex.

## Goals

- Keep the workflow inside the JPYC Agent MCP tool surface.
- Prefer read-only inspection before any state-changing action.
- Enforce quote-first sequencing for transfers and contract writes.
- Make missing prerequisites explicit before you attempt risky actions.

## Tool scope

This skill is for these tool families:

- Authentication: `auth_status`
- Wallets: `list_agent_wallets`, `get_agent_wallet`, `create_agent_wallet`, `get_agent_wallet_balance`
- Transfers: `quote_transfer`, `transfer_jpyc`, `list_transactions`, `get_transfer_status`
- Contracts: `read_contract`, `quote_contract_write`, `execute_contract_write`, `list_contract_call_history`, `get_contract_call_status`

Do not invent tools or assume direct signer access, private keys, or backdoor admin capabilities.

## Operating rules

1. Start by checking whether the user is authenticated when the task depends on private wallet data.
2. For wallet-oriented tasks, prefer `list_agent_wallets` before creating a new wallet.
3. Before any transfer or contract write, gather enough context to avoid avoidable failures:
   - identify the wallet
   - check available balance when relevant
   - confirm chain assumptions are Polygon
4. Treat state-changing actions as two-step flows:
   - transfer: `quote_transfer` -> `transfer_jpyc`
   - contract write: `quote_contract_write` -> `execute_contract_write`
5. If the user asks for execution immediately, still obtain the quote first and summarize the quote before execution.
6. If the user request is ambiguous, prefer inspection and ask for the missing operational parameter rather than guessing.

## Safe defaults

- Prefer `agent_wallet_id` over fuzzy identification when the user already has it.
- If there are multiple wallets and the target is unclear, stop and ask which wallet to use.
- When reading a contract, confirm the contract address, ABI fragment, method, and arguments before calling.
- When quoting a transfer, confirm `to_address` and `amount_jpyc`.
- When quoting a contract write, clearly distinguish estimation from execution.

## Response guidance

- Summarize the current step and why it is needed.
- For state-changing requests, explicitly say that you are using a quote-first flow.
- If authentication or approval is required, say so plainly instead of implying execution succeeded.
- If the client does not surface a full OAuth authorization URL, tell the user to open `https://jpyc-info.com/mcp/connect` as the canonical human fallback.
- Only fall back to `https://jpyc-info.com/api/jpyc-agent-oauth/start` plus `auth-session` polling when the client needs a low-level manual OAuth flow for debugging or compatibility reasons.
- Keep blockchain jargon to the minimum needed for the task.

## What not to do

- Do not suggest bypassing OAuth, approvals, or quote validation.
- Do not ask the user for secrets or private keys.
- Do not present a quoted action as if it were already executed.
- Do not use this skill for unrelated Web3 tooling outside the JPYC Agent MCP endpoint.
