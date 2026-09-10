#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Hyprlock Media Player — Smart Status Line                  ║
# ║  Generic MPRIS-aware with player detection                  ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Usage:
#   songdetail.sh              → returns "icon  title — artist" or player-specific info
#   songdetail.sh icon         → returns just the status icon (▶ / ⏸ / empty)
#   songdetail.sh player_name  → returns the player name (Firefox, Spotify, etc.)

MODE="${1:-full}"

# Check if any player is active
STATUS=$(playerctl status 2>/dev/null)
if [ -z "$STATUS" ] || [ "$STATUS" = "Stopped" ]; then
    case "$MODE" in
        icon)        echo "" ;;
        player_name) echo "" ;;
        *)           echo "" ;;
    esac
    exit 0
fi

# Detect which player is active
PLAYER_NAME=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)

# Map player name to a display-friendly name with nerd font icon
get_player_icon() {
    case "${1,,}" in
        spotify*)    echo "󰓇" ;;
        firefox*)    echo "󰈹" ;;
        chromium*|google-chrome*|brave*|vivaldi*|microsoft-edge*) echo "󰊯" ;;
        mpv*)        echo "" ;;
        vlc*)        echo "󰕼" ;;
        rhythmbox*)  echo "󰎆" ;;
        audacious*)  echo "󰎆" ;;
        cmus*)       echo "󰎆" ;;
        *)           echo "󰎆" ;;  # generic music icon
    esac
}

get_player_display_name() {
    case "${1,,}" in
        spotify*)    echo "Spotify" ;;
        firefox*)    echo "Firefox" ;;
        chromium*)   echo "Chromium" ;;
        google-chrome*) echo "Chrome" ;;
        brave*)      echo "Brave" ;;
        mpv*)        echo "mpv" ;;
        vlc*)        echo "VLC" ;;
        *)           echo "$1" ;;
    esac
}

# Get status icon
get_status_icon() {
    case "$STATUS" in
        Playing) echo "▶" ;;
        Paused)  echo "⏸" ;;
        *)       echo "⏹" ;;
    esac
}

TITLE=$(playerctl metadata --format '{{title}}' 2>/dev/null)
ARTIST=$(playerctl metadata --format '{{artist}}' 2>/dev/null)

# Truncate long titles
[ ${#TITLE} -gt 35 ] && TITLE="${TITLE:0:32}..."

case "$MODE" in
    icon)
        echo "$(get_player_icon "$PLAYER_NAME")  $(get_status_icon)"
        ;;
    player_name)
        echo "$(get_player_display_name "$PLAYER_NAME")"
        ;;
    *)
        # Full mode: "title — artist" or just "title" if no artist
        if [ -n "$ARTIST" ] && [ "$ARTIST" != "(null)" ]; then
            echo "$TITLE  —  $ARTIST"
        elif [ -n "$TITLE" ]; then
            echo "$TITLE"
        else
            echo "$(get_player_display_name "$PLAYER_NAME")"
        fi
        ;;
esac
