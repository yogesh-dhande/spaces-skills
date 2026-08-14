---
name: dispatch
description: Start work on a task in a fresh Spaces workspace - create a worktree workspace, spawn a coding agent in it, and send it the task prompt. Use when the user asks to dispatch, delegate, kick off, or parallelize a task in its own workspace, branch, or worktree, or on another device, instead of doing it in the current session. Do not use for work the user expects done here, in this conversation.
argument-hint: "The task to dispatch (and optionally project, branch, or device)"
---

Dispatch a task to a new agent in its own Spaces workspace. Requires the Spaces MCP server (`spaces` tools).

## 1. Resolve the target

- Project: call `spaces_project_list` and pick the project matching the current directory, or the one the user named. If ambiguous, ask.
- Device: default to this machine. If the user named a paired device, resolve it with `spaces_device_list`.
- Branch: derive a short kebab-case branch name from the task unless the user gave one. Set `existingBranch: true` only when the user asked to reuse a branch.

## 2. Create and start the workspace

1. `spaces_workspace_create` with `project` and `branch` (plus `baseBranch` or `device` when given). For a git project this creates a worktree on the new branch and runs project setup. The workspace is created but NOT started.
2. `spaces_workspace_start` with the returned workspace ID.

## 3. Spawn the agent and hand it the task

1. `spaces_agent_spawn` with the agent CLI command (default `claude`) and the new `workspace` ID. `workspace` is required when spawning on a paired device. Spawn delivers no prompt.
2. Send the task with `spaces_terminal_send`: `session` = `agentSpawn.terminalSessionID`, `text` = the task prompt, `submit: true`. Write the prompt so it stands alone - the new agent has none of this conversation's context.
3. Confirm pickup by polling `spaces_agent_status` or `spaces_terminal_tail`. If a first-run trust/onboarding dialog appears, answer it with `spaces_terminal_send` (empty `text` with `submit: true` presses Enter alone), then re-send the task if it was swallowed by the dialog.
4. If `agentSpawn.subscribed` is false, call `spaces_agent_subscribe` after the agent emits its first hook signal (it fails before then - retry) so blocked/done notifications flow back.

Finish by telling the user the workspace branch and directory and the `agentSpawn.open` deep link to the new terminal.
