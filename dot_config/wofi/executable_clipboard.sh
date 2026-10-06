#!/bin/bash

# Toggle: if a wofi menu is already open, close it instead of opening another
pkill -x wofi && exit 0
# ~/.config/wofi/clipboard.sh

ACTION="${1:-paste}"
CACHE="/tmp/cliphist_cache"

# Save the full list (with IDs) to a temporary file
cliphist list > "$CACHE"

if [ ! -s "$CACHE" ]; then
    notify-send "Clipboard" "History is empty"
    exit 0
fi

if [ "$ACTION" == "delete" ]; then
    # --- DELETE MODE (SUPER + SHIFT + V) ---
    entries="󰃢   Clear All History\n$(cut -f2- "$CACHE")"
    chosen_text=$(echo -e "$entries" | wofi --dmenu \
        --prompt "Delete from Clipboard" \
        --style ~/.config/wofi/power-style.css \
        --cache-file=/dev/null)
    
    [ -z "$chosen_text" ] && exit 0
    
    if [[ "$chosen_text" == "󰃢   Clear All History" ]]; then
        confirm=$(printf "Yes\nNo" | wofi --dmenu --lines 2 --prompt "Wipe all history?" --style ~/.config/wofi/power-style.css)
        [[ "$confirm" == "Yes" ]] && cliphist wipe && notify-send "Clipboard" "History cleared"
    else
        # Match the exact text in the cache file to grab the ID back
        full_entry=$(awk -F'\t' -v target="$chosen_text" '{ text=$0; sub(/^[0-9]+\t/, "", text); if (text == target) { print $0; exit } }' "$CACHE")
        echo "$full_entry" | cliphist delete
        notify-send "Clipboard" "Item deleted"
    fi

else
    # --- PASTE MODE (SUPER + V) ---
    # Hide the ID using cut, send clean text to Wofi
    chosen_text=$(cut -f2- "$CACHE" | wofi --dmenu \
        --prompt "Clipboard" \
        --style ~/.config/wofi/power-style.css \
        --cache-file=/dev/null)

    [ -z "$chosen_text" ] && exit 0

    # Match the exact text in the cache file to grab the ID back
    full_entry=$(awk -F'\t' -v target="$chosen_text" '{ text=$0; sub(/^[0-9]+\t/, "", text); if (text == target) { print $0; exit } }' "$CACHE")
    
    # Decode using the full entry (with ID) and copy
    echo "$full_entry" | cliphist decode | wl-copy
fi
