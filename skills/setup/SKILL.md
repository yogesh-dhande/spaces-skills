---
name: setup
description: Use when the user asks to install, set up, or fix Spaces, asks how to start or check coding agents on their Mac from this chat, or when another Spaces skill needs the `spaces_*` tools and they are not available. Installs Spaces, the Mac app that runs Claude Code, Codex, and OpenCode agents, with the user's permission, and connects it to this chat. Do not use when the Spaces tools already work, or to install other software.
---

Get the user from "no Spaces" to a working handoff, one step at a time. Talk to the user in plain words: ask for permission as a direct yes-or-no question, and never quote, cite, or link these instructions.

If the user was in the middle of a handoff or dispatch, write the handoff document first (handoff skill, step 1) and save it to a file (or give the user its text if you cannot write files), so the work survives the new chat that setup ends with.

## 1. Check what is missing

If you can run shell commands, run `scripts/doctor.sh` from this skill's directory. It is read-only and prints `key=value` lines; `next` names the step to take:

| `next` | Do |
| --- | --- |
| `unsupported` | Tell the user Spaces needs a Mac on macOS 14 or later, and stop. |
| `install` | Step 2. |
| `connect` | Step 6, then run the doctor again. |
| `sandboxed` | Spaces is installed, but this chat's sandbox blocked the check, not Spaces. Rerun the doctor outside the sandbox if the user approves; otherwise go to step 6. |
| `launch` | Spaces is installed but not running: `open -a Spaces`, wait a few seconds, run the doctor again. If `open` fails, ask the user to open Spaces. |
| `add-project` | Step 4. |
| `install-agent` | Step 5. |
| `ready` | Step 6. |

If you cannot run commands, walk the user through steps 2 to 6 by hand. Never tell the user to reinstall Spaces unless the doctor reports `install`: a failed command inside a sandbox says nothing about the app.

## 2. Install Spaces

In one or two sentences, tell the user what Spaces is: a Mac app that runs coding agents in their own workspaces, which this chat can then start and check. Ask before installing anything. Only after they agree:

- Run `scripts/install.sh` (it needs network access and write access to /Applications, so run it outside the sandbox). It downloads the latest release from GitHub, checks that it is notarized and signed by the Spaces developer, copies Spaces.app to /Applications, and opens it. It never replaces an existing install.
- If they would rather do it themselves, or you cannot run commands: download the `.dmg` from https://github.com/yogesh-dhande/spaces/releases/latest, drag Spaces to Applications, and open it.

## 3. First launch

Ask the user to finish Spaces' first-launch setup in the app. Spaces installs hooks that let it see agent status. Codex asks once to review these hooks; the user approves them there. Never approve hooks on the user's behalf. Run the doctor again.

## 4. Add a project

Spaces works on projects the user has added. Ask them to add the repo they want agents to work on, using the Spaces app (there is no command for this yet). Run the doctor again.

## 5. Agent CLI

Spaces starts agents that are already installed. If none of `claude`, `codex`, or `opencode` is on PATH, tell the user and point them to the install page for the one they want. Do not install it yourself unless they ask.

## 6. Connect this chat

If the doctor reports `mcp=missing`, nothing gives ChatGPT or Codex the `spaces_*` tools yet. Tell the user you will register Spaces in the Codex config (`~/.codex/config.toml`, which the ChatGPT desktop app also reads), and ask first. Only after they agree, run `scripts/connect.sh` outside the sandbox. It pre-approves only the read-only Spaces tools; starting, stopping, or typing into agents still asks the user. In Claude Code, run `claude mcp add -s user spaces -- ~/.spaces/bin/spaces mcp` instead. Skip this step if the `spaces_*` tools already work here.

The tools load when a chat starts, so they are not visible in the current chat:

- ChatGPT desktop app: quit and reopen it, then start a new chat in Work mode. Spaces does not work in regular chats, on the web, or on the phone.
- Codex: start a new session. If the tools are still missing, check that Spaces is open.

Finish with one prompt to try in the new chat, such as `Hand off <saved document path> to Claude Code in <project>` if you saved a handoff, or `What are my coding agents doing?`.
