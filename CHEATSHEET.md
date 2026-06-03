# Niri + Quickshell Cheatsheet

## Apps & Launcher
| Key | Action |
|-----|--------|
| `Mod+Return` | Open terminal (foot) |
| `Mod+D` | App launcher (fuzzel) |
| `Mod+V` | Clipboard history picker (cliphist + fuzzel) |
| `Mod+Q` | Close window |
| `Mod+O` | Overview (zoom-out workspace view) |
| `Mod+Shift+Slash` | Hotkey overlay help |

## Navigation (Vim-style HJKL)
| Key | Action |
|-----|--------|
| `Mod+H` / `Mod+←` | Focus left column |
| `Mod+L` / `Mod+→` | Focus right column |
| `Mod+K` / `Mod+↑` | Focus window up |
| `Mod+J` / `Mod+↓` | Focus window down |
| `Mod+Ctrl+H` / `Mod+Ctrl+←` | Move column left |
| `Mod+Ctrl+L` / `Mod+Ctrl+→` | Move column right |
| `Mod+Ctrl+K` / `Mod+Ctrl+↑` | Move window up |
| `Mod+Ctrl+J` / `Mod+Ctrl+↓` | Move window down |
| `Mod+PageUp` / `Mod+PageDown` | Switch workspace up/down |
| `Mod+WheelUp` / `Mod+WheelDown` | Scroll workspaces |

## Monitors
| Key | Action |
|-----|--------|
| `Mod+Shift+←/↑/↓/→` | Focus monitor in direction |
| `Mod+Shift+Ctrl+←/↑/↓/→` | Move column to monitor |

## Workspaces
| Key | Action |
|-----|--------|
| `Mod+1` … `Mod+9` | Jump to workspace 1–9 |
| `Mod+Ctrl+1` … `Mod+Ctrl+9` | Move column to workspace 1–9 |
| `Mod+Ctrl+PageUp` / `Mod+Ctrl+PageDown` | Move column to workspace up/down |

## Column / Window
| Key | Action |
|-----|--------|
| `Mod+[` / `Mod+]` | Consume or expel window left/right |

## Layout
| Key | Action |
|-----|--------|
| `Mod+F` | Maximize column (toggle) |
| `Mod+Shift+F` | Fullscreen window |
| `Mod+Shift+Space` | Toggle floating window |
| `Mod+R` | Cycle preset column widths |

## System
| Key | Action |
|-----|--------|
| `Mod+Shift+E` | Power menu (fuzzel: Lock / Logout / Suspend / Reboot / Shutdown) |
| `Ctrl+Alt+Delete` | Power menu (same as above) |
| `Mod+Shift+Ctrl+E` | Force quit Niri (bypass menu) |
| `Mod+Shift+C` | Reload Niri config |
| `Mod+Shift+P` | Power off monitors |
| `Mod+Shift+L` | Lock screen (swaylock) |
| `Mod+Shift+T` | Toggle night mode (gammastep) |

## Screenshots
| Key | Action |
|-----|--------|
| `Print` | Screenshot (interactive) |
| `Shift+Print` | Screenshot active screen |

## Media keys
| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume −5% |
| `XF86AudioMute` | Mute toggle |
| `XF86AudioMicMute` | Mic mute toggle |
| `XF86AudioPlay` | Play / pause (playerctl) |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `XF86MonBrightnessUp` | Brightness +5% |
| `XF86MonBrightnessDown` | Brightness −5% |

## Bar interactions (quickshell)
| Widget | Left-click | Middle-click | Scroll | Right-click |
|--------|-----------|-------------|--------|------------|
| Network | Open `nm-connection-editor` | — | — | — |
| Brightness | — | — | ±5% | — |
| Volume | Open `pavucontrol` | Mute toggle | ±5% | — |
| Clock | — | — | — | — |
| Power | Open powermenu (fuzzel) | — | — | — |

## Dotfile management
| Command | What it does |
|---------|-------------|
| `cd ~/dotfiles && stow -R niri` | Restow niri after editing config |
| `cd ~/dotfiles && stow -R .` | Restow all packages |
| `~/dotfiles/scripts/wallpaper` | Cycle to random wallpaper |
| `~/dotfiles/scripts/wallpaper ~/Pics/cat.png` | Set specific wallpaper |
| `~/dotfiles/scripts/generate-wallpapers.py` | Regenerate all 5 wallpapers |
| `~/dotfiles/scripts/clipboard-picker` | Manually open clipboard history |

## Quickshell bar layout
```
┌─ Niri │ eDP-1 ── ☕ Wed Jun 4 ── 󰤨 ZTE_2.4G │ 󰖜 100% │ 󰕾 55% │ 09:37 │ ⏻ ─┐
└──────────────────────────────────────────────────────────────────────────────┘
```

## Configs location
```
~/dotfiles/
├── niri/.config/niri/config.kdl         # WM keybinds & behaviour
├── quickshell/.config/quickshell/        # Bar & widgets (shell.qml)
├── foot/.config/foot/foot.ini           # Terminal
├── fuzzel/.config/fuzzel/fuzzel.ini     # App launcher theme
├── mako/.config/mako/config             # Notifications
├── gammastep/.config/gammastep/config.ini # Night mode
├── fontconfig/.config/fontconfig/fonts.conf
├── wallpapers/                           # 5x Catppuccin wallpapers (CC0)
└── scripts/                              # Helper scripts
```

## Quick fixes
| Problem | Fix |
|---------|-----|
| Bar not showing | `pkill qs && qs -c ~/.config/quickshell &` |
| Wallpaper not loaded | `~/dotfiles/scripts/wallpaper` |
| Config changes not applied | Restow + reload niri: `Mod+Shift+C` |
| Hot reload quickshell | Save QML file — quickshell reloads automatically |
| Clipboard history empty | Ensure `wl-paste --watch cliphist store` is running |

## Fonts
| Component | Font |
|-----------|------|
| System default | JetBrainsMono Nerd Font (fontconfig) |
| Terminal (foot) | JetBrainsMono Nerd Font 11pt |
| Launcher (fuzzel) | JetBrainsMono Nerd Font 13pt |
| Notifications (mako) | JetBrainsMono Nerd Font 10pt |
| Bar (quickshell) | JetBrainsMono Nerd Font |

## Theme
Catppuccin Mocha across all components:
- Base: `#1e1e2e` | Surface: `#313244` | Overlay: `#45475a`
- Text: `#cdd6f4` | Subtext: `#a6adc8`
- Blue: `#89b4fa` | Green: `#a6e3a1` | Red: `#f38ba8`
- Lavender: `#b4befe` | Mauve: `#cba6f7` | Pink: `#f5c2e7`
