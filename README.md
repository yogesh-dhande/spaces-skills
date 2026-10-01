# Spaces Skills

Agent skills for working with [Spaces](https://github.com/yogesh-dhande/spaces), installable with the [skills CLI](https://github.com/vercel-labs/skills).

## Install

```sh
npx skills add yogesh-dhande/spaces-skills
```

### As a ChatGPT / Codex plugin

This repo is also a skills-only plugin. It works on the Mac where Spaces is installed, in the ChatGPT desktop app (Work mode) and Codex, not on the web or phone.

```sh
codex plugin marketplace add yogesh-dhande/spaces-skills
codex plugin add spaces@spaces
```

Then restart the ChatGPT desktop app and ask it to set up Spaces. The setup skill installs Spaces if needed and, with your permission, registers the Spaces MCP server (`spaces mcp`) in `~/.codex/config.toml`, which both ChatGPT and Codex read.

## Skills

- **handoff** - Compact the current conversation into a handoff document, then spawn a fresh agent in a Spaces terminal (via the Spaces MCP server) and send it the handoff prompt so it starts working immediately.
- **dispatch** - Start work on a task in a fresh Spaces workspace: create a worktree workspace, spawn a coding agent in it, and send it the task prompt.
- **standup** - Survey every coding agent running across Spaces devices and summarize who is working, blocked, done, or waiting on input.
- **unblock** - Find blocked agents, answer the mechanical prompts holding them up (trust dialogs, press-Enter), and surface real questions to the user.
- **setup** - Check what Spaces setup is missing (`scripts/doctor.sh`), install the signed app with permission (`scripts/install.sh`), and connect the chat to the Spaces tools.
