#!/bin/sh
# Report what Spaces setup still needs on this machine, one key=value per line.
# Read-only. The last line, next=, names the single next step.
# SPACES_APP_PATHS / SPACES_CLI_PATHS (colon-separated) replace the search lists.

first_match() {
  test_flag=$1; old_ifs=$IFS; IFS=:
  for p in $2; do
    if [ -n "$p" ] && [ "$test_flag" "$p" ]; then IFS=$old_ifs; echo "$p"; return 0; fi
  done
  IFS=$old_ifs; return 1
}

macos=$(sw_vers -productVersion 2>/dev/null) || macos=none
major=${macos%%.*}
if [ "$macos" != none ] && [ "$major" -ge 14 ] 2>/dev/null; then supported=yes; else supported=no; fi
app=$(first_match -d "${SPACES_APP_PATHS:-/Applications/Spaces.app:$HOME/Applications/Spaces.app}") || app=missing
cli=$(first_match -x "${SPACES_CLI_PATHS:-$HOME/.spaces/bin/spaces:/usr/local/bin/spaces:$(command -v spaces 2>/dev/null)}") || cli=missing

# daemon=blocked means a sandbox around this shell refused the connection;
# Spaces itself may be fine.
daemon=unreachable; projects=unknown
if [ "$cli" != missing ]; then
  if list=$("$cli" project list 2>&1); then
    daemon=running
    projects=$(printf '%s\n' "$list" | awk -F'\t' '$2 ~ /^name=/ && $2 != "name=~" {n++} END {print n+0}')
  else
    case $list in *"not permitted"*) daemon=blocked ;; esac
  fi
fi

# mcp=plugin: this plugin bundles the server. mcp=config: the Codex config
# (also read by the ChatGPT desktop app) registers it. mcp=missing: neither.
plugin_root="$(cd "$(dirname "$0")/../../.." && pwd)"
config="${CODEX_HOME:-$HOME/.codex}/config.toml"
if grep -qs '"spaces"' "$plugin_root/.mcp.json"; then mcp=plugin
elif grep -qs '^\[mcp_servers\.spaces[].]' "$config"; then mcp=config
else mcp=missing
fi

agents=""
for a in claude codex opencode; do
  command -v "$a" >/dev/null 2>&1 && agents="${agents:+$agents,}$a"
done

if [ "$supported" = no ]; then next=unsupported
elif [ "$app" = missing ] && [ "$cli" = missing ]; then next=install
elif [ "$mcp" = missing ]; then next=connect
elif [ "$daemon" = blocked ]; then next=sandboxed
elif [ "$daemon" = unreachable ]; then next=launch
elif [ "$projects" = 0 ]; then next=add-project
elif [ -z "$agents" ]; then next=install-agent
else next=ready
fi

printf 'macos=%s\nmacos_supported=%s\napp=%s\ncli=%s\nmcp=%s\ndaemon=%s\nprojects=%s\nagents=%s\nnext=%s\n' \
  "$macos" "$supported" "$app" "$cli" "$mcp" "$daemon" "$projects" "${agents:-none}" "$next"
