#!/usr/bin/env bash
# Preview the SDDM login theme in a normal window (sddm-greeter test mode).
# Renders the theme exactly like `build --sddm` would, but into a temporary
# folder, so you can look at changes before installing them.
#
#   preview.sh                 default background style (ribbons)
#   preview.sh --style horizon other styles: horizon, circuit, city
#
# Close the window to end the preview (SUPER+Q). Nothing logs in from here.

set -e
THEME=~/.config/theme
STAGE="${XDG_RUNTIME_DIR:-/tmp}/sddm-preview/cyberpunk"

rm -rf "$STAGE"; mkdir -p "$STAGE"
"$THEME/build" --no-reload --sddm-stage "$STAGE" >/dev/null   # includes sddm/base
# a background style other than the default
if [ "$1" = --style ]; then python3 "$THEME/sddm/background.py" "$STAGE/bg.jpg" "$@" >/dev/null; fi

exec sddm-greeter-qt6 --test-mode --theme "$STAGE"
