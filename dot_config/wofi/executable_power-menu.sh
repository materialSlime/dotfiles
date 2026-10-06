#!/bin/bash

# Toggle: if a wofi menu is already open, close it instead of opening another
pkill -x wofi && exit 0

# Define the options for the power menu
# Using a simple string with newlines, ensuring no trailing empty line
options="    Shutdown
    Reboot
 󰔚   Lock
 󰗽   Logout
 󰤄   Suspend"

# Use wofi in dmenu mode to select an option
# Removed --hide-search to bring back the search bar
chosen=$(printf "%s" "$options" | wofi --dmenu --lines 5 --style ~/.config/wofi/power-style.css --prompt "System Power")

# Extract the action from the selected line (remove the icon/label)
case "$chosen" in
*Shutdown)
  confirm=$(printf "Yes\nNo" | wofi --dmenu --lines 2 --style ~/.config/wofi/power-style.css --prompt "Confirm Shutdown?")
  [[ "$confirm" == "Yes" ]] && systemctl poweroff
  ;;
*Reboot)
  confirm=$(printf "Yes\nNo" | wofi --dmenu --lines 2 --style ~/.config/wofi/power-style.css --prompt "Confirm Reboot?")
  [[ "$confirm" == "Yes" ]] && systemctl reboot
  ;;
*Lock)
  hyprlock
  ;;
*Logout)
  uwsm stop
  ;;
*Suspend)
  systemctl suspend
  ;;
esac
