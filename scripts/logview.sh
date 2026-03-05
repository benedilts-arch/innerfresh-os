#!/bin/bash
# logview.sh — Log viewer CLI
#
# Usage:
#   logview.sh [--event <name>] [--level <l>] [--grep <text>]
#              [--since <ISO|"1h"|"24h"|"7d">] [--until <ISO>]
#              [--limit <n>] [--json] [--tail]

LOG_DIR="${LOG_DIR:-$HOME/.openclaw/workspace/data/logs}"

EVENT="" LEVEL="" GREP="" SINCE="" UNTIL="" LIMIT=100 JSON=false TAIL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event)  EVENT="$2"; shift 2 ;;
    --level)  LEVEL="$2"; shift 2 ;;
    --grep)   GREP="$2"; shift 2 ;;
    --since)  SINCE="$2"; shift 2 ;;
    --until)  UNTIL="$2"; shift 2 ;;
    --limit)  LIMIT="$2"; shift 2 ;;
    --json)   JSON=true; shift ;;
    --tail)   TAIL=true; shift ;;
    *) shift ;;
  esac
done

# Determine source file
if [ -n "$EVENT" ] && [ -f "$LOG_DIR/${EVENT}.jsonl" ]; then
  SRC="$LOG_DIR/${EVENT}.jsonl"
else
  SRC="$LOG_DIR/all.jsonl"
fi

if [ ! -f "$SRC" ]; then
  echo "No logs found at $SRC"
  exit 0
fi

if $TAIL; then
  tail -f "$SRC"
  exit 0
fi

python3 << PYEOF
import json, sys, re
from datetime import datetime, timezone, timedelta

src = "$SRC"
level_filter = "$LEVEL"
grep_filter = "$GREP"
since_raw = "$SINCE"
until_raw = "$UNTIL"
limit = int("$LIMIT")
json_out = $( $JSON && echo "True" || echo "False" )

def parse_since(s):
    if not s: return None
    m = re.match(r'^(\d+)([hd])$', s)
    if m:
        n, unit = int(m.group(1)), m.group(2)
        delta = timedelta(hours=n) if unit=='h' else timedelta(days=n)
        return datetime.now(timezone.utc) - delta
    try:
        return datetime.fromisoformat(s.replace('Z','+00:00'))
    except: return None

since_dt = parse_since(since_raw)
until_dt = parse_since(until_raw) if until_raw else None

results = []
with open(src) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            entry = json.loads(line)
        except: continue
        if level_filter and entry.get("level","") != level_filter: continue
        if grep_filter and grep_filter.lower() not in line.lower(): continue
        if since_dt:
            ts = datetime.fromisoformat(entry.get("ts","").replace('Z','+00:00'))
            if ts < since_dt: continue
        if until_dt:
            ts = datetime.fromisoformat(entry.get("ts","").replace('Z','+00:00'))
            if ts > until_dt: continue
        results.append(entry)

results = results[-limit:]

if json_out:
    print(json.dumps(results, indent=2))
else:
    LEVEL_ICONS = {"debug":"⚪","info":"🔵","warn":"🟡","error":"🔴","critical":"🚨"}
    for e in results:
        ts = e.get("ts","")[:19].replace("T"," ")
        icon = LEVEL_ICONS.get(e.get("level","info"), "•")
        event = e.get("event","?")
        msg = e.get("msg","")
        extras = {k:v for k,v in e.items() if k not in ("ts","event","level","msg")}
        extra_str = " | " + " ".join(f"{k}={v}" for k,v in extras.items()) if extras else ""
        print(f"{ts} {icon} [{event}] {msg}{extra_str}")
PYEOF
