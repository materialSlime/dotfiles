#!/bin/bash
# Emergency restore script for hyprlock.conf
# Usage: bash ~/.config/hypr/backups/restore-hyprlock.sh
#
# This will restore the most recent backup of hyprlock.conf.
# You can run this from a TTY (Ctrl+Alt+F2) if hyprlock is broken.

BACKUP_DIR="$HOME/.config/hypr/backups"
LATEST_BACKUP=$(find "$BACKUP_DIR" -name "hyprlock.conf.bak" -type f | sort -r | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "ERROR: No backup found!"
    exit 1
fi

echo "Restoring from: $LATEST_BACKUP"
cp "$LATEST_BACKUP" "$HOME/.config/hypr/hyprlock.conf"
echo "✓ hyprlock.conf restored successfully."
echo "You can now lock your screen safely."
