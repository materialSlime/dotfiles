#!/bin/bash
# Waybar media player module — bash replacement for mediaplayer.py
# Called by waybar on interval. Outputs JSON with player info + progress bar.

# Exit silently (empty output hides the module) if no player is active
status=$(playerctl status 2>/dev/null) || exit 0

player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)

# Escape characters that break JSON
escape() { local s="${1//\\/\\\\}"; s="${s//\"/\\\"}"; echo "$s"; }
artist=$(escape "$artist")
title=$(escape "$title")

# Status icon
[[ "$status" == "Playing" ]] && icon="" || icon=""

# Source icon
case "$player" in
    spotify) source=" {Spotify}" ;;
    firefox) source=" {Firefox}" ;;
    mpv)     source="AV" ;;
    vlc)     source="LM " ;;
    *)       source="󰈹 " ;;
esac

# Progress bar for tooltip
progress=""
pos=$(playerctl position 2>/dev/null | cut -d. -f1)
len=$(playerctl metadata mpris:length 2>/dev/null)

if [[ -n "$len" && "$len" -gt 0 ]]; then
    len_s=$((len / 1000000))
    pos=${pos:-0}
    ((pos > len_s)) && pos=$len_s
    ((pos < 0)) && pos=0
    pct=$((pos * 100 / (len_s > 0 ? len_s : 1)))
    filled=$((pct * 20 / 100))
    empty=$((20 - filled))
    bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    printf -v progress '%d:%02d %s %d:%02d' $((pos/60)) $((pos%60)) "$bar" $((len_s/60)) $((len_s%60))
fi

# Format display text
text="$icon"
[[ -n "$artist" ]] && text+=" $artist -"
text+=" $title"

# Format tooltip
tooltip="$source\\n$title"
[[ -n "$artist" ]] && tooltip+="\\n$artist"
[[ -n "$progress" ]] && tooltip+="\\n$progress"

printf '{"text": "%s", "tooltip": "%s", "class": "custom-%s", "alt": "%s"}\n' \
    "$text" "$tooltip" "$player" "$player"
