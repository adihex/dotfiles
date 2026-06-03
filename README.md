# dotfiles

Managed with GNU Stow.

## packages
- niri
- quickshell
- foot
- fuzzel
- mako

## install stow (Nobara/Fedora)
```bash
sudo dnf install stow
```

## stow
```bash
cd ~/dotfiles
stow niri quickshell foot fuzzel mako
```

## unstow
```bash
cd ~/dotfiles
stow -D niri quickshell foot fuzzel mako
```

## restow
```bash
cd ~/dotfiles
stow -R niri quickshell foot fuzzel mako
```
