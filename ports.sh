#!/usr/bin/env bash
# ports — see what's listening, free a port.
#   ports            list all listening ports
#   ports 3000       show what's on port 3000
#   ports kill 3000  kill whatever is on port 3000

set -u

list() {
  printf '%-7s %-22s %-8s %s\n' "PORT" "PROCESS" "PID" "USER"
  lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | awk 'NR>1 {
      split($9, a, ":"); port = a[length(a)]
      if (!(port in seen)) { seen[port]=1; printf "%-7s %-22s %-8s %s\n", port, $1, $2, $3 }
    }' | sort -n
}

case "${1:-}" in
  "")   list ;;
  kill)
    port=${2:?usage: ports kill <port>}
    pids=$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null)
    if [[ -z "$pids" ]]; then echo "Nothing on port $port"; exit 0; fi
    for pid in $pids; do
      name=$(ps -p "$pid" -o comm= | xargs basename)
      kill "$pid" 2>/dev/null && echo "✓ Killed $name ($pid) on port $port" \
        || { kill -9 "$pid" 2>/dev/null && echo "✓ Force-killed $name ($pid) on port $port"; }
    done ;;
  *)    list | awk -v p="$1" 'NR==1 || $1==p' ;;
esac
