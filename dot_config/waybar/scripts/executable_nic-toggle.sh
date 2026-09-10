#!/bin/bash

# Toggle main ethernet interface on/off
# Usage: nic-toggle.sh [interface_name]
# If no interface specified, tries to find main ethernet interface

# Function to find main ethernet interface
find_main_ethernet() {
    # Look for common ethernet interface patterns
    for iface in $(ip -brief link | grep -v "^lo" | awk '{print $1}'); do
        # Check if it's an ethernet interface (starts with en, eth, etc.)
        if [[ "$iface" =~ ^(en|eth)[a-z0-9]* ]]; then
            echo "$iface"
            return 0
        fi
    done
    # Fallback: return first non-loopback interface
    ip -brief link | grep -v "^lo" | head -1 | awk '{print $1}'
}

# Determine interface to toggle
if [ -n "$1" ]; then
    iface="$1"
else
    iface=$(find_main_ethernet)
    if [ -z "$iface" ]; then
        notify-send "Network Toggle" "No ethernet interface found"
        exit 1
    fi
fi

# Check current state
current_state=$(ip -brief link show "$iface" | awk '{print $2}')

# Determine action
if [ "$current_state" = "UP" ]; then
    action="down"
    verb="Disabled"
else
    action="up"
    verb="Enabled"
fi

# Execute change (requires pkexec for sudo prompt)
if pkexec ip link set dev "$iface" "$action"; then
    notify-send "Network Toggle" "$iface is now $verb"
else
    notify-send "Network Toggle" "Failed to change state for $iface"
fi
