# JPYC Agent MCP

JPYC Manager MCP の公開ドキュメントと plugin sample を置く public repository です。  
This public repository contains documentation and plugin samples for the JPYC Manager MCP.

この repo は、外部エージェント、ツール開発者、連携担当者が「この MCP で何ができるか」「どう接続するか」「どの制約があるか」を判断できるようにするためのものです。  
This repo is intended to help external agents, tool builders, and integration engineers decide what this MCP does, how to connect to it, and what constraints apply.

## 何ができるか / What This MCP Does

JPYC Manager MCP は、OAuth で保護された HTTP MCP tool を提供します。  
The JPYC Manager MCP provides OAuth-protected HTTP MCP tools for:

- Polygon 上の agent wallet 作成 / creating Polygon agent wallets
- JPYC と gas 残高確認 / checking JPYC and gas balances
- JPYC 送金の quote と実行 / quoting and executing JPYC transfers
- 任意コントラクト read / reading arbitrary Polygon contracts
- コントラクト write の quote と実行 / quoting and executing contract writes through agent wallets
- 送金履歴と contract call 履歴の確認 / listing transfer and contract call history

## 接続前提 / What You Need Before Connecting

- HTTP MCP と OAuth に対応した MCP client  
  an MCP client that supports HTTP MCP and OAuth
- JPYC Manager deployment にアクセスできるユーザー権限  
  a user account authorized to access the JPYC Manager deployment
- Polygon 前提の運用  
  a Polygon-focused workflow
- state-changing action は quote-then-execute で扱う前提  
  acceptance of the quote-then-execute model for state-changing actions

## 主要な制約 / Core Constraints

- Polygon only
- user-owned wallets only
- `execute_contract_write` の前に `quote_contract_write` が必要  
  contract writes require `quote_contract_write` before `execute_contract_write`
- `transfer_jpyc` の前に `quote_transfer` が必要  
  JPYC transfers require `quote_transfer` before `transfer_jpyc`
- secret や signer material はこの repo では配布しない  
  secrets and signer material are not distributed through this repository

## 公開エンドポイント / Hosted Endpoint Pattern

現在の公開エンドポイントの形は次です。  
The current public endpoint pattern is:

- MCP resource: `https://jpyc-info.com/api/jpyc-manager-mcp`
- OAuth issuer base: `https://jpyc-info.com/api/jpyc-manager-oauth`
- OAuth resource metadata: `https://jpyc-info.com/api/jpyc-manager-oauth/resource-metadata`

外部接続の基点としてはこの surface を見てください。詳細な access policy は deployment 側で管理されます。  
Use these as the public connection surface. Project-specific access policy still applies on the deployment side.

## リポジトリ構成 / Repository Layout

- [docs/tools.md](./docs/tools.md): tool 一覧と request/response の要約  
  tool catalog and request/response notes
- [docs/auth.md](./docs/auth.md): OAuth と security model  
  OAuth and security model
- [docs/openai-and-mcp.md](./docs/openai-and-mcp.md): OpenAI / MCP の関連情報  
  OpenAI and MCP integration notes with official links
- [plugin/.codex-plugin/plugin.json](./plugin/.codex-plugin/plugin.json): 公開 plugin manifest sample  
  public plugin manifest sample
- [plugin/.mcp.json](./plugin/.mcp.json): 公開 MCP client sample  
  public MCP client sample
- [plugin/config/default.json](./plugin/config/default.json): non-secret runtime sample  
  non-secret runtime sample

## 想定読者 / Who This Repo Is For

- 外部エージェント開発者 / external agent developers evaluating tool coverage
- MCP integration を組み込むチーム / teams integrating MCP tools into internal or hosted agents
- 公開 action surface をレビューしたい監査・評価者 / auditors reviewing the public action surface and security model

## あえて公開しないもの / What Is Intentionally Not Public Here

- Supabase 内部実装詳細 / Supabase internal implementation details
- private operation 専用の secret 名 / secret names used only for private operations
- signer private key の内部処理 / signer private key handling internals
- private infrastructure topology / private infrastructure topology

## OpenAI 公式情報 / OpenAI References

OpenAI 側の最新仕様は必ず公式 docs を参照してください。  
For current OpenAI agent and tool-calling behavior, use the official docs:

- Function calling: `https://platform.openai.com/docs/guides/function-calling`
- Using tools: `https://platform.openai.com/docs/guides/tools`
- Agents SDK: `https://platform.openai.com/docs/guides/agents-sdk/`
- Agent Builder: `https://platform.openai.com/docs/guides/agent-builder`

## 補足 / Notes

この repo は JPYC Manager MCP の public-facing documentation surface です。private implementation repo とは分けており、外部エージェントが公開 contract を読める一方で、運用上の private detail は出さない構成にしています。  
This repository is the public-facing documentation surface for the JPYC Manager MCP. It is separate from the private implementation repository so external agents can inspect the public contract without exposing private operational details.
