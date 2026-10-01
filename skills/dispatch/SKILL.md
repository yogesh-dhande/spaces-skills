---
name: dispatch
description: Use when the user wants a new, self-contained task run by a separate coding agent in its own Spaces workspace, branch, or worktree, or on another device - "kick off an agent to add tests", "run these three tasks in parallel", "have Claude Code fix the login bug on a new branch". Creates the workspace, starts the agent, and sends it the task. Do not use when the user wants the plan or work from this conversation continued elsewhere, such as "start this" or "build it" (use handoff), or for work the user expects done here.
argument-hint: "The task to dispatch (and optionally project, branch, or device)"
---

Dispatch a task to a new agent in its own Spaces workspace. Requires the Spaces MCP server (`spaces` tools). If they are not available, use the setup skill instead.

## 1. Resolve the target

- Project: call `spaces_project_list` and use the project the user named. If they named none, use the project containing the current directory, but only when you are working inside one. Otherwise ask which project - never pick one yourself.
- Device: default to this machine. If the user named a paired device, resolve it with `spaces_device_list`.
- Branch: derive a short kebab-case branch name from the task unless the user gave one. Set `existingBranch: true` only when the user asked to reuse a branch.

## 2. Create and start the workspace

1. `spaces_workspace_create` with `project` and `branch` (plus `baseBranch` or `device` when given). For a git project this creates a worktree on the new branch and runs project setup. The workspace is created but NOT started.
2. `spaces_workspace_start` with the returned workspace ID.

## 3. Spawn the agent and hand it the task

1. `spaces_agent_spawn` with the agent CLI command (default `claude`) and the new `workspace` ID. `workspace` is required when spawning on a paired device. Spawn delivers no prompt. Spawn once per task: if it times out or reports the agent not ready, a dialog is usually blocking it - read that session with `spaces_terminal_tail` and handle the dialog there (step 3). Never spawn a second agent for the same task.
2. Send the task with `spaces_terminal_send`: `session` = `agentSpawn.terminalSessionID`, `text` = the task prompt, `submit: true`. Write the prompt so it stands alone - the new agent has none of this conversation's context.
3. Handle startup dialogs, read with `spaces_terminal_tail`:
   - Folder trust or onboarding for the new workspace: answer it with `spaces_terminal_send` (empty `text` with `submit: true` presses Enter alone).
   - A request to trust hooks, tools, or anything that runs outside the sandbox: never grant it. Pick the option that continues without trusting (arrow keys via `bytes`, e.g. `27, 91, 66` is Down, then an empty submit), and tell the user it was skipped.
   - Re-send the task if a dialog swallowed it.
4. Confirm pickup: report success only after `spaces_terminal_tail` shows the agent working on the task - not a dialog, not an empty prompt. If it is still stuck, say exactly what is on screen.
5. If `agentSpawn.subscribed` is false, call `spaces_agent_subscribe` after the agent emits its first hook signal (it fails before then - retry) so blocked/done notifications flow back.

Finish by telling the user the workspace branch and directory and the `agentSpawn.open` deep link to the new terminal.
