# Niri + Quickshell Cheatsheet

## Basics
| Key | Action |
|-----|--------|
| `Mod+Return` | Open terminal (foot) |
| `Mod+D` | App launcher (fuzzel) |
| `Mod+Q` | Close window |
| `Mod+O` | Overview (zoom-out workspace view) |
| `Mod+Shift+E` | Quit Niri (back to GDM) |
| `Mod+Shift+Slash` | Hotkey overlay help |

## Navigation
| Key | Action |
|-----|--------|
| `Mod+←` / `Mod+→` | Focus left/right column |
| `Mod+↑` / `Mod+↓` | Focus window up/down |
| `Mod+Ctrl+←/→` | Move column left/right |
| `Mod+Ctrl+↑/↓` | Move window up/down |
| `Mod+PageUp` / `Mod+PageDown` | Switch workspace up/down |
| `Mod+WheelUp` / `Mod+WheelDown` | Scroll workspaces |

## System
| Key | Action |
|-----|--------|
| `Mod+Shift+P` | Power off monitors |
| `Mod+Shift+L` | Lock screen (swaylock) |
| `Mod+Shift+T` | Toggle night mode (gammastep) |
| `Print` | Screenshot (full) |
| `Shift+Print` | Screenshot (current screen) |

## Workspace
| Key | Action |
|-----|--------|
| `Mod+Ctrl+PageUp/Down` | Move column to workspace up/down |

## Media keys (passthrough)
| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute toggle |
| `XF86AudioPlay` | Play/pause |

## Dotfile management
| Command | What it does |
|---------|-------------|
| `cd ~/dotfiles && stow -R niri` | Restow niri after editing config |
| `~/dotfiles/scripts/wallpaper` | Cycle to random wallpaper |
| `~/dotfiles/scripts/wallpaper ~/Pics/cat.png` | Set specific wallpaper |
| `~/dotfiles/scripts/stow-wayland.sh` | Restow all packages |
| `~/dotfiles/scripts/generate-wallpapers.py` | Regenerate all 5 wallpapers |

## Quickshell bar layout
```
┌─ Niri │ eDP-1 ───────── ☕ Mon Jun 2 ───────── 🟢 System │ 09:37 ─┐
└────────────────────────────────────────────────────────────────────┘
```

## Configs location
```
~/dotfiles/
├── niri/.config/niri/config.kdl        # WM config
├── quickshell/.config/quickshell/      # Bar & widgets
├── foot/.config/foot/foot.ini          # Terminal config
├── fuzzel/.config/fuzzel/fuzzel.ini    # App launcher
├── mako/.config/mako/config            # Notifications
├── gammastep/.config/gammastep/config.ini  # Night mode / blue-light filter
├── wallpapers/                         # Wallpaper images
└── scripts/                            # Helper scripts
```

## Quick fixes
| Problem | Fix |
|---------|-----|
| Bar not showing | `pkill qs && qs -c ~/.config/quickshell &` |
| Wallpaper not loaded | `~/dotfiles/scripts/wallpaper` |
| Config changes not applied | `cd ~/dotfiles && stow -R niri quickshell foot fuzzel mako` then reload niri: `niri msg action quit` (or just re-login) |
| Hot reload quickshell | Just save the QML file — quickshell reloads automatically |

## Font
| Component | Font |
|-----------|------|
| System default | JetBrainsMono Nerd Font (via fontconfig) |
| Terminal (foot) | JetBrainsMono Nerd Font 11pt |
| Launcher (fuzzel) | JetBrainsMono Nerd Font 11pt |
| Notifications (mako) | JetBrainsMono Nerd Font 10pt |
| Bar (quickshell) | JetBrainsMono Nerd Font |

## Power menu (rofi)
| Key | Action |
|-----|--------|
| `Mod+Shift+E` | Open rofi power menu |
| `Ctrl+Alt+Delete` | Same power menu |
| `Mod+Shift+Ctrl+E` | Force quit Niri (bypass menu) |
