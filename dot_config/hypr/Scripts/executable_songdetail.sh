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
#   songdetail.sh title        → just the title, shortened to 28 chars
#   songdetail.sh artist       → just the artist, shortened to 30 chars
#   songdetail.sh header       → dock header: "NOW PLAYING" or "HOST"
#
# With nothing playing, the same modes describe the machine instead:
# icon = monitor, title = hostname, artist = kernel, player_name = uptime.

MODE="${1:-full}"

# Pick the player that is actually playing (see active-player.sh)
PLAYER=$(~/.config/hypr/Scripts/active-player.sh)
STATUS=$([ -n "$PLAYER" ] && playerctl -p "$PLAYER" status 2>/dev/null)
if [ -z "$STATUS" ] || [ "$STATUS" = "Stopped" ]; then
    case "$MODE" in
        header)      echo "HOST" ;;
        icon)        echo "󰍹" ;;
        title)       tr '[:lower:]' '[:upper:]' </proc/sys/kernel/hostname ;;
        artist)      echo "Linux $(uname -r)" ;;
        player_name) uptime -p | sed 's/^up /UP /' ;;
        *)           echo "" ;;
    esac
    exit 0
fi
[ "$MODE" = header ] && { echo "NOW PLAYING"; exit 0; }

# Detect which player is active
PLAYER_NAME=$(playerctl -p "$PLAYER" metadata --format '{{playerName}}' 2>/dev/null)

# Firefox-based browsers (Zen, LibreWolf, ...) all report "firefox";
# ask D-Bus which program owns the player to tell them apart.
if [[ "${PLAYER_NAME,,}" == firefox* ]]; then
    OWNER=$(busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus \
        GetConnectionUnixProcessID s "org.mpris.MediaPlayer2.$PLAYER" 2>/dev/null | awk '{print $2}')
    case "$(cat /proc/"$OWNER"/comm 2>/dev/null)" in
        zen*)      PLAYER_NAME=zen ;;
        librewolf*) PLAYER_NAME=librewolf ;;
    esac
fi

# Map player name to a display-friendly name with nerd font icon
get_player_icon() {
    case "${1,,}" in
        spotify*)    echo "󰓇" ;;
        firefox*)    echo "󰈹" ;;
        zen*|librewolf*) echo "󰖟" ;;
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
        zen*)        echo "Zen" ;;
        librewolf*)  echo "LibreWolf" ;;
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

TITLE=$(playerctl -p "$PLAYER" metadata --format '{{title}}' 2>/dev/null)
ARTIST=$(playerctl -p "$PLAYER" metadata --format '{{artist}}' 2>/dev/null)

[ "$ARTIST" = "(null)" ] && ARTIST=""

# shorten to N characters with an ellipsis
short() { local t=$1 n=$2; [ ${#t} -gt "$n" ] && t="${t:0:$((n - 1))}…"; printf '%s' "$t"; }

case "$MODE" in
    icon)
        echo "$(get_player_icon "$PLAYER_NAME")  $(get_status_icon)"
        ;;
    title)
        short "${TITLE:-$(get_player_display_name "$PLAYER_NAME")}" 28; echo
        ;;
    artist)
        short "$ARTIST" 30; echo
        ;;
    player_name)
        # Prefer the name the player reports itself (MPRIS Identity, e.g. "Chrome");
        # Firefox-based browsers all report "Firefox", so those keep the name found above.
        IDENTITY=$(busctl --user get-property "org.mpris.MediaPlayer2.$PLAYER" /org/mpris/MediaPlayer2 \
            org.mpris.MediaPlayer2 Identity 2>/dev/null | sed -nE 's/^s "(.*)"$/\1/p')
        if [ -n "$IDENTITY" ] && [[ "${PLAYER_NAME,,}" != zen* && "${PLAYER_NAME,,}" != librewolf* ]]; then
            echo "$IDENTITY"
        else
            echo "$(get_player_display_name "$PLAYER_NAME")"
        fi
        ;;
    *)
        # Full mode: "title — artist" or just "title" if no artist
        TITLE=$(short "$TITLE" 45)
        if [ -n "$ARTIST" ]; then
            echo "$TITLE  —  $ARTIST"
        elif [ -n "$TITLE" ]; then
            echo "$TITLE"
        else
            echo "$(get_player_display_name "$PLAYER_NAME")"
        fi
        ;;
esac
