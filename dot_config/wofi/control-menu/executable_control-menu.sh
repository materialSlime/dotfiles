#!/bin/bash
# Control menu: the everyday keybind actions, reachable with a mouse or touch.
# Made for streaming to Moonlight on a phone, where Super/Alt/F-keys don't exist.
#
#   control-menu.sh              open the menu (waybar 󰍜 button, SUPER+X)
#   control-menu.sh <action>     run one action directly, e.g. "close", "ws 3", "movews 2"
#
# Window actions apply to the focused window: tap a window first, then open the menu.

# Navigation:
#   tap an item                  run it, or open its submenu (items ending in ›)
#   right-click / long-press     in a submenu: back to the main menu; in the main menu: close
#   Esc                          same as right-click
#   tap the 󰍜 button again       close everything, from any level
#
# Right-click and the button both close wofi, so the script sees an empty choice either
# way. The button leaves a marker file first; an empty choice WITH the marker means
# "close everything", WITHOUT it means "go back".
MARK=${XDG_RUNTIME_DIR:-/tmp}/control-menu.closing
if pgrep -x wofi >/dev/null; then
	touch "$MARK"
	pkill -x wofi
	exit 0
fi
rm -f "$MARK"

STYLE=~/.config/wofi/shared/menu.css
SHOTS=~/Pictures/Screenshots

d() { hyprctl dispatch "$1" >/dev/null; }

# menu PROMPT ITEM... -> prints the chosen item (empty if dismissed)
menu() {
	local prompt=$1
	shift
	printf '%s\n' "$@" | menu_stdin "$prompt" $#
}

# menu_stdin PROMPT COUNT -> same, items read one per line from stdin
# --cache-file=/dev/null: wofi normally moves often-picked items to the top;
# with no cache the menu keeps the fixed order written below.
# While wofi is open, Hyprland is switched to the "menu" submap (bindings.lua), where a
# right-click anywhere closes the menu: phones have no Esc key, and wofi keeps the
# keyboard while open. The trap switches back even if the script is killed.
menu_stdin() {
	# Rows that fit: focused monitor's height in desktop pixels (height ÷ scale), keep
	# 15% free, minus ~100px for the search box and margins, ÷ ~50px per row
	# (20px font + 2×12px padding in ../shared/menu.css). The rest of the list scrolls.
	local fit
	fit=$(hyprctl -j monitors | jq '.[] | select(.focused) | ((.height / .scale * 0.85 - 100) / 50 | floor)')
	fit=${fit:-12}
	local max=$((fit > 3 ? (fit < 12 ? fit : 12) : 3))
	local n=$(($2 < max ? $2 : max))
	d 'hl.dsp.submap("menu")'
	wofi --dmenu --insensitive --cache-file=/dev/null --style "$STYLE" --prompt "$1" --lines "$n"
	d 'hl.dsp.submap("reset")'
}
trap 'd "hl.dsp.submap(\"reset\")"' EXIT

# A submenu came back empty: go back to the main menu (return 1), unless the 󰍜 button
# was tapped, in which case close everything.
back() {
	[ -e "$MARK" ] && exit 0
	return 1
}

# App launcher with the same back/close behaviour as the other menus. wofi only prints
# the chosen app's .desktop file (it exits 0 even when killed, so its exit code can't
# tell "launched" from "dismissed"); the script launches it through uwsm like the binds.
# Returns 1 if dismissed.
apps_menu() {
	local app
	d 'hl.dsp.submap("menu")'
	app=$(wofi --show drun --style "$STYLE" --prompt "Open app" -D drun-print_desktop_file=true | head -1)
	d 'hl.dsp.submap("reset")'
	[ -z "$app" ] && return 1
	setsid -f uwsm app -- "${app%% *}" >/dev/null 2>&1 # "${…%% *}": drop an action name, if any
}

# Power submenu; Shutdown and Reboot ask for confirmation. Dismissing the confirmation
# returns to this menu; dismissing this menu returns 1 (back to the main menu).
power_menu() {
	local p
	while true; do
		p=$(menu "Power" "󰐥  Shutdown" "󰜉  Reboot" "󰌾  Lock" "󰗽  Logout" "󰤄  Suspend")
		[ -z "$p" ] && return 1
		case "$p" in
		*Shutdown | *Reboot)
			if [ "$(menu "Confirm ${p##* }?" "Yes" "No")" != "Yes" ]; then
				[ -e "$MARK" ] && exit 0 # 󰍜/⏻ tapped: close everything
				continue                  # No / back: show the power menu again
			fi
			if [ "${p##* }" = Shutdown ]; then systemctl poweroff; else systemctl reboot; fi
			;;
		*Lock) hyprlock ;;
		*Logout) uwsm stop ;;
		*Suspend) systemctl suspend ;;
		esac
		return 0
	done
}

pick_workspace() {
	menu "$1" 1 2 3 4 5 6 7 8 9 10 | tr -dc '0-9'
}

# List open windows as "workspace │ class │ title", focus the chosen one.
# Returns 1 if the list was dismissed (so the caller can go back).
switch_window() {
	local list choice addr
	# one line per window; the address is kept at the end and hidden from the menu
	list=$(hyprctl clients -j | jq -r '
		sort_by(.workspace.id)[] | select(.mapped)
		| "\(.workspace.name) │ \(.class) │ \(.title[0:60]) │\(.address)"')
	[ -z "$list" ] && return 0
	choice=$(printf '%s\n' "$list" | sed 's/ │0x[0-9a-f]*$//' | menu_stdin "Switch to window" "$(printf '%s\n' "$list" | wc -l)")
	[ -z "$choice" ] && return 1
	# match the chosen visible text back to its address
	addr=$(printf '%s\n' "$list" | grep -F -- "$choice │0x" | head -1 | grep -o '0x[0-9a-f]*$')
	[ -n "$addr" ] && d "hl.dsp.focus({ window = \"address:$addr\" })"
}

run() {
	case "$1" in
	apps) apps_menu ;;
	windows) switch_window ;;
	close) d 'hl.dsp.window.close()' ;;
	maximize) d 'hl.dsp.window.fullscreen({ mode = 1 })' ;;
	fullscreen) d 'hl.dsp.window.fullscreen({ mode = 0 })' ;;
	float) d 'hl.dsp.window.float({ action = "toggle" })' ;;
	pin) d 'hl.dsp.window.pin()' ;;
	next) d 'hl.dsp.window.cycle_next()' ;;
	ws\ *) d "hl.dsp.focus({ workspace = ${1#ws } })" ;;
	movews\ *) d "hl.dsp.window.move({ workspace = ${1#movews } })" ;;
	move\ *) d "hl.dsp.window.move({ direction = \"${1#move }\" })" ;;
	scratchpad) d 'hl.dsp.workspace.toggle_special()' ;;
	to-scratchpad) d 'hl.dsp.window.move({ workspace = "special" })' ;;
	clipboard) ~/.config/wofi/clipboard/clipboard.sh ;;
	shot-screen) hyprshot -m output -m active -o "$SHOTS" ;;
	shot-window) hyprshot -m window -m active -o "$SHOTS" ;;
	shot-region) hyprshot -m region -o "$SHOTS" ;;
	notifications) swaync-client -t -sw ;;
	bar) pkill -x waybar || setsid -f waybar ;;
	power | power-menu) power_menu ;; # power-menu.sh is a wrapper for this
	*) return 1 ;;
	esac
}

# Direct action from the command line
if [ -n "$1" ]; then
	run "$*"
	exit
fi

main_menu() {
	menu "Control" \
		"󰀻  Open app" \
		"󰖯  Switch to window" \
		"󰅖  Close window" \
		"󰊓  Maximize (toggle)" \
		"󰍉  Fullscreen (toggle)" \
		"󰉧  Float / tile (toggle)" \
		"󰐃  Pin on all workspaces" \
		"󰒮  Focus next window" \
		"󰕰  Go to workspace ›" \
		"󰁔  Move window to workspace ›" \
		"󰆾  Move window ›" \
		"󰘔  Scratchpad (toggle)" \
		"󰆓  Send window to scratchpad" \
		"󰅌  Clipboard history" \
		"󰄀  Screenshot ›" \
		"󰂚  Notifications" \
		"󰍜  Show / hide bar" \
		"󰐥  Power menu"
}

# Loop so a submenu can return here: a submenu branch that comes back empty calls
# `back`, which either exits (button tapped) or lets `continue` show the main menu again.
# Every finished action ends with `exit`.
while true; do
	choice=$(main_menu)
	[ -z "$choice" ] && exit 0 # main menu dismissed: close

	case "$choice" in
	*"Go to workspace"*)
		n=$(pick_workspace "Go to workspace")
		[ -z "$n" ] && { back; continue; }
		run "ws $n"
		;;
	*"Move window to workspace"*)
		n=$(pick_workspace "Move window to workspace")
		[ -z "$n" ] && { back; continue; }
		run "movews $n"
		;;
	*"Move window ›")
		dir=$(menu "Move window" "󰁍  left" "󰁔  right" "󰁝  up" "󰁅  down" | awk '{print $NF}')
		[ -z "$dir" ] && { back; continue; }
		run "move $dir"
		;;
	*"Screenshot"*)
		s=$(menu "Screenshot" "󰍹  Whole screen" "󰖯  Focused window" "󰩭  Select region")
		case "$s" in
		*screen) run shot-screen ;;
		*window) run shot-window ;;
		*region) run shot-region ;;
		*) back; continue ;;
		esac
		;;
	*"Switch to window") switch_window || { back; continue; } ;;
	*"Open app") apps_menu || { back; continue; } ;;
	*"Power menu") power_menu || { back; continue; } ;;
	*"Close window") run close ;;
	*"Maximize"*) run maximize ;;
	*"Fullscreen"*) run fullscreen ;;
	*"Float / tile"*) run float ;;
	*"Pin on all"*) run pin ;;
	*"Focus next"*) run next ;;
	*"Scratchpad (toggle)") run scratchpad ;;
	*"Send window to scratchpad") run to-scratchpad ;;
	*"Clipboard history") run clipboard ;;
	*"Notifications") run notifications ;;
	*"Show / hide bar") run bar ;;
	esac
	exit 0
done
