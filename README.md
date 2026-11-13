# dotfiles: Arch Linux + i3 (ThinkPad T410 setup)

Dark, light-on-resources i3 desktop: polybar, rofi, dunst, Alacritty, yazi, fastfetch.
Look adapted from [Keyitdev's dotfiles](https://github.com/Keyitdev/dotfiles) (GPL-3.0). No compositor, PipeWire audio.

## New laptop
1. Install Arch with `archinstall` and pick the **i3** profile (PipeWire audio, NetworkManager).
2. Log in, open a terminal, and run:
   ```
   sudo pacman -S --needed git && git clone https://github.com/WazzoMC/dotfiles ~/dotfiles && bash ~/dotfiles/install.sh
   ```
It installs everything in `packages.txt`, backs up any configs it replaces, and detects the laptop's Wi-Fi, battery and backlight for the bar.

## Saving changes
`bash ~/dotfiles/save.sh`: copies your current configs in, commits, and pushes.

## Keys (Super = Windows key)
| Action | Keys |
|---|---|
| Terminal | Super+Enter |
| Apps | Super+Space (or Super+D) |
| Close window | Super+W |
| Pop window out / in | Super+T |
| Bigger / smaller | Super+= / Super+- |
| Wallpaper picker | Super+Ctrl+Space (~/Pictures/wallpapers) |
| Files (yazi) | Super+Shift+F |
| Switch window | Super+Tab |
| Power menu | Super+X or Super+Esc |
| Copy / paste anywhere | Super+C / Super+V |
| Screenshot | PrtSc (Shift+PrtSc = area) |
| Focus / move | Super+arrows / Super+Shift+arrows |
| Split side / below | Super+H / Super+Shift+V |
| Fullscreen | Super+F |
| Workspaces | Super+1…0, Super+Shift+1…0 to move a window |
| Reload / restart i3 | Super+Shift+C / Super+Shift+R |
