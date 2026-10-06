#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Hyprlock Media Player — Album Art Fetcher                  ║
# ║  Saves current album art to /tmp for the image widget       ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Called by hyprlock's image { reload_cmd } to keep art updated.
# Handles: Spotify, Firefox, Chromium, mpv, VLC, any MPRIS player.
# Outputs the path to the image file on stdout.

ART_PATH="/tmp/hyprlock_album_art.png"
FALLBACK_PATH="/tmp/hyprlock_album_art_fallback.png"

# Create a cyberpunk fallback icon if it doesn't exist (a 1x1 transparent pixel)
if [ ! -f "$FALLBACK_PATH" ]; then
    # Tiny transparent PNG — won't show visually but prevents hyprlock errors
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "$FALLBACK_PATH" 2>/dev/null
fi

# Check if any player is running
STATUS=$(playerctl status 2>/dev/null)
if [ -z "$STATUS" ] || [ "$STATUS" = "Stopped" ]; then
    # No player active — use fallback
    cp "$FALLBACK_PATH" "$ART_PATH" 2>/dev/null
    echo "$ART_PATH"
    exit 0
fi

# Get the art URL from playerctl
ART_URL=$(playerctl metadata mpris:artUrl 2>/dev/null)

if [ -z "$ART_URL" ]; then
    # No art available (common for browsers, some players)
    cp "$FALLBACK_PATH" "$ART_PATH" 2>/dev/null
    echo "$ART_PATH"
    exit 0
fi

# Handle different URL schemes
case "$ART_URL" in
    file://*)
        # Local file — just copy it
        LOCAL_PATH="${ART_URL#file://}"
        cp "$LOCAL_PATH" "$ART_PATH" 2>/dev/null
        ;;
    http://*|https://*)
        # Remote URL — download with curl (silent, timeout, overwrite)
        curl -sL --max-time 3 -o "$ART_PATH" "$ART_URL" 2>/dev/null
        ;;
    *)
        # Unknown scheme — try as file path
        if [ -f "$ART_URL" ]; then
            cp "$ART_URL" "$ART_PATH" 2>/dev/null
        else
            cp "$FALLBACK_PATH" "$ART_PATH" 2>/dev/null
        fi
        ;;
esac

echo "$ART_PATH"
