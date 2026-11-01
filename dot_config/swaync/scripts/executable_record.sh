#!/usr/bin/env bash
# Screen recording toggle for the swaync panel (gpu-screen-recorder).
#   record.sh         start: focused monitor + desktop audio -> ~/Videos/Recordings
#                     (running again stops it; SIGINT makes gpu-screen-recorder finish the file)
#   record.sh status  prints true/false for the toggle button's update-command

dir="$HOME/Videos/Recordings"
running() { pgrep -f '^gpu-screen-recorder' >/dev/null; }

if [[ ${1:-} == status ]]; then
  running && echo true || echo false
  exit 0
fi

if running; then
  pkill -INT -f '^gpu-screen-recorder'
  notify-send -a "REC" "Recording saved" "$dir"
  exit 0
fi

mkdir -p "$dir"
mon=$(hyprctl activeworkspace -j | jq -r .monitor)
swaync-client -cp >/dev/null
sleep 0.4
setsid -f gpu-screen-recorder -w "$mon" -f 60 -a default_output \
  -o "$dir/rec-$(date +%F_%H-%M-%S).mp4" >/dev/null 2>&1
notify-send -a "REC" "Recording $mon" "Open the panel and press record again to stop"
