#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Hyprlock Media Player — Album Art Fetcher                  ║
# ║  Prints the path of the current cover for the image widget  ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Called by hyprlock's image { reload_cmd } every reload_time seconds.
# Each cover is fetched once per track, converted to real PNG and cached as
# /tmp/hyprlock-art/<hash>.png, so the printed path changes with the track and
# hyprlock reloads it. If there's no player, no art, or the download fails,
# a transparent placeholder is shown instead of an old cover.
# Every image is 480x270 (16:9, made by cover-frame.py) so the dock never
# shifts; with no player at all, a HOST tile is shown instead.

CACHE="/tmp/hyprlock-art"
EMPTY="$CACHE/empty.png"
mkdir -p "$CACHE"

# transparent placeholder (made with PIL so libpng accepts it; the old
# hand-written bytes had a bad CRC and hyprlock refused to load them)
[ -s "$EMPTY" ] || python3 -c 'import sys; from PIL import Image; Image.new("RGBA", (8, 8), (0, 0, 0, 0)).save(sys.argv[1], "PNG")' "$EMPTY"

FRAME=~/.config/hypr/Scripts/cover-frame.py
HOST="$CACHE/host.png"

PLAYER=$(~/.config/hypr/Scripts/active-player.sh)
if [ -z "$PLAYER" ]; then
    [ -s "$HOST" ] || python3 "$FRAME" host "$HOST" 2>/dev/null
    [ -s "$HOST" ] && echo "$HOST" || echo "$EMPTY"
    exit 0
fi

URL=$(playerctl -p "$PLAYER" metadata mpris:artUrl 2>/dev/null)
if [ -z "$URL" ]; then
    # Browsers often send no cover for YouTube, only the page URL:
    # use YouTube's standard thumbnail for that video instead
    PAGE=$(playerctl -p "$PLAYER" metadata xesam:url 2>/dev/null)
    ID=$(printf '%s' "$PAGE" | sed -nE 's#.*(youtube\.com/(watch\?(.*&)?v=|shorts/|embed/)|youtu\.be/)([A-Za-z0-9_-]{11}).*#\4#p')
    [ -n "$ID" ] && URL="https://i.ytimg.com/vi/$ID/mqdefault.jpg"
fi
[ -z "$URL" ] && { echo "$EMPTY"; exit 0; }

case "$URL" in
    http://*|https://*)
        # remote cover: one download per URL
        OUT="$CACHE/$(printf '%s' "$URL" | md5sum | cut -c1-16).png"
        TMP="$OUT.part"
        [ -s "$OUT" ] || curl -sL --connect-timeout 5 --max-time 10 -o "$TMP" "$URL" 2>/dev/null
        ;;
    *)
        # local cover file. Browsers may reuse the same temp path for a new
        # cover, so the cache is keyed on the image's content, not its path.
        SRC="${URL#file://}"
        TMP="$CACHE/local.part"
        if ! cp "$SRC" "$TMP" 2>/dev/null; then
            # Flatpak apps (e.g. Chrome) keep it in their private /tmp:
            # read it from inside whichever running instance has it
            for inst in $(flatpak ps --columns=instance 2>/dev/null); do
                timeout 3 flatpak enter "$inst" cat "$SRC" >"$TMP" 2>/dev/null && [ -s "$TMP" ] && break
                rm -f "$TMP"
            done
        fi
        [ -s "$TMP" ] || { rm -f "$TMP"; echo "$EMPTY"; exit 0; }
        OUT="$CACHE/$(md5sum <"$TMP" | cut -c1-16).png"
        [ -s "$OUT" ] && rm -f "$TMP"
        ;;
esac
if [ ! -s "$OUT" ]; then
    # covers are often JPEG and come in any shape: fit each one into the
    # 16:9 frame as a real PNG (see cover-frame.py)
    if [ -s "$TMP" ] && python3 "$FRAME" frame "$TMP" "$OUT" 2>/dev/null; then
        rm -f "$TMP"
    else
        rm -f "$TMP" "$OUT"
        echo "$EMPTY"; exit 0
    fi
fi

# keep the cache small: drop covers older than a day
find "$CACHE" -name '*.png' ! -name empty.png ! -name host.png -mmin +1440 -delete 2>/dev/null

echo "$OUT"
