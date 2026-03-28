# OpenAI and MCP Notes

This repository documents a project-specific MCP surface. For current OpenAI platform behavior, rely on OpenAI's official documentation.

## Recommended OpenAI References

- Function calling: `https://platform.openai.com/docs/guides/function-calling`
- Using tools: `https://platform.openai.com/docs/guides/tools`
- Agents SDK: `https://platform.openai.com/docs/guides/agents-sdk/`
- Agent Builder: `https://platform.openai.com/docs/guides/agent-builder`

## How This Relates to OpenAI Tool Use

Typical OpenAI-based agent integrations will:

1. connect to the JPYC Manager MCP as an external tool source
2. let the model choose among wallet, transfer, and contract tools
3. require application-side approval or policy checks before executing state-changing calls
4. persist quote identifiers if a later execution step is possible

## Practical Mapping

- OpenAI tool calling decides when a tool should be invoked
- this MCP defines what wallet and contract operations are available
- your application still owns policy, approvals, and user experience

## What To Avoid

- do not hardcode secrets in plugin manifests
- do not assume transfer or contract writes are single-step actions
- do not skip quote validation for state-changing calls

## Public Repo Role

This repository is not a substitute for the OpenAI docs. It is the public, project-specific companion that explains:

- what the JPYC Manager MCP exposes
- how the OAuth-protected endpoint is structured
- what constraints external agents must respect
