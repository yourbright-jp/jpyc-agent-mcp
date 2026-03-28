# Tool Catalog

All tools return structured JSON content. State-changing actions use a quote-first flow.

## Wallet Tools

### `list_agent_wallets`

- Purpose: list wallets owned by the signed-in user
- Input:
  - `limit`
  - `cursor`
  - `chain`
  - `status`
- Returns:
  - `items`
  - `next_cursor`

### `get_agent_wallet`

- Purpose: fetch a wallet by `agent_wallet_id` or `agent_name`
- Input:
  - `agent_wallet_id`
  - `agent_name`
- Returns:
  - wallet metadata
  - chain and signer mode

### `create_agent_wallet`

- Purpose: create or reuse a Polygon agent wallet
- Input:
  - `agent_name`
  - `chain`
  - `metadata`
- Returns:
  - `agent_wallet_id`
  - `wallet_address`
  - `existing`
  - signer and execution mode

### `get_agent_wallet_balance`

- Purpose: fetch JPYC balance, gas balance, and pending outbound summary
- Input:
  - `agent_wallet_id`
- Returns:
  - `on_chain_jpyc`
  - `native_gas`
  - `pending_outbound`
  - `available_balance`
  - `stale`

## JPYC Transfer Tools

### `quote_transfer`

- Purpose: create an expiring JPYC transfer quote
- Input:
  - `agent_wallet_id`
  - `to_address`
  - `amount_jpyc`
- Returns:
  - `quote_id`
  - `wallet_address`
  - `to_address`
  - `amount_jpyc`
  - gas and sponsored cost fields
  - `expires_at`
  - `status`

### `transfer_jpyc`

- Purpose: execute a previously quoted transfer
- Input:
  - `agent_wallet_id`
  - `quote_id`
  - `signature_payload`
- Returns:
  - `transfer_request_id`
  - `quote_id`
  - `status`
  - `user_op_hash`
  - `tx_hash`
  - `explorer_url`

### `list_transactions`

- Purpose: list transfer history for a wallet
- Input:
  - `agent_wallet_id`
  - `limit`
  - `cursor`
- Returns:
  - `items`
  - `next_cursor`

### `get_transfer_status`

- Purpose: fetch one transfer execution record
- Input:
  - `transfer_request_id`
- Returns:
  - transfer status fields
  - sponsor and execution fields
  - `tx_hash`
  - `explorer_url`

## Contract Read and Write Tools

### `read_contract`

- Purpose: call a `view` or `pure` Polygon contract function through the wallet context
- Input:
  - `agent_wallet_id`
  - `contract_address`
  - `abi_fragment`
  - `args`
- Returns:
  - `call_data`
  - decoded `result`
  - wallet and chain metadata
- Notes:
  - single function ABI fragment only
  - fallback, event, and write fragments are rejected

### `quote_contract_write`

- Purpose: simulate a contract write and store an executable quote
- Input:
  - `agent_wallet_id`
  - `contract_address`
  - `abi_fragment`
  - `args`
  - `value_native`
- Returns:
  - `quote_id`
  - `call_data`
  - `value_native`
  - `estimated_gas`
  - `simulation_status`
  - `simulation_result`
  - `expires_at`
  - `status`
- Notes:
  - Polygon only
  - single function ABI fragment only
  - write must be `nonpayable` or `payable`
  - execution requires the returned `quote_id`

### `execute_contract_write`

- Purpose: execute a previously quoted contract write
- Input:
  - `agent_wallet_id`
  - `quote_id`
- Returns:
  - `execution_status`
  - `user_op_hash`
  - `tx_hash`
  - `explorer_url`
  - `submitted_at`
  - `confirmed_at`

### `list_contract_call_history`

- Purpose: list quoted and executed contract writes for a wallet
- Input:
  - `agent_wallet_id`
  - `limit`
  - `cursor`
- Returns:
  - `items`
  - `next_cursor`

### `get_contract_call_status`

- Purpose: fetch one quoted or executed contract write
- Input:
  - `quote_id`
- Returns:
  - quote metadata
  - execution metadata
  - `tx_hash`
  - `explorer_url`

## Common Errors

Typical errors include:

- `unauthorized`
- `wallet_not_found`
- `unsupported_chain`
- `invalid_address`
- `invalid_amount`
- `invalid_native_amount`
- `invalid_args`
- `invalid_cursor`
- `quote_not_found`
- `quote_expired`
- `contract_call_quote_not_found`
- `unsupported_function_state_mutability`
- `nonpayable_function_cannot_receive_value`
- `insufficient_balance`
- `insufficient_native_balance`

## Integration Notes

- Treat quotes as short-lived
- Always store `quote_id` if you may execute later
- Prefer `read_contract` for inspection and `quote_contract_write` for any state-changing call
- Expect wallet ownership checks on every tool call
