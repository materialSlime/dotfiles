#!/bin/bash

# This script manages a custom Waybar module that can display either a clock or a year progress bar.
# It uses a state file to toggle between the two modes.

# The file used to store the current state ("clock" or "progress").
STATE_FILE="/tmp/waybar_clock_mode.state"

export LANG=C.UTF-8 
FILLED_CHAR="■"
EMPTY_CHAR="□"


# --- Initialization ---
# If the state file doesn't exist, create it and set the default state to "clock".
if [ ! -f "$STATE_FILE" ]; then
    echo "clock" > "$STATE_FILE"
fi

# --- Function to Toggle State ---
# This function is called when the Waybar module is clicked.
toggle_state() {
    # Read the current state from the file.
    current_state=$(cat "$STATE_FILE")

    # Flip the state.
    if [ "$current_state" == "clock" ]; then
        echo "progress" > "$STATE_FILE"
    else
        echo "clock" > "$STATE_FILE"
    fi

    # Send a signal to Waybar to refresh the module.
    # The signal number (10) must match the 'signal' option in the Waybar config.
    pkill -RTMIN+10 waybar
}

# --- Function to Get Display Output ---
# This function is called by Waybar at a regular interval to get the module's content.
get_display() {
    # Read the current state from the file.
    current_state=$(cat "$STATE_FILE")

    # Check if the state is "clock".
    if [ "$current_state" == "clock" ]; then
        # If so, display the time.
        text=$(date +"%A %I:%M %p")
        # Generate calendar, highlight current day, replace newlines with '\n' for JSON and wrap in a monospace font span
        today_padded=$(date +%e) # e.g., " 5" or "15"
        highlight_start="<span foreground='#FFD700' weight='bold'>" # Gold color
        highlight_end="<\/span>" # Escaped for sed

        calendar_raw=$(cal)
        calendar_formatted=$(echo "$calendar_raw" | \
            sed -E "s/(^| )(${today_padded})( |$)/\1${highlight_start}\2${highlight_end}\3/g" | \
            awk '{printf "%s\\n", $0}' | sed '$s/\\n$//')
        tooltip="<span font_family='monospace'>${calendar_formatted}</span>"
        # Output JSON for Waybar. The 'text' is what's displayed on the bar.
        printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$tooltip"
    else
        # Otherwise, display the year progress bar.
        # Get the current day of the year (e.g., 356).
        day_of_year=$(date +%-j)
        # Get the total number of days in the current year (365 or 366).
        days_in_year=$(date -d "$(date +%Y)-12-31" +%-j)
        # Calculate the percentage of the year that has passed.
        percent=$(( (100 * day_of_year) / days_in_year ))

        # --- Build the Progress Bar ---
        bar_width=10 # Total width of the bar in characters.
        # Calculate how many characters should be filled.
        filled_width=$(( (bar_width * percent) / 100 ))
        # Calculate how many characters should be empty.
        empty_width=$(( bar_width - filled_width ))

        # Create the filled and empty parts of the bar.
        filled_bar=""
            for ((i=0; i<filled_width; i++)); do
                filled_bar+="$FILLED_CHAR"
            done
        empty_bar=""
            for ((i=0; i<empty_width; i++)); do
                empty_bar+="$EMPTY_CHAR"
            done
        
        # Combine the parts to create the final text and tooltip.
        text="$filled_bar$empty_bar ${percent}%"
        days_remaining=$((days_in_year - day_of_year))
        weeks_passed=$((day_of_year / 7))
        weeks_remaining=$((days_remaining / 7))
        tooltip="Day ${day_of_year} of ${days_in_year}\\n${days_remaining} days remaining\\n${weeks_passed} weeks passed, ${weeks_remaining} weeks remaining"

        # Output JSON for Waybar.
        # echo "{\"text\": \"[${filled_bar}${empty_bar}]\", \"tooltip\": \"Test progress: ${percentage}%\"}"
        printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$tooltip"
    fi
}

# --- Main Script Logic ---
# This script is called with an argument: "toggle" or "get_display".
case "$1" in
    toggle)
        # If the argument is "toggle", call the toggle_state function.
        toggle_state
        ;;
    get_display)
        # If the argument is "get_display", call the get_display function.
        get_display
        ;;
    *)
        # If the argument is invalid, show an error in the Waybar module.
        printf '{"text": "Script Error", "tooltip": "Usage: %s {toggle|get_display}"}\n' "$0"
        exit 1
        ;;
esac
