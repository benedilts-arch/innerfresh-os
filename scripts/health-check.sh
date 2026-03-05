#!/bin/bash
# health-check.sh — System health check with exponential backoff alerting
#
# Usage:
#   health-check.sh           — run all checks, alert on new failures
#   health-check.sh --full    — run all checks, print full report
#   health-check.sh --reset   — clear alert backoff state
#
# State file: data/health-state.json
# Tracks last-alerted timestamp per failure type for backoff

WORKSPACE="$HOME/.openclaw/workspace"
SCRIPTS="$WORKSPACE/scripts"
DATA="$WORKSPACE/data"
STATE_FILE="$DATA/health-state.json"
PASS=0; FAIL=0
ALERTS=()
FULL=false
[[ "$1" == "--full" ]] && FULL=true
[[ "$1" == "--reset" ]] && echo '{}' > "$STATE_FILE" && echo "Alert state cleared." && exit 0

mkdir -p "$DATA"
[ ! -f "$STATE_FILE" ] && echo '{}' > "$STATE_FILE"

NOW=$(python3 -c "import time; print(int(time.time()))")

pass() { echo "✅ $1"; PASS=$((PASS+1)); }
fail() {
  echo "❌ $1"; FAIL=$((FAIL+1))
  ALERTS+=("$1")
}

# ── Exponential backoff ───────────────────────────────────────────────────────
# Returns 0 (should alert) or 1 (still in backoff window)
should_alert() {
  local KEY="$1"
  python3 -c "
import json, time, sys
key = sys.argv[1]
now = int(time.time())
try:
    state = json.load(open('$STATE_FILE'))
except:
    state = {}
entry = state.get(key, {})
last = entry.get('last_alerted', 0)
count = entry.get('count', 0)
# Backoff: 5min, 15min, 1h, 4h, 24h
backoff_mins = [5, 15, 60, 240, 1440]
backoff_secs = backoff_mins[min(count, len(backoff_mins)-1)] * 60
if now - last > backoff_secs:
    # Update state
    state[key] = {'last_alerted': now, 'count': count + 1}
    with open('$STATE_FILE', 'w') as f:
        json.dump(state, f)
    sys.exit(0)  # should alert
sys.exit(1)  # still in backoff
" "$KEY" 2>/dev/null
}

clear_alert() {
  local KEY="$1"
  python3 -c "
import json, sys
key = sys.argv[1]
try:
    state = json.load(open('$STATE_FILE'))
    if key in state:
        del state[key]
        with open('$STATE_FILE', 'w') as f:
            json.dump(state, f)
except: pass
" "$KEY" 2>/dev/null
}

# ── 1. Gateway process ────────────────────────────────────────────────────────
if openclaw gateway status 2>/dev/null | grep -q "loaded"; then
  pass "Gateway process running"
  clear_alert "gateway_down"
else
  fail "Gateway process not running"
fi

# ── 2. Gateway port reachable ─────────────────────────────────────────────────
if curl -s --max-time 3 http://127.0.0.1:18789/ >/dev/null 2>&1 || \
   nc -z 127.0.0.1 18789 2>/dev/null; then
  pass "Gateway port 18789 reachable"
  clear_alert "gateway_port"
else
  fail "Gateway port 18789 not reachable"
fi

# ── 3. LLM failure rate (last hour) ──────────────────────────────────────────
LLM_STATS=$(sqlite3 "$DATA/llm.db" "
  SELECT
    COUNT(*) as total,
    SUM(CASE WHEN status='failed' THEN 1 ELSE 0 END) as failures
  FROM llm_calls
  WHERE created_at > $(( NOW - 3600 ));" 2>/dev/null)

if [ -n "$LLM_STATS" ]; then
  TOTAL=$(echo "$LLM_STATS" | cut -d'|' -f1)
  FAILURES=$(echo "$LLM_STATS" | cut -d'|' -f2)
  if [ "${TOTAL:-0}" -gt 0 ] && [ "${FAILURES:-0}" -gt 0 ]; then
    RATE=$(python3 -c "print(round(${FAILURES:-0}/${TOTAL:-1}*100,1))")
    [ "$(python3 -c "print(1 if ${FAILURES:-0}/${TOTAL:-1} > 0.3 else 0)")" = "1" ] \
      && fail "LLM failure rate ${RATE}% in last hour ($FAILURES/$TOTAL)" \
      || pass "LLM calls: $TOTAL in last hour, $FAILURES failures (${RATE}%)"
  else
    pass "LLM: no failures in last hour"
  fi
else
  pass "LLM: no calls in last hour (DB new or empty)"
fi

# ── 4. Structured event log errors (last hour) ────────────────────────────────
RECENT_ERRORS=$(sqlite3 "$DATA/logs.db" "
  SELECT event, msg FROM structured_logs
  WHERE level='error' AND event NOT LIKE '%-test%' AND ts > datetime('now','-1 hour')
  LIMIT 5;" 2>/dev/null)

if [ -n "$RECENT_ERRORS" ]; then
  COUNT=$(echo "$RECENT_ERRORS" | wc -l | tr -d ' ')
  fail "Structured log errors in last hour: $COUNT"
  $FULL && echo "$RECENT_ERRORS" | sed 's/^/    /'
else
  pass "No structured log errors in last hour"
fi

# ── 5. Gateway log errors (last hour only) ───────────────────────────────────
GW_LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
if [ -f "$GW_LOG" ]; then
  GW_ERRORS=$(tail -500 "$GW_LOG" | python3 "$SCRIPTS/parse-gateway-errors.py" 2>/dev/null)
  if [ -n "$GW_ERRORS" ]; then
    fail "Gateway log has errors in the last hour"
    $FULL && echo "$GW_ERRORS" | sed 's/^/    /'
  else
    pass "Gateway log clean (no errors in last hour)"
  fi
else
  pass "Gateway log not yet created today"
fi

# ── 6. Cron persistent failures ───────────────────────────────────────────────
PERSIST_FAILS=$(sqlite3 "$DATA/cron.db" "
  SELECT job_name, COUNT(*) as cnt
  FROM cron_runs
  WHERE status='failed' AND started_at > $(( NOW - 21600 ))
  GROUP BY job_name
  HAVING cnt >= 3;" 2>/dev/null)

if [ -n "$PERSIST_FAILS" ]; then
  fail "Persistent cron failures: $PERSIST_FAILS"
else
  pass "No persistent cron failures in last 6h"
fi

# ── 7. Disk usage ─────────────────────────────────────────────────────────────
DB_TOTAL=$(du -sm "$DATA"/*.db "$DATA/logs/"*.jsonl 2>/dev/null | awk '{sum+=$1} END{print sum+0}')
[ "${DB_TOTAL:-0}" -gt 500 ] \
  && fail "Data directory large: ${DB_TOTAL}MB (threshold 500MB)" \
  || pass "Data directory size: ${DB_TOTAL}MB"

# ── 8. Backup freshness ───────────────────────────────────────────────────────
LATEST_BACKUP=$(ls -t "$HOME/backups/openclaw/archives/"*.enc 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
  BACKUP_AGE=$(python3 -c "import os,time; print(int((time.time()-os.path.getmtime('$LATEST_BACKUP'))/3600))")
  [ "${BACKUP_AGE:-99}" -gt 25 ] \
    && fail "Latest backup is ${BACKUP_AGE}h old (hourly backup may have stopped)" \
    || pass "Latest backup: ${BACKUP_AGE}h ago"
else
  fail "No backups found"
fi

# ── Summary & alerting ────────────────────────────────────────────────────────
echo ""
echo "=== Health Check: $PASS passed, $FAIL failed ==="

if [ ${#ALERTS[@]} -gt 0 ]; then
  # Only alert for failures not recently reported (backoff)
  NEW_ALERTS=()
  for ALERT in "${ALERTS[@]}"; do
    KEY=$(echo "$ALERT" | tr ' ' '_' | cut -c1-40)
    should_alert "$KEY" && NEW_ALERTS+=("$ALERT")
  done

  if [ ${#NEW_ALERTS[@]} -gt 0 ]; then
    MSG="🩺 Health check: ${FAIL} issue(s)"$'\n'
    for A in "${NEW_ALERTS[@]}"; do MSG+="• $A"$'\n'; done
    bash "$SCRIPTS/notify.sh" enqueue "$MSG" --tier high --type system 2>/dev/null
    echo "Alerts queued: ${#NEW_ALERTS[@]} new"
  else
    echo "Failures found but all within backoff window — not re-alerting"
  fi
fi

[ $FAIL -gt 0 ] && exit 1 || exit 0
