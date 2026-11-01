#!/bin/bash
# Clock pieces for hyprlock with fixed-width digits.
#
# Rajdhani's digits are proportional ("1" is 334 units wide, "8" is 542) and the
# font has no tabular-digit feature, so a centered clock would shift every
# minute. Instead:
#   - the clock "frame" always lays out 88:88 (the widest digits) with the
#     digits invisible — only the colon and the seconds show — so its width
#     never changes;
#   - each real digit is its own label, centered on its slot of that frame.
# Slot centers (1080p, x from screen center) are in hyprlock.conf.
#
#   clock.sh frame   invisible 88:88 + visible colon + seconds (top-aligned)
#   clock.sh ampm    invisible 88:88 + AM/PM where the seconds are
#   clock.sh 1..4    one digit of HH:MM (1 = hour tens … 4 = minute ones)
#   clock.sh 1 D     hour tens digit, only when it is D (else nothing)
#   clock.sh 4 D     minute ones digit, only when it is D (else nothing)
#                    The outer digits have one label per possible value, each
#                    placed so that digit's ink sits flush with the clock's edge
#                    (side bearings differ per digit).

source ~/.config/theme/gen/colors.sh 2>/dev/null   # $accent, $primary, $secondary

MONO="font_family='JetBrainsMono Nerd Font Mono'"
SPACE="<span $MONO size='12pt'> </span>"
HIDE="<span fgalpha='1'>"                          # drawn, but invisible

case "$1" in
    frame)
        echo "${HIDE}88</span><span foreground='${primary:-#F75049}' fgalpha='90%' size='130pt'>:</span>${HIDE}88</span>$SPACE<span $MONO font_weight='normal' size='28pt' foreground='${secondary:-#5EF6FF}' fgalpha='35%' rise='112640'>$(date +%S)</span>"
        ;;
    ampm)
        echo "${HIDE}88<span size='130pt'>:</span>88</span>$SPACE<span $MONO font_weight='normal' size='28pt' foreground='${primary:-#F75049}' fgalpha='70%'>$(date +%p)</span>"
        ;;
    1|2) d=$(date +%I | cut -c"$1")
         [ -n "$2" ] && [ "$d" != "$2" ] && exit 0
         echo "<span foreground='${accent:-#F3E900}'>$d</span>" ;;
    3|4) d=$(date +%M | cut -c"$(( $1 - 2 ))")
         [ -n "$2" ] && [ "$d" != "$2" ] && exit 0
         echo "<span foreground='${secondary:-#5EF6FF}'>$d</span>" ;;
esac
