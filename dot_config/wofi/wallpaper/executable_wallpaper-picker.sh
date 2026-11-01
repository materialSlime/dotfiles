#!/usr/bin/env bash
# Wallpaper filmstrip: one row of thumbnails along the bottom of the screen.
# Starts at the current wallpaper. h/l or arrows/scroll to browse, type to filter,
# Enter/click to set it, Esc or SUPER+SHIFT+W again to close.
# Sets through wallpaper.sh, which also restores the choice at login.

DIR=~/Pictures/Wallpapers
THUMBS=~/.cache/wallpaper-picker
STYLE=~/.config/wofi/wallpaper/style.css
SETTER=~/.config/wofi/wallpaper/wallpaper.sh

if pgrep -x wofi >/dev/null; then
  pkill -x wofi
  exit 0
fi

python3 -I ~/.config/wofi/wallpaper/wallpaper-thumbs.py --out "$THUMBS"

shopt -s nullglob nocaseglob
files=()
for ext in jpg jpeg png gif webp bmp; do files+=("$DIR"/*."$ext"); done
shopt -u nullglob nocaseglob
((${#files[@]})) || exit 1
mapfile -t files < <(printf '%s\n' "${files[@]}" | sort)

# rotate the list so the strip starts at the wallpaper on screen
current=$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -n1)
start=0
for i in "${!files[@]}"; do [[ ${files[i]} == "$current" ]] && start=$i && break; done
ordered=("${files[@]:start}" "${files[@]:0:start}")

declare -A by_name
lines=()
for f in "${ordered[@]}"; do
  name=$(basename "${f%.*}")
  key=$(printf '%s' "$(realpath "$f")" | md5sum | cut -d' ' -f1)
  by_name[$name]=$f
  lines+=("img:$THUMBS/$key.png:text:$name")
done

# monitor width in desktop pixels, minus margins
mw=$(hyprctl -j monitors | jq '.[] | select(.focused) | (.width / .scale | floor)')
mw=${mw:-1920}

choice=$(printf '%s\n' "${lines[@]}" | wofi --dmenu --insensitive --cache-file=/dev/null \
  --style "$STYLE" --prompt "wallpaper" --hide-search --allow-images --hide-scroll \
  --location bottom --yoffset -72 --width $((mw - 160)) --height 250 \
  --columns ${#lines[@]} --define image_size=300 \
  --define orientation=horizontal --define halign=start --define content_halign=center \
  --define key_left=h,Left --define key_right=l,Right)

[[ -z $choice ]] && exit 0
name=${choice##*:text:}
name=${name##*:}
path=${by_name[$name]}
[[ -f $path ]] || exit 1
"$SETTER" set "$path"
