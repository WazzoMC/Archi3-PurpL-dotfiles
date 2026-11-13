#!/usr/bin/env bash
# save.sh: snapshot this laptop's i3 desktop into ~/dotfiles (a git repo).
# Run it whenever you change something; it commits, and pushes if GitHub is set up.
# On a new laptop: git clone https://github.com/WazzoMC/dotfiles ~/dotfiles && bash ~/dotfiles/install.sh
set -euo pipefail

DOT="$HOME/dotfiles"
CONFIGS=(i3 polybar rofi dunst alacritty gtk-3.0 fastfetch)

echo "==> Saving your setup into $DOT"
mkdir -p "$DOT"/{config,bin,fonts,wallpapers}

# configs (fresh copy each time, minus backups)
for n in "${CONFIGS[@]}"; do
  rm -rf "${DOT:?}/config/$n"
  if [[ -d "$HOME/.config/$n" ]]; then cp -a "$HOME/.config/$n" "$DOT/config/"; fi
done
find "$DOT/config" -name '*.bak-*' -delete

# polybar: swap this laptop's hardware names for placeholders (install.sh re-detects them)
cfg="$DOT/config/polybar/config.ini"
if [[ -f "$cfg" ]]; then
  sed -i -E 's|^(interface[[:space:]]*=[[:space:]]*).*|\1__WIFI__|; s|^(battery[[:space:]]*=[[:space:]]*).*|\1__BAT__|; s|^(adapter[[:space:]]*=[[:space:]]*).*|\1__ADP__|; s|^(card[[:space:]]*=[[:space:]]*).*|\1__BACKLIGHT__|' "$cfg"
fi

# scripts, fonts, wallpapers
rm -f "$DOT"/bin/*
if compgen -G "$HOME/.local/bin/t410-*" >/dev/null; then cp -a "$HOME"/.local/bin/t410-* "$DOT/bin/"; fi
if [[ -f "$HOME/.local/share/fonts/Feather.ttf" ]]; then cp -a "$HOME/.local/share/fonts/Feather.ttf" "$DOT/fonts/"; fi
find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
  -size -50M -exec cp -a {} "$DOT/wallpapers/" \; 2>/dev/null || true
if [[ -L "$HOME/.config/wallpaper" ]]; then basename "$(readlink "$HOME/.config/wallpaper")" > "$DOT/wallpaper-current.txt"; fi

# package list: created once, then it's yours to edit (add apps you want on every laptop)
if [[ ! -f "$DOT/packages.txt" ]]; then
cat > "$DOT/packages.txt" <<'EOF'
# Installed by install.sh with pacman. One package per line; # starts a comment.
# desktop
i3-wm
i3lock
xss-lock
polybar
rofi
dunst
libnotify
feh
maim
xclip
xdotool
network-manager-applet
papirus-icon-theme
ttf-iosevka-nerd
ttf-roboto-mono
noto-fonts
noto-fonts-emoji
# terminal + tools
alacritty
fastfetch
yazi
ffmpegthumbnailer
poppler
fd
ripgrep
fzf
zoxide
git
# apps
firefox
obsidian
EOF
fi

cat > "$DOT/.gitignore" <<'EOF'
*.bak-*
*.log
EOF

cat > "$DOT/install.sh" <<'INSTALL_EOF'
#!/usr/bin/env bash
# install.sh: set up this i3 desktop on a fresh Arch Linux + i3 install.
#   git clone https://github.com/WazzoMC/dotfiles ~/dotfiles && bash ~/dotfiles/install.sh
# Safe to re-run. Backs up whatever it replaces to ~/config-backup-<date>/.
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/config-backup-$STAMP"

command -v pacman >/dev/null || { echo "This is for Arch Linux (pacman not found)."; exit 1; }

echo "==> Installing packages from packages.txt (needs your password)"
mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$DOT/packages.txt" | awk '{print $1}')
sudo pacman -Syu --needed --noconfirm "${PKGS[@]}"

echo "==> Backing up current configs to $BACKUP"
mkdir -p "$BACKUP"
for d in "$DOT"/config/*/; do
  n="$(basename "$d")"
  if [[ -e "$HOME/.config/$n" ]]; then cp -a "$HOME/.config/$n" "$BACKUP/"; fi
done
if [[ -f "$HOME/.bashrc" ]]; then cp -a "$HOME/.bashrc" "$BACKUP/bashrc"; fi

echo "==> Copying configs, scripts, fonts and wallpapers"
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/fonts" "$HOME/Pictures/wallpapers"
for d in "$DOT"/config/*/; do
  n="$(basename "$d")"
  mkdir -p "$HOME/.config/$n"
  cp -a "$d." "$HOME/.config/$n/"
done
if compgen -G "$DOT/bin/*" >/dev/null; then cp -a "$DOT"/bin/* "$HOME/.local/bin/"; chmod +x "$HOME"/.local/bin/*; fi
if compgen -G "$DOT/fonts/*" >/dev/null; then cp -a "$DOT"/fonts/* "$HOME/.local/share/fonts/"; fi
if compgen -G "$DOT/wallpapers/*" >/dev/null; then cp -a "$DOT"/wallpapers/* "$HOME/Pictures/wallpapers/"; fi
chmod +x "$HOME/.config/polybar/launch.sh" 2>/dev/null || true
fc-cache -f >/dev/null

echo "==> Detecting this laptop's Wi-Fi, battery and screen brightness"
WIFI=""; for n in /sys/class/net/*; do if [[ -d "$n/wireless" ]]; then WIFI="$(basename "$n")"; break; fi; done
BAT=""; for b in /sys/class/power_supply/BAT*; do if [[ -e "$b" ]]; then BAT="$(basename "$b")"; break; fi; done
ADP=""; for a in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do if [[ -e "$a" ]]; then ADP="$(basename "$a")"; break; fi; done
BL=""
if [[ -e /sys/class/backlight/intel_backlight ]]; then BL=intel_backlight
else for l in /sys/class/backlight/*; do if [[ -e "$l" ]]; then BL="$(basename "$l")"; break; fi; done; fi
echo "    wifi=${WIFI:-none} battery=${BAT:-none} adapter=${ADP:-none} backlight=${BL:-none}"

cfg="$HOME/.config/polybar/config.ini"
if [[ -f "$cfg" ]]; then
  sed -i "s|__WIFI__|${WIFI:-wlan0}|; s|__BAT__|${BAT:-BAT0}|; s|__ADP__|${ADP:-AC}|; s|__BACKLIGHT__|${BL:-intel_backlight}|" "$cfg"
  if [[ -z "$BL" ]];   then sed -i 's/ backlight sep2 sep2//' "$cfg"; fi
  if [[ -z "$BAT" ]];  then sed -i 's/ sep right1 battery left1//' "$cfg"; fi
  if [[ -z "$WIFI" ]]; then sed -i 's/ sep right1 network left1//' "$cfg"; fi
fi

echo "==> Wallpaper, dark mode and fastfetch"
cur="$(cat "$DOT/wallpaper-current.txt" 2>/dev/null || true)"
if [[ -n "$cur" && -f "$HOME/Pictures/wallpapers/$cur" ]]; then
  ln -sfn "$HOME/Pictures/wallpapers/$cur" "$HOME/.config/wallpaper"
elif [[ ! -e "$HOME/.config/wallpaper" ]]; then
  first="$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f | sort | head -1)"
  if [[ -n "$first" ]]; then ln -sfn "$first" "$HOME/.config/wallpaper"; fi
fi
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
touch "$HOME/.bashrc"
if ! grep -q 't410: fastfetch' "$HOME/.bashrc"; then
  printf '\n# t410: fastfetch when a terminal opens (delete these 2 lines to turn it off)\n[[ $- == *i* ]] && command -v fastfetch >/dev/null && fastfetch\n' >> "$HOME/.bashrc"
fi

echo "==> Checking the i3 config"
if i3 -C -c "$HOME/.config/i3/config"; then
  i3-msg restart >/dev/null 2>&1 || true
  echo
  echo "All set! If you're not in i3 yet, log in to i3 now."
  echo "Undo: cp -a $BACKUP/. ~/.config/ && i3-msg restart"
else
  echo "The i3 config check failed. Putting your previous i3 config back."
  if [[ -d "$BACKUP/i3" ]]; then rm -rf "$HOME/.config/i3"; cp -a "$BACKUP/i3" "$HOME/.config/i3"; fi
  exit 1
fi
INSTALL_EOF

cat > "$DOT/README.md" <<'README_EOF'
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
README_EOF

chmod +x "$DOT/install.sh"
# keep a copy of this script in the repo so you can re-run it: bash ~/dotfiles/save.sh
if [[ "$(readlink -f "$0")" != "$(readlink -f "$DOT/save.sh")" ]]; then cp "$0" "$DOT/save.sh"; fi
chmod +x "$DOT/save.sh"
if [[ -f "$HOME/.config/polybar/LICENSE-keyitdev" ]]; then cp "$HOME/.config/polybar/LICENSE-keyitdev" "$DOT/"; fi

echo "==> Committing"
cd "$DOT"
if [[ ! -d .git ]]; then git init -q -b main; fi
if ! git config user.name >/dev/null; then git config user.name "$(whoami)"; fi
if ! git config user.email >/dev/null; then git config user.email "$(whoami)@$(cat /etc/hostname 2>/dev/null || echo localhost)"; fi
git add -A
if git diff --cached --quiet; then
  echo "    nothing changed since the last save"
else
  git commit -q -m "Save setup $(date '+%Y-%m-%d %H:%M')"
  echo "    saved a new snapshot"
fi
if git remote get-url origin >/dev/null 2>&1; then
  echo "==> Pushing to GitHub"
  git push -q -u origin main && echo "    pushed"
else
  echo
  echo "Not on GitHub yet. To upload it (one time):"
  echo "  sudo pacman -S --needed github-cli"
  echo "  gh auth login"
  echo "  cd ~/dotfiles && gh repo create dotfiles --public --source . --push"
fi
echo
echo "On a new laptop (Arch + i3 installed, logged in):"
echo "  sudo pacman -S --needed git && git clone https://github.com/WazzoMC/dotfiles ~/dotfiles && bash ~/dotfiles/install.sh"
