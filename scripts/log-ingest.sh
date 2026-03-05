#!/bin/bash
# log-ingest.sh — Nightly JSONL → SQLite ingest + rotation
#
# Usage:
#   log-ingest.sh ingest      — parse JSONL into structured_logs table
#   log-ingest.sh rotate      — rotate large files, archive old records
#   log-ingest.sh init
#   log-ingest.sh stats

DB="${LOG_DB:-$HOME/.openclaw/workspace/data/logs.db}"
LOG_DIR="${LOG_DIR:-$HOME/.openclaw/workspace/data/logs}"
ARCHIVE_DIR="$HOME/.openclaw/workspace/data/log-archives"
MAX_SIZE_MB=50
KEEP_ROTATIONS=3

mkdir -p "$(dirname "$DB")" "$ARCHIVE_DIR"
sql() { sqlite3 "$DB" "$@"; }

case "$1" in
  init)
    sql "
      CREATE TABLE IF NOT EXISTS structured_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts TEXT NOT NULL,
        event TEXT NOT NULL,
        level TEXT NOT NULL,
        msg TEXT,
        fields TEXT,
        source_file TEXT,
        ingested_at INTEGER DEFAULT (strftime('%s','now')),
        UNIQUE(ts, event, msg)
      );
      CREATE TABLE IF NOT EXISTS raw_server_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        log_date TEXT,
        level TEXT,
        line TEXT NOT NULL,
        source TEXT,
        ingested_at INTEGER DEFAULT (strftime('%s','now')),
        UNIQUE(log_date, line)
      );
      CREATE INDEX IF NOT EXISTS idx_sl_event ON structured_logs(event);
      CREATE INDEX IF NOT EXISTS idx_sl_level ON structured_logs(level);
      CREATE INDEX IF NOT EXISTS idx_sl_ts ON structured_logs(ts);
    "
    echo "Log DB initialized: $DB"
    ;;

  ingest)
    bash "$0" init 2>/dev/null
    TOTAL=0
    DUPES=0

    # Ingest all JSONL files
    for FILE in "$LOG_DIR"/*.jsonl; do
      [ -f "$FILE" ] || continue
      SOURCE=$(basename "$FILE")
      python3 << PYEOF
import json, sqlite3, os
db = sqlite3.connect("$DB")
file = "$FILE"
source = "$SOURCE"
total = dupes = 0

with open(file) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            e = json.loads(line)
        except: continue
        ts    = e.pop("ts", "")
        event = e.pop("event", source.replace(".jsonl",""))
        level = e.pop("level", "info")
        msg   = e.pop("msg", "")
        fields = json.dumps(e) if e else None
        try:
            db.execute(
                "INSERT OR IGNORE INTO structured_logs(ts,event,level,msg,fields,source_file) VALUES(?,?,?,?,?,?)",
                (ts, event, level, msg, fields, source)
            )
            if db.execute("SELECT changes()").fetchone()[0] == 0:
                dupes += 1
            else:
                total += 1
        except: dupes += 1

db.commit()
db.close()
print(f"  {source}: +{total} rows ({dupes} dupes skipped)")
PYEOF
    done

    # Ingest OpenClaw gateway log
    GATEWAY_LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
    if [ -f "$GATEWAY_LOG" ]; then
      python3 << PYEOF
import sqlite3, os, re
from datetime import datetime
db = sqlite3.connect("$DB")
file = "$GATEWAY_LOG"
inserted = 0

with open(file, errors='replace') as f:
    for line in f:
        line = line.rstrip()
        if not line: continue
        level = "info"
        if re.search(r'\berror\b', line, re.I): level = "error"
        elif re.search(r'\bwarn\b', line, re.I): level = "warn"
        log_date = datetime.now().strftime("%Y-%m-%d")
        try:
            db.execute(
                "INSERT OR IGNORE INTO raw_server_logs(log_date,level,line,source) VALUES(?,?,?,?)",
                (log_date, level, line[:2000], "openclaw-gateway")
            )
            inserted += 1
        except: pass

db.commit()
db.close()
print(f"  gateway log: +{inserted} lines")
PYEOF
    fi
    ;;

  rotate)
    MONTH=$(python3 -c "from datetime import datetime; print(datetime.now().strftime('%Y-%m'))")

    for FILE in "$LOG_DIR"/*.jsonl; do
      [ -f "$FILE" ] || continue
      SIZE_MB=$(python3 -c "import os; print(os.path.getsize('$FILE') / 1048576)")
      OVER=$(python3 -c "print('yes' if $SIZE_MB > $MAX_SIZE_MB else 'no')")

      if [ "$OVER" = "yes" ]; then
        BASENAME=$(basename "$FILE" .jsonl)
        ARCHIVE="$ARCHIVE_DIR/${BASENAME}-${MONTH}.jsonl.gz"
        gzip -c "$FILE" > "$ARCHIVE"
        : > "$FILE"  # Truncate (don't delete)
        echo "Rotated $BASENAME (${SIZE_MB}MB) → $ARCHIVE"

        # Keep only last N rotations
        ls -t "$ARCHIVE_DIR/${BASENAME}-"*.jsonl.gz 2>/dev/null | tail -n +$((KEEP_ROTATIONS+1)) | xargs rm -f 2>/dev/null
      fi
    done

    # Archive old structured_logs rows (>90 days)
    CUTOFF=$(python3 -c "from datetime import datetime, timedelta, timezone; print((datetime.now(timezone.utc)-timedelta(days=90)).isoformat())")
    ARCHIVE_DB="$ARCHIVE_DIR/logs-$MONTH.db"
    sqlite3 "$ARCHIVE_DB" "CREATE TABLE IF NOT EXISTS structured_logs AS SELECT * FROM structured_logs WHERE 0;" 2>/dev/null
    COUNT=$(sql "SELECT COUNT(*) FROM structured_logs WHERE ts < '$CUTOFF';")
    if [ "$COUNT" -gt 0 ]; then
      sql ".dump structured_logs" | grep "INSERT" | sqlite3 "$ARCHIVE_DB" 2>/dev/null
      sql "DELETE FROM structured_logs WHERE ts < '$CUTOFF';"
      echo "Archived $COUNT old log rows to $ARCHIVE_DB"
    fi
    ;;

  stats)
    echo "=== Log Stats ==="
    echo ""
    echo "── JSONL files ──"
    du -sh "$LOG_DIR"/*.jsonl 2>/dev/null | sort -h
    echo ""
    echo "── SQLite tables ──"
    sql "SELECT 'structured_logs', COUNT(*) FROM structured_logs;" | tr '|' '\t'
    sql "SELECT 'raw_server_logs', COUNT(*) FROM raw_server_logs;" | tr '|' '\t'
    echo ""
    echo "── Recent errors ──"
    sql "SELECT ts, event, msg FROM structured_logs WHERE level='error' ORDER BY ts DESC LIMIT 5;" | column -t -s '|'
    ;;

  *)
    echo "Usage: log-ingest.sh {init|ingest|rotate|stats}"
    exit 1
    ;;
esac
