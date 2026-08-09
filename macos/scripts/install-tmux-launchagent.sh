#!/bin/bash
set -euo pipefail

label="local.tmux-server"
domain="gui/$UID"
script_dir="$(cd "$(dirname "$0")" && pwd)"
template="$script_dir/../tmux-launchagent/$label.plist.in"
destination="$HOME/Library/LaunchAgents/$label.plist"
tmux_bin="$(command -v tmux || true)"

if [[ -z "$tmux_bin" ]]; then
  echo "tmux is not installed or not on PATH" >&2
  exit 1
fi

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
rendered="$(mktemp "${TMPDIR:-/tmp}/$label.XXXXXX")"
trap 'rm -f "$rendered"' EXIT

cp "$template" "$rendered"
plutil -remove ProgramArguments.4 "$rendered"
plutil -insert ProgramArguments.4 -string "$tmux_bin" "$rendered"
plutil -replace EnvironmentVariables.PATH -string \
  "$HOME/.local/share/mise/shims:$(dirname "$tmux_bin"):/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  "$rendered"
plutil -replace StandardOutPath -string "$HOME/Library/Logs/tmux-server.log" "$rendered"
plutil -replace StandardErrorPath -string "$HOME/Library/Logs/tmux-server.err.log" "$rendered"
plutil -lint "$rendered" >/dev/null

loaded=false
if launchctl print "$domain/$label" >/dev/null 2>&1; then
  loaded=true
fi

if [[ ! -f "$destination" ]] || ! cmp -s "$rendered" "$destination"; then
  if [[ "$loaded" == true ]]; then
    launchctl bootout "$domain/$label"
    loaded=false
  fi
  install -m 0644 "$rendered" "$destination"
fi

if [[ "$loaded" == false ]]; then
  launchctl bootstrap "$domain" "$destination"
fi
launchctl kickstart -k "$domain/$label"

echo "Installed and started $destination"
