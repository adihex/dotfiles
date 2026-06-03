#!/usr/bin/env bash
set -euo pipefail

sudo dnf install -y stow niri quickshell foot fuzzel mako swaybg gammastep

cd "$HOME/dotfiles"
stow -R niri quickshell foot fuzzel mako gammastep

echo
echo "Installed packages and restowed dotfiles."
echo "Log into a Niri session to test."
