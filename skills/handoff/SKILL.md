---
name: handoff
description: Compact the current conversation into a handoff document, then spawn a fresh agent in a Spaces terminal and hand the work off to it.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work, then use the Spaces MCP tools to spawn that agent and point it at the document.

## 1. Write the handoff document

Save it to the temporary directory of the user's OS - not the current workspace.

- Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.
- Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.
- Redact any sensitive information, such as API keys, passwords, or personally identifiable information.
- If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

## 2. Spawn the successor agent via Spaces

Requires the Spaces MCP server (`spaces` tools). If the tools are unavailable, stop after step 1 and give the user the document path.

1. Call `spaces_agent_spawn` with the command for the same agent CLI you are running as (default to `claude` if unsure). Spawn delivers no prompt; it only starts the agent and returns an `agentSpawn` object with `terminalSessionID`.
2. Send the handoff prompt with `spaces_terminal_send`:
   - `session`: `agentSpawn.terminalSessionID`
   - `text`: a short prompt such as `Read <absolute path to handoff doc> and continue the work described there.`
   - `submit`: true (one call is enough; submit-safety is server-side)
3. Confirm the agent picked the work up: poll `spaces_agent_status` or `spaces_terminal_tail` for the session. If a first-run trust/onboarding dialog appears in the tail, answer it with `spaces_terminal_send` (an empty `text` with `submit: true` presses Enter alone).
4. If `agentSpawn.subscribed` is false, call `spaces_agent_subscribe` once the agent has signaled so blocked/done notifications flow back.

Finish by telling the user the handoff document path and the `agentSpawn.open` deep link to the new terminal.
