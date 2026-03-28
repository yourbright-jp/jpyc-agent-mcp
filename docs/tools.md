# Tool Catalog / ツール一覧

すべての tool は structured JSON を返します。state-changing action は quote-first です。  
All tools return structured JSON content. State-changing actions use a quote-first flow.

## Wallet Tools / ウォレット系

### `list_agent_wallets`

- 目的 / Purpose: サインイン中ユーザーが所有する wallet 一覧を返す  
  list wallets owned by the signed-in user
- 入力 / Input:
  - `limit`
  - `cursor`
  - `chain`
  - `status`
- 応答 / Returns:
  - `items`
  - `next_cursor`

### `get_agent_wallet`

- 目的 / Purpose: `agent_wallet_id` または `agent_name` で wallet を取得する  
  fetch a wallet by `agent_wallet_id` or `agent_name`
- 入力 / Input:
  - `agent_wallet_id`
  - `agent_name`
- 応答 / Returns:
  - wallet metadata
  - chain and signer mode

### `create_agent_wallet`

- 目的 / Purpose: Polygon agent wallet を作成または再利用する  
  create or reuse a Polygon agent wallet
- 入力 / Input:
  - `agent_name`
  - `chain`
  - `metadata`
- 応答 / Returns:
  - `agent_wallet_id`
  - `wallet_address`
  - `existing`
  - signer and execution mode

### `get_agent_wallet_balance`

- 目的 / Purpose: JPYC 残高、gas 残高、pending outbound を返す  
  fetch JPYC balance, gas balance, and pending outbound summary
- 入力 / Input:
  - `agent_wallet_id`
- 応答 / Returns:
  - `on_chain_jpyc`
  - `native_gas`
  - `pending_outbound`
  - `available_balance`
  - `stale`

## JPYC Transfer Tools / JPYC 送金系

### `quote_transfer`

- 目的 / Purpose: 期限付きの JPYC transfer quote を作る  
  create an expiring JPYC transfer quote
- 入力 / Input:
  - `agent_wallet_id`
  - `to_address`
  - `amount_jpyc`
- 応答 / Returns:
  - `quote_id`
  - `wallet_address`
  - `to_address`
  - `amount_jpyc`
  - gas / sponsored cost fields
  - `expires_at`
  - `status`

### `transfer_jpyc`

- 目的 / Purpose: quote 済み transfer を実行する  
  execute a previously quoted transfer
- 入力 / Input:
  - `agent_wallet_id`
  - `quote_id`
  - `signature_payload`
- 応答 / Returns:
  - `transfer_request_id`
  - `quote_id`
  - `status`
  - `user_op_hash`
  - `tx_hash`
  - `explorer_url`

### `list_transactions`

- 目的 / Purpose: wallet の transfer history を返す  
  list transfer history for a wallet
- 入力 / Input:
  - `agent_wallet_id`
  - `limit`
  - `cursor`
- 応答 / Returns:
  - `items`
  - `next_cursor`

### `get_transfer_status`

- 目的 / Purpose: 1 件の transfer execution 状態を返す  
  fetch one transfer execution record
- 入力 / Input:
  - `transfer_request_id`
- 応答 / Returns:
  - transfer status fields
  - sponsor and execution fields
  - `tx_hash`
  - `explorer_url`

## Contract Read and Write Tools / コントラクト read/write 系

### `read_contract`

- 目的 / Purpose: `view` / `pure` の Polygon contract function を実行する  
  call a `view` or `pure` Polygon contract function through the wallet context
- 入力 / Input:
  - `agent_wallet_id`
  - `contract_address`
  - `abi_fragment`
  - `args`
- 応答 / Returns:
  - `call_data`
  - decoded `result`
  - wallet and chain metadata
- 注記 / Notes:
  - 単一 function ABI fragment のみ  
    single function ABI fragment only
  - fallback / event / write fragment は拒否  
    fallback, event, and write fragments are rejected

### `quote_contract_write`

- 目的 / Purpose: contract write を simulate し、実行用 quote を保存する  
  simulate a contract write and store an executable quote
- 入力 / Input:
  - `agent_wallet_id`
  - `contract_address`
  - `abi_fragment`
  - `args`
  - `value_native`
- 応答 / Returns:
  - `quote_id`
  - `call_data`
  - `value_native`
  - `estimated_gas`
  - `simulation_status`
  - `simulation_result`
  - `expires_at`
  - `status`
- 注記 / Notes:
  - Polygon only
  - 単一 function ABI fragment のみ  
    single function ABI fragment only
  - write は `nonpayable` または `payable` のみ  
    write must be `nonpayable` or `payable`
  - 実行には返却された `quote_id` が必要  
    execution requires the returned `quote_id`

### `execute_contract_write`

- 目的 / Purpose: quote 済み contract write を実行する  
  execute a previously quoted contract write
- 入力 / Input:
  - `agent_wallet_id`
  - `quote_id`
- 応答 / Returns:
  - `execution_status`
  - `user_op_hash`
  - `tx_hash`
  - `explorer_url`
  - `submitted_at`
  - `confirmed_at`

### `list_contract_call_history`

- 目的 / Purpose: wallet の contract write quote / execution 履歴を返す  
  list quoted and executed contract writes for a wallet
- 入力 / Input:
  - `agent_wallet_id`
  - `limit`
  - `cursor`
- 応答 / Returns:
  - `items`
  - `next_cursor`

### `get_contract_call_status`

- 目的 / Purpose: 1 件の contract write quote / execution 状態を返す  
  fetch one quoted or executed contract write
- 入力 / Input:
  - `quote_id`
- 応答 / Returns:
  - quote metadata
  - execution metadata
  - `tx_hash`
  - `explorer_url`

## 代表的なエラー / Common Errors

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

## 連携メモ / Integration Notes

- quote は短命として扱う  
  treat quotes as short-lived
- あとで実行するなら `quote_id` を保存する  
  always store `quote_id` if you may execute later
- 調査は `read_contract`、state-changing action は `quote_contract_write` を基本にする  
  prefer `read_contract` for inspection and `quote_contract_write` for any state-changing call
- すべての call に ownership check がある前提で組む  
  expect wallet ownership checks on every tool call
