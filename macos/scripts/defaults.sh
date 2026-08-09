#!/bin/bash
set -euo pipefail

# Opinionated and opt-in. This script changes only the explicitly audited keys.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "Applied keyboard, Finder, and Dock preferences"
