#!/usr/bin/env bash
# mac-health — one-screen status of your Mac.

set -u

echo "🖥  $(scutil --get ComputerName)  ·  macOS $(sw_vers -productVersion)  ·  up $(uptime | sed -E 's/.*up ([^,]*),.*/\1/')"
echo

# Disk
read -r size used avail pct <<< "$(df -h / | awk 'NR==2 {print $2, $3, $4, $5}')"
echo "💾 Disk      $used used of $size  ($avail free, $pct)"

# Memory
total=$(( $(sysctl -n hw.memsize) / 1073741824 ))
pressure=$(memory_pressure 2>/dev/null | awk -F': ' '/System-wide memory free percentage/ {print $2}')
echo "🧠 Memory    ${total} GB total  ·  ${pressure:-?} free"

# Battery
if pmset -g batt | grep -q InternalBattery; then
  charge=$(pmset -g batt | grep -o '[0-9]*%' | head -1)
  state=$(pmset -g batt | grep -oE 'charging|discharging|charged' | head -1)
  cycles=$(system_profiler SPPowerDataType 2>/dev/null | awk -F': ' '/Cycle Count/ {print $2}')
  cond=$(system_profiler SPPowerDataType 2>/dev/null | awk -F': ' '/Condition/ {print $2}')
  echo "🔋 Battery   $charge ($state)  ·  $cycles cycles  ·  $cond"
fi

# Time Machine
tm=$(tmutil latestbackup 2>/dev/null)
if [[ -n "$tm" ]]; then
  echo "⏱  Backup    last Time Machine: ${tm##*/}"
else
  echo "⏱  Backup    no Time Machine backup found"
fi

# Network
ssid=$(ipconfig getsummary en0 2>/dev/null | awk -F' SSID : ' '/ SSID : / {print $2}')
ip=$(ipconfig getifaddr en0 2>/dev/null)
echo "📶 Network   ${ssid:-not on Wi-Fi}  ·  ${ip:-no IP}"

# Top CPU
echo
echo "🔥 Top CPU"
ps -Aro %cpu,comm | head -6 | tail -5 | awk '{printf "   %5s%%  %s\n", $1, $2}' | sed 's|/.*/||'

# Top memory
echo "📈 Top memory"
ps -Amo rss,comm | head -6 | tail -5 | awk '{printf "   %5d MB  %s\n", $1/1024, $2}' | sed 's|/.*/||'

# Listening ports (dev servers)
n=$(lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | awk 'NR>1' | wc -l | tr -d ' ')
echo
echo "🔌 $n listening ports  (run 'ports' to see them)"
