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
