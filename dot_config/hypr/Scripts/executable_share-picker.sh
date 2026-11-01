#!/bin/sh
# Screen-share picker for xdg-desktop-portal-hyprland (see ~/.config/hypr/xdph.conf).
# Never shows a dialog, so RustDesk works unattended: share the focused monitor,
# else the first one listed (the headless SUNSHINE screen when nothing is plugged in).
mon=$(hyprctl -j monitors | jq -r 'first(.[] | select(.focused) | .name) // .[0].name // empty')
[ -n "$mon" ] || mon=SUNSHINE
echo "[SELECTION]r/screen:$mon"
