---
name: standup
description: Use when the user asks what their coding agents are doing, whether an agent is done, stuck, or waiting on them, or wants a status roll-up of agents across Spaces devices. Read-only - it summarizes who is working, blocked, done, or waiting on input. Do not use for CI builds, deploys, or other jobs that are not coding agents, or to answer a blocked agent (use unblock).
---

Give the user a status roll-up of their agents. Read-only: never send input to a terminal from this skill.

Requires the Spaces MCP server (`spaces` tools). If they are not available, use the setup skill instead.

## Gather

1. `spaces_device_list` to enumerate paired devices.
2. `spaces_agent_list` for this machine and for each reachable paired device (pass `device`).
3. For any agent whose status or note leaves its situation unclear - especially blocked ones - read `spaces_terminal_tail` (`lines`: 30-40) on its session to see what it is actually doing or asking. Skip the tail for agents whose list row already tells the story.

## Report

Order by urgency: agents needing attention first (blocked, waiting on a dialog or question), then actively working, then done/exited.

For each agent give: label, project/workspace and branch, device (when not this machine), one line on what it is doing or stuck on (from its note or tail), and its `spaces://terminal` deep link. For blocked agents, quote the actual question or dialog from the tail so the user can decide without opening the terminal.

Close with a one-line headline: how many working, blocked, and done. If nothing is running anywhere, say exactly that.
