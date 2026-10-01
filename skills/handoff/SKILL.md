---
name: handoff
description: Use when the user wants work from this conversation continued by a coding agent (Claude Code, Codex, or OpenCode) in a fresh session - "start this in Claude Code", "have Codex build it", "hand this off", "continue this in a new session". Writes a handoff document from the conversation, starts the agent in a Spaces workspace on its own branch, and gives it the document. Also propose it when stale context is degrading the current session, and confirm before running it. Do not use for a new task that does not depend on this conversation (use dispatch), or for work the user wants done here.
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work, then use the Spaces MCP tools to spawn that agent and point it at the document.

If the conversation holds no task or context worth continuing, say so and stop - do not start an agent.

## 1. Write the handoff document

Save it to the temporary directory of the user's OS - not the current workspace. If you cannot write files (for example, in a ChatGPT chat), keep the document in hand and send its full text as the prompt in step 2 instead of a path.

- Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.
- Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.
- Redact any sensitive information, such as API keys, passwords, or personally identifiable information.
- If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

## 2. Spawn the successor agent via Spaces

Requires the Spaces MCP server (`spaces` tools). If the tools are unavailable, stop after step 1, give the user the document path (or its text), and use the setup skill.

Where the successor runs: if you are working inside a Spaces workspace, spawn it there. Otherwise (for example, in a ChatGPT chat), use the project the user named - ask if they named none, never pick one yourself - then create a fresh workspace for the work with `spaces_workspace_create` (`project`, a short kebab-case `branch`) and `spaces_workspace_start`, and spawn in it.

1. Call `spaces_agent_spawn` with the command for the agent CLI the user asked for, else the same agent CLI you are running as (default to `claude` if unsure), plus `workspace` when you created one. Spawn delivers no prompt; it only starts the agent and returns an `agentSpawn` object with `terminalSessionID`. Spawn once: if it times out or reports the agent not ready, read that session with `spaces_terminal_tail` and handle the dialog there - never spawn a second agent.
2. Send the handoff prompt with `spaces_terminal_send`:
   - `session`: `agentSpawn.terminalSessionID`
   - `text`: a short prompt such as `Read <absolute path to handoff doc> and continue the work described there.`, or the full handoff document when there is no file
   - `submit`: true (one call is enough; submit-safety is server-side)
3. Confirm the agent picked the work up: poll `spaces_agent_status` or `spaces_terminal_tail` for the session, and report success only once the tail shows it working on the handoff. If a folder trust or onboarding dialog appears, answer it with `spaces_terminal_send` (an empty `text` with `submit: true` presses Enter alone) and re-send the handoff if the dialog swallowed it. Never grant trust to hooks or tools that run outside the sandbox - pick the option that continues without trusting and tell the user.
4. If `agentSpawn.subscribed` is false, call `spaces_agent_subscribe` once the agent has signaled so blocked/done notifications flow back.

Finish by telling the user the handoff document path (if you saved one) and the `agentSpawn.open` deep link to the new terminal.
