#!/bin/bash
# health-pipeline.sh — Pull all health sources, append to timeline, analyze
#
# Usage:
#   health-pipeline.sh sync           — pull all configured sources
#   health-pipeline.sh analyze [days] — LLM analysis on recent timeline
#   health-pipeline.sh trends [days]  — trend flags without LLM
#   health-pipeline.sh summary        — quick stats from timeline
#   health-pipeline.sh init           — create DB and directories

HEALTH_DIR="$HOME/.openclaw/workspace/health"
CONNECTORS="$HEALTH_DIR/connectors"
TIMELINE="$HEALTH_DIR/health-timeline.jsonl"
SCRIPTS="$HOME/.openclaw/workspace/scripts"
DB="$HOME/.openclaw/workspace/data/health.db"

_log() { bash "$SCRIPTS/log.sh" --event health-pipeline --level "$1" --msg "$2" 2>/dev/null; echo "[$1] $2"; }

case "$1" in
  init)
    mkdir -p "$HEALTH_DIR/connectors" "$HOME/.config/health"
    sqlite3 "$DB" "
      CREATE TABLE IF NOT EXISTS health_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        source TEXT NOT NULL,
        metric TEXT NOT NULL,
        value REAL,
        value_text TEXT,
        unit TEXT,
        imported_at INTEGER DEFAULT (strftime('%s','now')),
        UNIQUE(timestamp, source, metric)
      );
      CREATE INDEX IF NOT EXISTS idx_hm_metric ON health_metrics(metric);
      CREATE INDEX IF NOT EXISTS idx_hm_ts ON health_metrics(timestamp);
      CREATE INDEX IF NOT EXISTS idx_hm_source ON health_metrics(source);
    "
    _log "info" "Health DB initialized"

    # Create config template if not exists
    if [ ! -f "$HOME/.config/health/config.sh" ]; then
      cp "$HEALTH_DIR/health-config.sh" "$HOME/.config/health/config.sh"
      chmod 600 "$HOME/.config/health/config.sh"
      _log "info" "Config template created at ~/.config/health/config.sh — fill in your tokens"
    fi
    ;;

  sync)
    bash "$0" init 2>/dev/null
    source "$HOME/.config/health/config.sh" 2>/dev/null
    TOTAL=0

    # ── Oura ────────────────────────────────────────────────────────────────
    if [ -n "$OURA_TOKEN" ]; then
      _log "info" "Pulling Oura data..."
      python3 "$CONNECTORS/oura.py" --days 7 2>/dev/null >> "$TIMELINE"
      OURA_COUNT=$(python3 "$CONNECTORS/oura.py" --days 7 2>/dev/null | wc -l | tr -d ' ')
      _log "info" "Oura: $OURA_COUNT records"
      TOTAL=$((TOTAL + OURA_COUNT))
    else
      _log "info" "Oura: not configured (set OURA_TOKEN)"
    fi

    # ── Apple Health ────────────────────────────────────────────────────────
    if [ -n "$APPLE_HEALTH_EXPORT" ] && [ -d "$APPLE_HEALTH_EXPORT" ]; then
      _log "info" "Importing Apple Health export..."
      python3 "$CONNECTORS/apple_health.py" --export "$APPLE_HEALTH_EXPORT" --days 7 2>/dev/null >> "$TIMELINE"
      _log "info" "Apple Health: import complete"
    else
      _log "info" "Apple Health: not configured (set APPLE_HEALTH_EXPORT)"
    fi

    # ── Withings ────────────────────────────────────────────────────────────
    if [ -n "$WITHINGS_ACCESS_TOKEN" ]; then
      _log "info" "Pulling Withings data..."
      python3 "$CONNECTORS/withings.py" --days 30 2>/dev/null >> "$TIMELINE"
      _log "info" "Withings: import complete"
    else
      _log "info" "Withings: not configured (set WITHINGS_ACCESS_TOKEN)"
    fi

    # ── Ingest timeline → SQLite ────────────────────────────────────────────
    if [ -f "$TIMELINE" ]; then
      python3 << PYEOF
import json, sqlite3
db = sqlite3.connect("$DB")
imported = dupes = 0
with open("$TIMELINE") as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            r = json.loads(line)
            val_num = float(r['value']) if isinstance(r['value'], (int, float)) else None
            val_txt = str(r['value']) if not isinstance(r['value'], (int, float)) else None
            db.execute(
                "INSERT OR IGNORE INTO health_metrics(timestamp,source,metric,value,value_text,unit) VALUES(?,?,?,?,?,?)",
                (r['timestamp'], r['source'], r['metric'], val_num, val_txt, r.get('unit',''))
            )
            if db.execute("SELECT changes()").fetchone()[0]: imported += 1
            else: dupes += 1
        except: dupes += 1
db.commit()
db.close()
print(f"DB ingest: +{imported} new, {dupes} dupes skipped")
PYEOF
    fi

    _log "info" "Sync complete"
    ;;

  trends)
    DAYS="${2:-30}"
    echo "=== Health Trends (last $DAYS days) ==="
    python3 << PYEOF
import sqlite3, json
from datetime import datetime, timedelta, timezone
db = sqlite3.connect("$DB")
cutoff = (datetime.now(timezone.utc) - timedelta(days=$DAYS)).isoformat()

def avg(metric):
    row = db.execute(
        "SELECT AVG(value), MIN(value), MAX(value), COUNT(*) FROM health_metrics WHERE metric=? AND timestamp > ?",
        (metric, cutoff)
    ).fetchone()
    return row

def trend(metric):
    """Simple linear trend: positive=improving, negative=worsening"""
    rows = db.execute(
        "SELECT timestamp, value FROM health_metrics WHERE metric=? AND timestamp > ? AND value IS NOT NULL ORDER BY timestamp",
        (metric, cutoff)
    ).fetchall()
    if len(rows) < 3: return None
    n = len(rows)
    # Mean of first half vs second half
    first_half = [r[1] for r in rows[:n//2]]
    second_half = [r[1] for r in rows[n//2:]]
    delta = sum(second_half)/len(second_half) - sum(first_half)/len(first_half)
    return delta

metrics_to_check = [
    ("average_hrv", "HRV", "ms", True),      # higher = better
    ("sleep_score", "Sleep Score", "score", True),
    ("readiness_score", "Readiness", "score", True),
    ("resting_hr", "Resting HR", "bpm", False),  # lower = better
    ("steps", "Steps", "count", True),
    ("weight", "Weight", "kg", None),            # neutral
    ("body_fat", "Body Fat", "%", False),
]

flags = []
for metric, label, unit, higher_is_better in metrics_to_check:
    stats = avg(metric)
    if not stats or stats[3] == 0: continue
    mean, mn, mx, cnt = stats
    delta = trend(metric)

    direction = ""
    if delta is not None and abs(delta) > 0.5:
        if (delta > 0 and higher_is_better) or (delta < 0 and higher_is_better is False):
            direction = "📈 trending up"
        elif (delta < 0 and higher_is_better) or (delta > 0 and higher_is_better is False):
            direction = "📉 trending down ⚠️"
            flags.append(f"{label} declining")

    print(f"  {label}: avg={mean:.1f} {unit}  min={mn:.1f}  max={mx:.1f}  ({cnt} readings)  {direction}")

if flags:
    print()
    print(f"⚠️  Flags: {', '.join(flags)}")
else:
    print()
    print("✅ No concerning trends detected")

db.close()
PYEOF
    ;;

  analyze)
    DAYS="${2:-7}"
    echo "=== LLM Health Analysis (last $DAYS days) ==="

    # Gather recent data
    SNAPSHOT=$(python3 << PYEOF
import sqlite3, json
from datetime import datetime, timedelta, timezone
db = sqlite3.connect("$DB")
cutoff = (datetime.now(timezone.utc) - timedelta(days=$DAYS)).isoformat()

metrics = {}
for row in db.execute("SELECT metric, AVG(value), COUNT(*) FROM health_metrics WHERE timestamp > ? AND value IS NOT NULL GROUP BY metric", (cutoff,)):
    metrics[row[0]] = {"avg": round(row[1], 2), "count": row[2]}

db.close()
print(json.dumps(metrics, indent=2))
PYEOF
)

    # Route through LLM router
    python3 << PYEOF
import sys
sys.path.insert(0, "$SCRIPTS")
from llm_router import call_llm

snapshot = """$SNAPSHOT"""

prompt = f"""You are a health coach reviewing biometric data from a wearable device.

Recent metrics (last $DAYS days averages):
{snapshot}

Provide:
1. Daily health summary (2-3 sentences, conversational)
2. Trend flags (any metrics that warrant attention)
3. One specific, actionable coaching tip for today

Keep it concise and practical. No disclaimers. Be direct."""

response = call_llm(
    model="claude-haiku-3-5",
    prompt=prompt,
    task="health-analysis",
    desc="daily health summary"
)
print(response)
PYEOF
    ;;

  summary)
    echo "=== Health Timeline Summary ==="
    sqlite3 "$DB" "
      SELECT source, COUNT(*) as readings,
        MIN(timestamp) as earliest,
        MAX(timestamp) as latest
      FROM health_metrics
      GROUP BY source;" | column -t -s '|'
    echo ""
    echo "Total records: $(sqlite3 "$DB" "SELECT COUNT(*) FROM health_metrics;")"
    ;;

  *)
    echo "Usage: health-pipeline.sh {init|sync|trends [days]|analyze [days]|summary}"
    exit 1
    ;;
esac
