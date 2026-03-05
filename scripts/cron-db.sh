#!/bin/bash
# cron-db.sh — Central cron log database (SQLite)
# Usage:
#   cron-db.sh init
#   cron-db.sh log-start <job_name>          → returns run_id
#   cron-db.sh log-end <run_id> <status> [summary]
#   cron-db.sh query [--job <name>] [--status <ok|fail>] [--limit <n>]
#   cron-db.sh should-run <job_name> <window>  → window: daily|hourly
#   cron-db.sh cleanup-stale
#   cron-db.sh failure-count <job_name> <hours>

DB="${CRON_DB:-$HOME/.openclaw/workspace/data/cron.db}"
mkdir -p "$(dirname "$DB")"

sql() { sqlite3 "$DB" "$@"; }

case "$1" in
  init)
    sql "
      CREATE TABLE IF NOT EXISTS cron_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'running',
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        duration_ms INTEGER,
        summary TEXT
      );
      CREATE INDEX IF NOT EXISTS idx_job ON cron_runs(job_name);
      CREATE INDEX IF NOT EXISTS idx_status ON cron_runs(status);
    "
    echo "DB initialized: $DB"
    ;;

  log-start)
    JOB="$2"
    NOW=$(python3 -c "import time; print(int(time.time()*1000))")
    RUN_ID=$(sql "INSERT INTO cron_runs(job_name, status, started_at) VALUES('$JOB', 'running', $NOW); SELECT last_insert_rowid();")
    # Auto cleanup stale jobs
    STALE_CUTOFF=$(( $(python3 -c "import time; print(int(time.time()*1000))") - 7200000 ))
    sql "UPDATE cron_runs SET status='failed', summary='auto-marked stale', ended_at=$NOW WHERE status='running' AND started_at < $STALE_CUTOFF AND id != $RUN_ID;"
    echo "$RUN_ID"
    ;;

  log-end)
    RUN_ID="$2"
    STATUS="$3"
    SUMMARY="${4:-}"
    NOW=$(python3 -c "import time; print(int(time.time()*1000))")
    sql "SELECT started_at FROM cron_runs WHERE id=$RUN_ID;" | read STARTED
    STARTED=$(sql "SELECT started_at FROM cron_runs WHERE id=$RUN_ID;")
    DURATION=$(( NOW - STARTED ))
    sql "UPDATE cron_runs SET status='$STATUS', ended_at=$NOW, duration_ms=$DURATION, summary='$(echo "$SUMMARY" | sed "s/'/''/g")' WHERE id=$RUN_ID;"
    ;;

  should-run)
    JOB="$2"
    WINDOW="${3:-daily}"
    if [ "$WINDOW" = "daily" ]; then
      TODAY=$(date +%Y-%m-%d)
      CUTOFF=$(date -j -f "%Y-%m-%d" "$TODAY" +%s%3N 2>/dev/null || date -d "$TODAY" +%s%3N)
    else
      CUTOFF=$(( $(python3 -c "import time; print(int(time.time()*1000))") - 3600000 ))
    fi
    COUNT=$(sql "SELECT COUNT(*) FROM cron_runs WHERE job_name='$JOB' AND status='ok' AND started_at > $CUTOFF;")
    if [ "$COUNT" -gt 0 ]; then
      echo "skip"
    else
      echo "run"
    fi
    ;;

  query)
    WHERE="1=1"
    LIMIT=20
    shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --job) WHERE="$WHERE AND job_name='$2'"; shift 2 ;;
        --status) WHERE="$WHERE AND status='$2'"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    sql "SELECT id, job_name, status, datetime(started_at/1000,'unixepoch','+4 hours'), duration_ms, summary FROM cron_runs WHERE $WHERE ORDER BY started_at DESC LIMIT $LIMIT;" | column -t -s '|'
    ;;

  failure-count)
    JOB="$2"
    HOURS="${3:-6}"
    CUTOFF=$(( $(python3 -c "import time; print(int(time.time()*1000))") - (HOURS * 3600000) ))
    sql "SELECT COUNT(*) FROM cron_runs WHERE job_name='$JOB' AND status='failed' AND started_at > $CUTOFF;"
    ;;

  cleanup-stale)
    NOW=$(python3 -c "import time; print(int(time.time()*1000))")
    CUTOFF=$(( NOW - 7200000 ))
    COUNT=$(sql "UPDATE cron_runs SET status='failed', summary='stale cleanup', ended_at=$NOW WHERE status='running' AND started_at < $CUTOFF; SELECT changes();")
    echo "Marked $COUNT stale runs as failed"
    ;;

  *)
    echo "Usage: cron-db.sh {init|log-start|log-end|query|should-run|cleanup-stale|failure-count}"
    exit 1
    ;;
esac
