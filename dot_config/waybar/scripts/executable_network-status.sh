#!/usr/bin/env bash
# Show the active NetworkManager connection without relying on a stable Wi-Fi
# interface name. Prefer Wi-Fi when it is connected; otherwise show Ethernet.

set -u

devices=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true)

connected_device() {
  local type=$1
  printf '%s\n' "$devices" | awk -F: -v type="$type" \
    '$2 == type && $3 ~ /^connected/ { print $1; exit }'
}

first_value() {
  nmcli -g "$1" device show "$2" 2>/dev/null | sed -n '1p'
}

json_escape() {
  sed ':a;N;$!ba;s/\\/\\\\/g;s/"/\\"/g;s/\n/\\n/g'
}

wifi=$(connected_device wifi)
ethernet=$(connected_device ethernet)

if [[ -n $wifi ]]; then
  connection=$(first_value GENERAL.CONNECTION "$wifi")
  address=$(first_value IP4.ADDRESS "$wifi")
  gateway=$(first_value IP4.GATEWAY "$wifi")
  dns=$(first_value IP4.DNS "$wifi")
  signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list ifname "$wifi" 2>/dev/null |
    awk -F: '$1 == "*" { print $2; exit }')
  signal=${signal:-0}

  if ((signal <= 20)); then
    icon='󰤯'
  elif ((signal <= 40)); then
    icon='󰤟'
  elif ((signal <= 60)); then
    icon='󰤢'
  elif ((signal <= 80)); then
    icon='󰤥'
  else
    icon='󰤨'
  fi

  tooltip=$(printf 'Wi-Fi: %s\nSignal: %s%%\nInterface: %s\n\nIP: %s\nGateway: %s \nDNS: %s' \
    "$connection" "$signal" "$wifi" "${address:-Unavailable}" "${gateway:-Unavailable}" "${dns:-Unavailable}" | json_escape)
  printf '{"text":"%s","tooltip":"%s","class":"wifi"}\n' "$icon" "$tooltip"

elif [[ -n $ethernet ]]; then
  connection=$(first_value GENERAL.CONNECTION "$ethernet")
  address=$(first_value IP4.ADDRESS "$ethernet")
  gateway=$(first_value IP4.GATEWAY "$ethernet")
  dns=$(first_value IP4.DNS "$ethernet")
  tooltip=$(printf 'Interface: %s\n\nIP: %s\nGateway: %s\nDNS: %s' \
    "$ethernet" "${address:-Unavailable}" "${gateway:-Unavailable}" "${dns:-Unavailable}" | json_escape)
  printf '{"text":"󰈀","tooltip":"%s","class":"ethernet"}\n' "$tooltip"
else
  printf '%s\n' '{"text":"","tooltip":"No network connection","class":"disconnected"}'
fi
