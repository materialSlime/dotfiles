#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  CYBERPUNK LOCK SCREEN — Dynamic Data Feed                  ║
# ║  Generates scrolling "data noise" like a hacker terminal    ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Outputs a single line of pseudo-random hex/system data that cycles,
# giving the lock screen a living, breathing cyberpunk terminal feel.

# Gather real system data fragments
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' | head -c 20)
LOAD=$(cat /proc/loadavg 2>/dev/null | cut -d' ' -f1-3)
MEM_USED=$(free -h 2>/dev/null | awk '/Mem:/ {print $3}')
MEM_TOTAL=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}')
NET_DEV=$(ip -br link show 2>/dev/null | grep -v "^lo" | head -1 | awk '{print $1}')
IP_ADDR=$(ip -4 addr show "$NET_DEV" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
HOSTNAME=$(cat /proc/sys/kernel/hostname 2>/dev/null || echo "unknown")
KERNEL=$(uname -r 2>/dev/null | head -c 25)

# Build a rotating data line based on current second
SEC=$(date +%-S)
MOD=$((SEC % 8))

case $MOD in
    0) echo "SYS.UPTIME :: $UPTIME   //  KERNEL $KERNEL" ;;
    1) echo "MEM.ALLOC :: $MEM_USED / $MEM_TOTAL   //  LOAD [$LOAD]" ;;
    2) echo "NET.IFACE :: $NET_DEV   //  ADDR $IP_ADDR" ;;
    3) echo "NODE :: $HOSTNAME   //  PID.ACTIVE $(ls /proc | grep -c '^[0-9]')" ;;
    4) echo "SEC.LAYER :: HYPRLOCK v$(hyprlock --version 2>/dev/null | head -c 10 || echo '?.?')" ;;
    5) echo "CPU.FREQ :: $(cat /proc/cpuinfo 2>/dev/null | grep 'MHz' | head -1 | awk '{print $4}') MHz" ;;
    6) echo "ENTROPY :: $(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null)   //  TASKS $(nproc)" ;;
    7) echo "CHRONO :: $(date +'%Y-%m-%dT%H:%M:%S%z')   //  EPOCH $(date +%s)" ;;
esac
