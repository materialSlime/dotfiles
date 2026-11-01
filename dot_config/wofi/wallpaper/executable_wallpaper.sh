#!/usr/bin/env bash
# Wallpaper helper for awww. One place sets wallpapers (same transition every
# time) and remembers the current one, so the picker, the next key and the
# restore at login stay in sync. No automatic cycling.
#
#   wallpaper.sh             restore the last wallpaper (autostart)
#   wallpaper.sh set FILE    set FILE and remember it (picker)
#   wallpaper.sh next        switch to the next wallpaper (SUPER+ALT+W)

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper/current"

# transition used for every change
AWWW_OPTS=(--resize crop --filter Lanczos3
  --transition-type fade --transition-step 63 --transition-duration 2
  --transition-fps 75 --transition-angle 0)

apply() {
  [[ -f $1 ]] || return 1
  awww img "${AWWW_OPTS[@]}" "$1" || return 1
  mkdir -p "${STATE%/*}"
  printf '%s\n' "$1" >"$STATE"
}

set_next() {
  shopt -s nullglob nocaseglob
  local images=() ext
  for ext in jpg jpeg png gif webp; do
    images+=("$WALLPAPER_DIR"/*."$ext")
  done
  shopt -u nullglob nocaseglob
  ((${#images[@]})) || return 1
  mapfile -t images < <(printf '%s\n' "${images[@]}" | sort)

  # continue from whatever is on screen
  local current next i
  current=$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -n1)
  next=${images[0]}
  for i in "${!images[@]}"; do
    if [[ ${images[i]} == "$current" ]]; then
      next=${images[(i + 1) % ${#images[@]}]}
      break
    fi
  done
  apply "$next"
}

case "$1" in
  set)  apply "$(realpath "$2")" ;;
  next) set_next ;;
  *)    # restore: wait for the daemon, then bring back the last wallpaper
        for _ in {1..50}; do awww query &>/dev/null && break; sleep 0.2; done
        apply "$(cat "$STATE" 2>/dev/null)" || set_next ;;
esac
