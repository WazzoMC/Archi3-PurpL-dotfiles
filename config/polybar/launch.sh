#!/usr/bin/env bash
# Restart polybar (one bar on the laptop screen)
killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.5; done
sleep 1  # let the wallpaper load first (for the see-through bar)
polybar main --config="$HOME/.config/polybar/config.ini" >/tmp/polybar.log 2>&1 &
