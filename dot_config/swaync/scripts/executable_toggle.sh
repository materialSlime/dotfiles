#!/usr/bin/env bash
# Toggle buttons for the swaync panel (buttons-grid in config.json).
#   toggle.sh <name> status   prints true/false (the button's update-command)
#   toggle.sh <name>          makes the real state match $SWAYNC_TOGGLE_STATE (the button's command)
#
# swaync also runs a button's command when update-command refreshes its state (every time
# the panel opens), so commands must SET the requested state, never flip it: when the
# state already matches they do nothing.

name=${1:?usage: toggle.sh <mic|gamemode|record|nightlight> [status]}
gamemode=~/.config/hypr/Scripts/keyd-gamemode.sh

is_on() {
  case $name in
    mic)        wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED ;;  # lit = muted
    gamemode)   [[ -e $XDG_RUNTIME_DIR/keyd-gamemode ]] ;;
    record)     ~/.config/swaync/scripts/record.sh status | grep -q true ;;
    nightlight) pgrep -x hyprsunset >/dev/null ;;
    *) echo "unknown toggle: $name" >&2; exit 2 ;;
  esac
}

if [[ ${2:-} == status ]]; then
  is_on && echo true || echo false
  exit 0
fi

want=${SWAYNC_TOGGLE_STATE:-}
[[ $want == true || $want == false ]] || exit 0
if is_on; then now=true; else now=false; fi
[[ $want == "$now" ]] && exit 0

case $name in
  mic)        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ "$([[ $want == true ]] && echo 1 || echo 0)" ;;
  gamemode)   $gamemode ;;
  record)     ~/.config/swaync/scripts/record.sh ;;
  nightlight)
    if [[ $want == true ]]; then
      command -v hyprsunset >/dev/null || { notify-send 'Night light' 'hyprsunset is not installed'; exit 0; }
      setsid -f hyprsunset -t 4000 >/dev/null 2>&1
    else
      pkill -x hyprsunset
    fi ;;
esac
