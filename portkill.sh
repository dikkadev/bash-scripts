
portkill() {
  if [ $# -eq 0 ]; then
    echo "usage: portkill <port> [port ...]"
    return 1
  fi

  for port in "$@"; do
    printf "Port %s:\n" "$port"

    # try lsof first (returns only PIDs)
    pids=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null || true)

    # fallback to ss parsing if lsof not available or found nothing
    if [ -z "$pids" ]; then
      pids=$(ss -ltnp 2>/dev/null | awk -v p=":$port" '
        $0 ~ p {
          for (i=1;i<=NF;i++) {
            if ($i ~ /pid=/) {
              gsub(/pid=|,/,"",$i)
              split($i, a, "=")
              print a[2]
            }
          }
        }' | sort -u)
    fi

    if [ -z "$pids" ]; then
      echo "  no listening process found"
      continue
    fi

    for pid in $pids; do
      # show who/what the PID is
      if psout=$(ps -p "$pid" -o pid= -o user= -o cmd= 2>/dev/null); then
        echo "  -> PID $pid: $psout"
      else
        echo "  -> PID $pid: (process vanished)"
        continue
      fi

      # try polite kill first
      if kill "$pid" 2>/dev/null; then
        sleep 0.3
        if kill -0 "$pid" 2>/dev/null; then
          echo "    still alive; escalating to SIGKILL"
          # try with sudo if needed
          if ! kill -9 "$pid" 2>/dev/null; then
            sudo kill -9 "$pid" 2>/dev/null || echo "    failed to kill PID $pid (permission?)"
          fi
        else
          echo "    terminated (SIGTERM)"
        fi
      else
        echo "    SIGTERM failed, trying sudo SIGTERM"
        if sudo kill "$pid" 2>/dev/null; then
          sleep 0.3
          if kill -0 "$pid" 2>/dev/null; then
            echo "    still alive after sudo SIGTERM; sudo SIGKILL now"
            sudo kill -9 "$pid" 2>/dev/null || echo "    failed to sudo kill PID $pid"
          else
            echo "    terminated (sudo SIGTERM)"
          fi
        else
          echo "    cannot send signal to PID $pid (permission or not found)"
        fi
      fi
    done
  done
}
