#!/usr/bin/env bash

# --- Configuration ---
# Path to your wallpaper folder
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
# Time between wallpaper changes (in seconds)
INTERVAL=900
# ---------------------

# Check if directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
  echo "Error: Directory $WALLPAPER_DIR not found."
  exit 1
fi

echo "Starting awww wallpaper cycle from $WALLPAPER_DIR every $INTERVAL seconds..."

# Loop forever
while true; do
  # Clear the array each cycle to pick up new files
  images=()

  # Use shell globbing instead of find to avoid predicate errors
  # Enable case-insensitive matching and nullglob (don't return the pattern if no match)
  shopt -s nullglob
  shopt -s nocaseglob

  # Expand all supported extensions into the array
  for ext in jpg jpeg png gif webp; do
    images+=("$WALLPAPER_DIR"/*."$ext")
  done

  if [ ${#images[@]} -eq 0 ]; then
    echo "No images found in $WALLPAPER_DIR. Sleeping for 60s..."
    sleep 60
    continue
  fi

  # Cycle through the list one by one
  for img in "${images[@]}"; do
    echo "Setting wallpaper: $img"
    # Set wallpaper with a random transition
    awww img --transition-type random "$img"

    # Wait for the specified interval
    sleep "$INTERVAL"
  done
done
