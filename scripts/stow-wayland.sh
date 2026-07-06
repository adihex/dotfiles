#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/dotfiles"
stow -R niri quickshell foot fuzzel mako bin

echo "Restowed: niri quickshell foot fuzzel mako bin"
