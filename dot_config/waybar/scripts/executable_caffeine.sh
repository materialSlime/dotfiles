#!/bin/bash
# Caffeine toggle — blocks system sleep while keeping screen lock active.
# Uses systemd-inhibit so hypridle's lock/screensaver listeners are unaffected.

LOCKFILE="/tmp/caffeine.lock"

toggle() {
    if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE" 2>/dev/null)" 2>/dev/null; then
        kill "$(cat "$LOCKFILE")" 2>/dev/null
        rm -f "$LOCKFILE"
    else
        systemd-inhibit --what=sleep --who="Caffeine" --why="User requested no sleep" --mode=block sleep infinity &
        echo $! > "$LOCKFILE"
        disown
    fi
    pkill -RTMIN+9 waybar
}

status() {
    if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE" 2>/dev/null)" 2>/dev/null; then
        echo '{"text": "󰅶", "tooltip": "Caffeine ON — sleep inhibited", "class": "on"}'
    else
        rm -f "$LOCKFILE" 2>/dev/null
        echo '{"text": "󰒲", "tooltip": "Caffeine OFF — normal sleep", "class": "off"}'
    fi
}

case "${1:-status}" in
    toggle) toggle ;;
    *) status ;;
esac
