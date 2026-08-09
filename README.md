# dotfiles

Managed with GNU Stow.

## Linux packages
- niri
- quickshell
- foot
- fuzzel
- mako
- gamemode

## install stow (Nobara/Fedora)
```bash
sudo dnf install stow
```

## stow
```bash
cd ~/dotfiles
stow niri quickshell foot fuzzel mako gamemode
```

## unstow
```bash
cd ~/dotfiles
stow -D niri quickshell foot fuzzel mako gamemode
```

## restow
```bash
cd ~/dotfiles
stow -R niri quickshell foot fuzzel mako gamemode
```

## macOS

macOS packages live under `macos/` so they remain separate from the Linux
packages. The Homebrew manifest is intentionally curated rather than a dump of
everything installed on one machine.

### prerequisites

Install [Homebrew](https://brew.sh/), then install the selected applications,
CLI tools, fonts, and GNU Stow:

```bash
cd ~/dotfiles
brew bundle --file macos/Brewfile
```

The fonts used by the terminal profiles are JetBrains Mono and Symbols Nerd
Font Mono. Apple Color Emoji, Apple Symbols, Menlo, and SF Mono are macOS system
fallbacks.

### Stow packages

Each package is independent. Before stowing, back up or remove any existing
file at the package's destination; Stow stops rather than overwriting a
conflicting file.

```bash
cd ~/dotfiles
stow --dir macos --target "$HOME" wezterm
stow --dir macos --target "$HOME" tmux
stow --dir macos --target "$HOME" git
stow --dir macos --target "$HOME" mise
stow --dir macos --target "$HOME" nvim
stow --dir macos --target "$HOME" ghostty
```

These commands create links only for the named package and do not restow or
modify Linux packages. Remove packages independently with:

```bash
cd ~/dotfiles
stow --dir macos --target "$HOME" --delete wezterm
stow --dir macos --target "$HOME" --delete tmux
stow --dir macos --target "$HOME" --delete git
stow --dir macos --target "$HOME" --delete mise
stow --dir macos --target "$HOME" --delete nvim
stow --dir macos --target "$HOME" --delete ghostty
```

The Git package conflicts with an existing `~/.gitconfig`. It deliberately
contains no name, email, GitHub user, credential helper, or repository-specific
settings; configure identity and credentials locally after installation.

After stowing mise, activate it using mise's shell-specific instructions and
install the pinned tools:

```bash
mise install
```

The custom Neovim Python setup requires `ty` and `ruff`. If uv manages Astral
tools on your machine, install them with `uv tool install ty` and
`uv tool install ruff`. Enabled LazyVim extras may also use external tools when
their features are selected: Claude Code, Go, Rust plus `rust-analyzer`, and a
TypeScript runtime such as `tsx` or `ts-node`. These optional language and agent
toolchains are intentionally not forced by the curated Brewfile.

### tmux LaunchAgent

The LaunchAgent is a template rather than a Stow package. After installing tmux
and stowing its config, run the installer explicitly:

```bash
bash macos/scripts/install-tmux-launchagent.sh
```

The installer discovers `tmux`, renders home-relative paths, validates the
plist, and idempotently bootstraps and starts `local.tmux-server`. To remove it:

```bash
launchctl bootout "gui/$UID/local.tmux-server" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/local.tmux-server.plist"
```

### optional macOS defaults

`macos/scripts/defaults.sh` is **opinionated and opt-in**. It changes only the
audited keyboard repeat, Finder column-view, and Dock auto-hide/recent-apps
preferences, then restarts Finder and Dock. Stow and `brew bundle` never run it.

Review it first, then apply it explicitly:

```bash
bash macos/scripts/defaults.sh
```
