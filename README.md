# dotfiles

Managed with GNU Stow.

## packages
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
