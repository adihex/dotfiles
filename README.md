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

## macOS WezTerm

The macOS WezTerm configuration is kept under `macos/wezterm` so it remains
separate from the Linux packages.

### prerequisites

- [WezTerm](https://wezterm.org/)
- [GNU Stow](https://www.gnu.org/software/stow/) (`brew install stow`)
- JetBrains Mono and Symbols Nerd Font Mono for the intended font rendering

Apple Color Emoji, Apple Symbols, and Menlo are macOS system fallbacks.

### install

Back up or remove an existing `~/.wezterm.lua` first; Stow will stop rather than
overwrite a conflicting file.

```bash
cd ~/dotfiles
stow --dir macos --target "$HOME" wezterm
```

This creates only `~/.wezterm.lua` and does not restow or modify any Linux
package. To remove the symlink:

```bash
cd ~/dotfiles
stow --dir macos --target "$HOME" --delete wezterm
```
