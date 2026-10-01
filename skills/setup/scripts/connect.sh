#!/bin/sh
# Register the Spaces MCP server in the Codex config, which the ChatGPT desktop
# app (Work mode) and Codex both read. Read-only Spaces tools are pre-approved;
# tools that start, stop, or type into agents still ask. Refuses if already set.
# The new config is validated with Codex in a scratch copy before it replaces
# the real one, so a bad write can never break Codex.
set -eu
home="${CODEX_HOME:-$HOME/.codex}"
config="$home/config.toml"
cli="$HOME/.spaces/bin/spaces"
readonly_tools="spaces_project_list spaces_workspace_list spaces_terminal_list
  spaces_terminal_tail spaces_agent_list spaces_agent_status spaces_agent_brief_read
  spaces_device_list spaces_agent_subscribe spaces_agent_unsubscribe"

if [ ! -x "$cli" ]; then echo "Spaces CLI not found at $cli. Install and open Spaces first." >&2; exit 1; fi
if grep -qs '^\[mcp_servers\.spaces[].]' "$config"; then echo "Spaces is already registered in $config" >&2; exit 1; fi

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
[ -f "$config" ] && cp "$config" "$work/config.toml"
{
  printf '\n[mcp_servers.spaces]\ncommand = "%s"\nargs = ["mcp"]\n' "$cli"
  for t in $readonly_tools; do printf '\n[mcp_servers.spaces.tools.%s]\napproval_mode = "approve"\n' "$t"; done
} >> "$work/config.toml"

codex=$(command -v codex 2>/dev/null) || codex=/Applications/ChatGPT.app/Contents/Resources/codex-cli/bin/codex
if [ -x "$codex" ]; then
  if ! CODEX_HOME="$work" "$codex" mcp list 2>&1 | grep -q '^spaces '; then
    echo "Codex rejected the new config; $config is unchanged." >&2; exit 1
  fi
fi

mkdir -p "$home"
cp "$work/config.toml" "$config"
echo "Registered Spaces in $config. Start a new chat to load its tools."
