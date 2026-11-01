#!/bin/bash
# Prints the MPRIS player the lock screen should show: the first one that is
# Playing, otherwise the first Paused one, otherwise nothing.
# (Plain `playerctl` just takes the first player in its list, so a paused
# browser tab could win over music that is actually playing.)

paused=""
for p in $(playerctl -l 2>/dev/null); do
    case "$(playerctl -p "$p" status 2>/dev/null)" in
        Playing) echo "$p"; exit 0 ;;
        Paused)  [ -z "$paused" ] && paused=$p ;;
    esac
done
[ -n "$paused" ] && echo "$paused"
