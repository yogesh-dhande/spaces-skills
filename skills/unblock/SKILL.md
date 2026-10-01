---
name: unblock
description: Use when the user wants stuck or waiting coding agents moving again - "unblock my agents", "Claude Code is waiting on a trust prompt", "clear the pending dialogs" - or when a status check found blocked agents and the user wants them handled. Answers mechanical prompts such as folder trust and press-Enter, and brings real questions back to the user word for word. Do not use only to check status (use standup).
---

Get blocked agents moving again. Requires the Spaces MCP server (`spaces` tools); if they are not available, use the setup skill instead. Pairs well with `/loop` for babysitting a fleet.

## 1. Find blocked agents

`spaces_device_list`, then `spaces_agent_list` for this machine and each reachable device. If the user limited the scope (a project, workspace, or device), consider only agents inside it and leave every other agent untouched. For every agent that is blocked or waiting, read `spaces_terminal_tail` (`lines`: 40) to see the exact prompt on screen.

## 2. Decide: answer or escalate

Auto-answer ONLY mechanical prompts where every sane user gives the same answer:

- first-run trust / onboarding / telemetry dialogs
- "press Enter to continue" and pager prompts
- resuming after a benign informational notice

NEVER auto-answer - always surface to the user instead:

- destructive or hard-to-reverse confirmations (delete, overwrite, force-push, publish, deploy)
- credential, auth, or payment prompts
- requests to trust hooks, tools, or anything that runs outside the sandbox
- design decisions, plan approvals, or any open question the agent asked
- anything ambiguous - when unsure, escalate

## 3. Answer mechanical prompts

Use `spaces_terminal_send` on the agent's session:

- empty `text` with `submit: true` presses Enter alone
- `text` plus `submit: true` types and submits a line
- for TUI menus that need arrow keys, send `bytes` (e.g. `27, 91, 66` is Down arrow), then an empty submit

Re-read `spaces_terminal_tail` after each answer to confirm the agent resumed, and `spaces_agent_subscribe` to its session if not already watching.

## 4. Report

List what was unblocked and how. For every escalated agent, quote the question or dialog verbatim with its `spaces://terminal` deep link so the user can answer directly. Never answer a judgment call on the user's behalf, and never relay an answer the user has not actually given.
