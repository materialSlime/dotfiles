#!/bin/bash
# Screensaver driven by terminaltexteffects (tte).
#
# Launched by hypridle on idle timeout. Runs tte in a loop rendering
# random ASCII effects in a fullscreen terminal window titled
# "custom-screensaver". Self-exits on:
#   - Any keystroke
#   - Any mouse movement, click, or scroll
#   - Focus loss (another window takes focus)
#   - Hyprlock starting (system locking)
#   - Resume from suspend
#
# PORTABILITY:
#   Uses only standard xterm escape sequences — no terminal-specific APIs.
#   Tested/compatible: ghostty, kitty, alacritty, foot, wezterm, xterm.
#   Launch method: xdg-terminal-exec (uses system default terminal).
#   Mouse tracking: xterm ?1003h/?1006h (supported by all above).
#   Background color: OSC 11 (supported by all above).
#
# LOCKFILE STRATEGY:
#   /tmp/custom-screensaver.lock with PID inside + flock().
#   Stale lockfiles from dead PIDs are detected and overwritten.

set -u

LOCKFILE="/tmp/custom-screensaver.lock"

# ── Cleanup function ──────────────────────────────────────────────────
exit_screensaver() {
    # Restore terminal state — disable mouse tracking, show cursor
    printf '\033[?1003l\033[?1006l\033[?25h' 2>/dev/null
    pkill -x tte 2>/dev/null
    rm -f "$LOCKFILE"
    hyprctl keyword cursor:invisible false >/dev/null 2>&1 || true
    exit 0
}

# ── Focus check ───────────────────────────────────────────────────────
screensaver_in_focus() {
    hyprctl activewindow -j 2>/dev/null | python3 -c '
import json, sys
try:
    w = json.load(sys.stdin)
    sys.exit(0 if w.get("title", "") == "custom-screensaver" else 1)
except Exception:
    sys.exit(1)
'
}

# ── Stale lockfile check ─────────────────────────────────────────────
# If lockfile exists, check if the PID inside is still alive.
# If dead → stale lock, remove it and continue.
# If alive → another instance is running, exit.
if [ -f "$LOCKFILE" ]; then
    OLD_PID=$(cat "$LOCKFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        # Another instance is genuinely running
        exit 0
    else
        # Stale lockfile from a dead process — clean it up
        rm -f "$LOCKFILE"
    fi
fi

# ── Acquire lock atomically via flock ─────────────────────────────────
# Write our PID, then hold an exclusive flock on the file.
# This prevents two instances from racing past the PID check above.
echo "$$" > "$LOCKFILE"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    # Another instance grabbed the lock between our check and now
    rm -f "$LOCKFILE"
    exit 0
fi
# Re-write PID after flock (flock doesn't truncate)
echo "$$" >"$LOCKFILE"

# ── Register cleanup traps ────────────────────────────────────────────
# EXIT covers normal exit + any signal that terminates the script.
# Explicit signal traps ensure cleanup even if subprocesses are running.
trap exit_screensaver SIGINT SIGTERM SIGHUP EXIT

hyprctl keyword cursor:invisible true >/dev/null 2>&1 || true
# Set terminal background to black (OSC 11)
printf '\033]11;rgb:00/00/00\007'
# Enable xterm mouse tracking — ALL mouse events (move, click, scroll)
# become stdin bytes instead of being handled by the terminal.
# This prevents text selection, context menus, and lets us detect mouse activity.
#   ?1003h = report all motion events     (universally supported)
#   ?1006h = SGR extended encoding        (handles coordinates > 223)
#   ?25l   = hide text cursor             (cleaner screensaver look)
printf '\033[?1003h\033[?1006h\033[?25l'

# ── Main loop ─────────────────────────────────────────────────────────
while true; do
    tte -i "$HOME/.config/screensaver/logo.txt" --random-effect --xterm-colors --no-eol --canvas-width 0 --canvas-height 0 --anchor-text c &
    tte_pid=$!

    while kill -0 "$tte_pid" 2>/dev/null; do
        # Check for any input — keyboard OR mouse (mouse tracking sends bytes to stdin)
        if read -n1 -t 0.5 2>/dev/null; then
            exit_screensaver
        fi

        # Check if we lost focus (user switched window, or hyprlock started)
        if ! screensaver_in_focus; then
            exit_screensaver
        fi

        # Check if hyprlock is now running (system locked)
        if pidof hyprlock >/dev/null 2>&1; then
            exit_screensaver
        fi
    done
    wait "$tte_pid" 2>/dev/null
done
