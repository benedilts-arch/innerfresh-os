#!/bin/bash
# cron-wrap.sh — Cron wrapper with lockfile, signal traps, timeout, and DB logging
#
# Usage: cron-wrap.sh --job <name> [--timeout <seconds>] [--window daily|hourly] -- <command> [args...]
#
# Example:
#   cron-wrap.sh --job morning-briefing --timeout 120 -- bash ~/scripts/morning.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_DB="$SCRIPT_DIR/cron-db.sh"
LOCK_DIR="${HOME}/.openclaw/workspace/data/locks"
mkdir -p "$LOCK_DIR"

JOB=""
TIMEOUT=""
WINDOW="daily"
CMD=()

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --job) JOB="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --window) WINDOW="$2"; shift 2 ;;
    --) shift; CMD=("$@"); break ;;
    *) shift ;;
  esac
done

if [ -z "$JOB" ] || [ ${#CMD[@]} -eq 0 ]; then
  echo "Usage: cron-wrap.sh --job <name> [--timeout <sec>] [--window daily|hourly] -- <command>"
  exit 1
fi

# Init DB if needed
"$CRON_DB" init 2>/dev/null

# Idempotency check
SHOULD=$("$CRON_DB" should-run "$JOB" "$WINDOW")
if [ "$SHOULD" = "skip" ]; then
  echo "[cron-wrap] $JOB already ran this $WINDOW, skipping."
  exit 0
fi

# Lockfile (PID-based)
LOCK="$LOCK_DIR/${JOB}.pid"
if [ -f "$LOCK" ]; then
  OLD_PID=$(cat "$LOCK")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[cron-wrap] $JOB already running (PID $OLD_PID). Exiting."
    exit 1
  else
    echo "[cron-wrap] Removing stale lockfile for PID $OLD_PID"
    rm -f "$LOCK"
  fi
fi

echo $$ > "$LOCK"

# Log start
RUN_ID=$("$CRON_DB" log-start "$JOB")

# Signal traps — clean shutdown
cleanup() {
  echo "[cron-wrap] $JOB interrupted."
  "$CRON_DB" log-end "$RUN_ID" "failed" "interrupted by signal"
  rm -f "$LOCK"
  exit 1
}
trap cleanup SIGTERM SIGINT SIGHUP

# Run command
if [ -n "$TIMEOUT" ]; then
  OUTPUT=$(gtimeout "$TIMEOUT" "${CMD[@]}" 2>&1)
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 124 ]; then
    "$CRON_DB" log-end "$RUN_ID" "failed" "timed out after ${TIMEOUT}s"
    rm -f "$LOCK"

    # Persistent failure check
    FAIL_COUNT=$("$CRON_DB" failure-count "$JOB" 6)
    if [ "$FAIL_COUNT" -ge 3 ]; then
      echo "🔴 PERSISTENT FAILURE: $JOB has failed $FAIL_COUNT times in the last 6 hours."
    fi
    exit 124
  fi
else
  OUTPUT=$("${CMD[@]}" 2>&1)
  EXIT_CODE=$?
fi

# Log result
if [ $EXIT_CODE -eq 0 ]; then
  "$CRON_DB" log-end "$RUN_ID" "ok" "$(echo "$OUTPUT" | tail -1)"
else
  "$CRON_DB" log-end "$RUN_ID" "failed" "exit $EXIT_CODE: $(echo "$OUTPUT" | tail -2)"

  # Persistent failure alert
  FAIL_COUNT=$("$CRON_DB" failure-count "$JOB" 6)
  if [ "$FAIL_COUNT" -ge 3 ]; then
    echo "🔴 PERSISTENT FAILURE: $JOB has failed $FAIL_COUNT times in the last 6 hours."
  fi
fi

rm -f "$LOCK"
exit $EXIT_CODE
