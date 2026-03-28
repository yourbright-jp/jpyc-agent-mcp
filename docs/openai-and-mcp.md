# OpenAI and MCP Notes / OpenAI と MCP の補足

この repository は project-specific な MCP surface を説明するものです。OpenAI platform 自体の最新挙動は、必ず OpenAI 公式 docs を参照してください。  
This repository documents a project-specific MCP surface. For current OpenAI platform behavior, rely on OpenAI's official documentation.

## 参照すべき OpenAI 公式 docs / Recommended OpenAI References

- Function calling: `https://platform.openai.com/docs/guides/function-calling`
- Using tools: `https://platform.openai.com/docs/guides/tools`
- Agents SDK: `https://platform.openai.com/docs/guides/agents-sdk/`
- Agent Builder: `https://platform.openai.com/docs/guides/agent-builder`

## この MCP と OpenAI tool use の関係 / How This Relates to OpenAI Tool Use

OpenAI ベースの agent integration では、通常は次の流れになります。  
Typical OpenAI-based agent integrations will:

1. JPYC Manager MCP を external tool source として接続する  
   connect to the JPYC Manager MCP as an external tool source
2. model が wallet / transfer / contract tool から選ぶ  
   let the model choose among wallet, transfer, and contract tools
3. state-changing action の前に app 側で approval や policy check を入れる  
   require application-side approval or policy checks before executing state-changing calls
4. 後続実行のために `quote_id` を保持する  
   persist quote identifiers if a later execution step is possible

## 実務上のマッピング / Practical Mapping

- OpenAI tool calling は「どの tool を呼ぶか」を決める  
  OpenAI tool calling decides when a tool should be invoked
- この MCP は「どの wallet / contract operation が使えるか」を定義する  
  this MCP defines what wallet and contract operations are available
- 実際の policy、approval、UX はアプリ側の責任  
  your application still owns policy, approvals, and user experience

## 避けるべきこと / What To Avoid

- plugin manifest に secret を埋め込まない  
  do not hardcode secrets in plugin manifests
- transfer や contract write を single-step action だと思わない  
  do not assume transfer or contract writes are single-step actions
- state-changing call で quote validation を飛ばさない  
  do not skip quote validation for state-changing calls

## この public repo の役割 / Public Repo Role

この repo は OpenAI docs の代替ではありません。JPYC Manager MCP について、次を project-specific に説明する companion repository です。  
This repository is not a substitute for the OpenAI docs. It is the public, project-specific companion that explains:

- どの tool が公開されているか  
  what the JPYC Manager MCP exposes
- OAuth-protected endpoint がどう構成されているか  
  how the OAuth-protected endpoint is structured
- 外部エージェントが守るべき制約は何か  
  what constraints external agents must respect
