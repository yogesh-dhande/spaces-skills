#!/bin/sh
# Install the latest Spaces release into /Applications (or $SPACES_INSTALL_DIR),
# then open it. Downloads the DMG from GitHub, checks it is notarized and signed
# by the Spaces developer, and refuses to replace an existing install.
set -eu
team=BEMDA62NB6
dest=${SPACES_INSTALL_DIR:-/Applications}
app="$dest/Spaces.app"
if [ -e "$app" ]; then echo "Spaces is already installed at $app" >&2; exit 1; fi

work=$(mktemp -d); mnt="$work/mnt"; mkdir "$mnt"
trap 'hdiutil detach -quiet "$mnt" 2>/dev/null || true; rm -rf "$work"' EXIT

url=$(curl -fsSL https://api.github.com/repos/yogesh-dhande/spaces/releases/latest |
  sed -n 's/.*"browser_download_url": *"\([^"]*\.dmg\)".*/\1/p' | head -1)
if [ -z "$url" ]; then echo "No DMG in the latest Spaces release" >&2; exit 1; fi
echo "Downloading $url"
curl -fsSL -o "$work/Spaces.dmg" "$url"
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$mnt" "$work/Spaces.dmg"

# Verify a clean copy: the DMG's bundle carries Finder info that --strict rejects.
ditto --noextattr --norsrc "$mnt/Spaces.app" "$work/Spaces.app"
codesign --verify --deep --strict "$work/Spaces.app"
codesign -dv "$work/Spaces.app" 2>&1 | grep -qx "TeamIdentifier=$team" ||
  { echo "Spaces.app is not signed by the Spaces developer ($team)" >&2; exit 1; }
spctl --assess --type execute "$work/Spaces.app"

ditto "$work/Spaces.app" "$app"
echo "Installed $app"
[ "${SPACES_INSTALL_NO_OPEN:-}" = 1 ] || open "$app"
