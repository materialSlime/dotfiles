#!/bin/bash
# Toggle keyd game mode: plain D/Space for games, tap/hold keys otherwise
STATE="$XDG_RUNTIME_DIR/keyd-gamemode"

if [[ -e $STATE ]]; then
	keyd bind reset && rm "$STATE" && notify-send "Game mode OFF" "Tap/hold keys active"
else
	keyd bind 'd = d' 'space = space' && touch "$STATE" && notify-send "Game mode ON" "D and Space are plain keys"
fi
