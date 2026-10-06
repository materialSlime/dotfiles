#!/bin/env bash
# deviceName
# deviceStatus
# while read -r line; do
#   lineArr=($(grep -oP "([\w]{2}:){5}[\w]{2} Connected: (no|yes)" <<<"$line"))
#   if [[ -n ${lineArr[0]} ]]; then
#     deviceStatus="${lineArr[-1]}"
#     while read -r device; do
#       deviceArr=($device)
#       if [[ ${deviceArr[1]} == ${lineArr[0]} ]]; then
#         deviceName="${deviceArr[@]:2}"
#       fi
#     done < <(bluetoothctl devices)
#   fi
#   if [[ $deviceStatus == "yes" ]]; then
#     swayosd-client --custom-message "Connected: $deviceName" --custom-icon "bluetooth-active"
#   elif [[ $deviceStatus == "no" ]]; then
#     swayosd-client --custom-message "Disconnected: $deviceName" --custom-icon "bluetooth-deactive"
#   fi
#   # done < <(cat ./test.logs)
# done < <(bluetoothctl)
while read -r line; do

  # 2. Check for the specific "Connected: yes" event
  if [[ "$line" == *"Connected: yes"* ]]; then

    # 3. Extract the MAC address (it's the 3rd word in the line)
    # The line is: [CHG] Device AA:BB:CC:DD:EE:FF Connected: yes
    MAC=$(echo "$line" | awk '{print $3}')

    # 4. Ask bluetoothctl for the info on that specific MAC address,
    # and search for the "Name:" line to extract it.
    DEVICE_NAME=$(bluetoothctl info "$MAC" | grep "Name:" | awk -F ': ' '{print $2}')
    # 5. Trigger your SwayOSD card!
    swayosd-client --custom-message "Bluetooth: $DEVICE_NAME" --custom-icon "bluetooth-active"

  fi

  # Optional: Do the exact same thing for Disconnects!
  if [[ "$line" == *"Connected: no"* ]]; then
    MAC=$(echo "$line" | awk '{print $3}')
    DEVICE_NAME=$(bluetoothctl info "$MAC" | grep "Name:" | awk -F ': ' '{print $2}')
    swayosd-client --custom-message "Disconnected: $DEVICE_NAME" --custom-icon "bluetooth-disabled"
  fi

done < <(bluetoothctl)
