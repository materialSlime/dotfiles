#!/usr/bin/env bash
# Download and install the fonts this setup uses.
#
#   Rajdhani                 Google Fonts  (waybar, wofi, hyprlock, SDDM)
#   Noto Sans JP             Google Fonts  (kanji in ghostty, waybar)
#   JetBrains Mono Nerd Font Nerd Fonts    (terminal, icons everywhere)
#
# All three are under the SIL Open Font License; each font folder gets its
# license file next to it.
#
#   install-fonts.sh --user        ~/.local/share/fonts        (just you, no sudo)
#   install-fonts.sh --system      /usr/local/share/fonts      (all users, incl. the
#                                                               SDDM login screen; sudo)
#   install-fonts.sh --dest DIR    any folder (no font-cache refresh)
#   install-fonts.sh               asks which one

set -euo pipefail

GF=https://raw.githubusercontent.com/google/fonts/main/ofl
NERD=https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz

mode=${1:-}
dest=""
case "$mode" in
    --user)   dest="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
    --system) dest=/usr/local/share/fonts ;;
    --dest)   dest=${2:?usage: install-fonts.sh --dest DIR} ;;
    "")
        echo "Install fonts for:"
        echo "  1) just me      (~/.local/share/fonts)"
        echo "  2) all users    (/usr/local/share/fonts, needs sudo; also used by the login screen)"
        read -rp "Choose 1 or 2: " ans
        case "$ans" in
            1) mode=--user;   dest="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
            2) mode=--system; dest=/usr/local/share/fonts ;;
            *) echo "cancelled"; exit 1 ;;
        esac ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown option: $mode (use --user, --system or --dest DIR)"; exit 1 ;;
esac

for cmd in curl tar xz; do
    command -v "$cmd" >/dev/null || { echo "missing: $cmd"; exit 1; }
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
get() { echo "  ↓ $(basename "$2")"; curl -fsSL --retry 2 -o "$2" "$1"; }

echo "Downloading…"
mkdir -p "$tmp/Rajdhani" "$tmp/NotoSansJP" "$tmp/JetBrainsMonoNerd"
for w in Light Regular Medium SemiBold Bold; do
    get "$GF/rajdhani/Rajdhani-$w.ttf" "$tmp/Rajdhani/Rajdhani-$w.ttf"
done
get "$GF/rajdhani/OFL.txt" "$tmp/Rajdhani/OFL.txt"
get "$GF/notosansjp/NotoSansJP%5Bwght%5D.ttf" "$tmp/NotoSansJP/NotoSansJP[wght].ttf"
get "$GF/notosansjp/OFL.txt" "$tmp/NotoSansJP/OFL.txt"
get "$NERD" "$tmp/JetBrainsMono.tar.xz"
tar -xJf "$tmp/JetBrainsMono.tar.xz" -C "$tmp/JetBrainsMonoNerd"
rm "$tmp/JetBrainsMono.tar.xz"

echo "Installing into $dest"
SUDO=""
if [ "$mode" = --system ]; then SUDO=sudo; fi
for family in Rajdhani NotoSansJP JetBrainsMonoNerd; do
    $SUDO mkdir -p "$dest/$family"
    $SUDO cp -f "$tmp/$family"/* "$dest/$family/"
    $SUDO chmod 644 "$dest/$family"/*
done

if [ "$mode" != --dest ]; then
    echo "Refreshing font cache…"
    $SUDO fc-cache -f "$dest" >/dev/null
    for fam in "Rajdhani" "Noto Sans JP" "JetBrainsMono Nerd Font"; do
        if fc-list : family | grep -qi "^$fam"; then echo "  ✓ $fam"; else echo "  ✗ $fam not found"; fi
    done
fi
echo "Done."
