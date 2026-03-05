#!/bin/bash
# notify.sh — Notification priority queue
#
# Usage:
#   notify.sh enqueue <message> [--tier critical|high|medium] [--type <type>] [--channel <id>]
#   notify.sh flush [--tier high|medium]
#   notify.sh send <message> --channel <id>       # bypass queue, send immediately
#   notify.sh status
#   notify.sh init

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB="${NOTIFY_DB:-$HOME/.openclaw/workspace/data/notify.db}"
TELEGRAM_CHAT="${TELEGRAM_CHAT:-6560403362}"
mkdir -p "$(dirname "$DB")"

sql() { sqlite3 "$DB" "$@"; }

NOW() { python3 -c "import time; print(int(time.time()))"; }

# ── Classification rules ────────────────────────────────────────────────────
classify() {
  local TYPE="$1"
  local MSG="$2"
  case "$TYPE" in
    # Critical: needs immediate attention
    chargeback|dispute|security|error|system|auth|interactive) echo "critical" ;;
    # High: job failures, important updates
    job-failure|payment|calendar-reminder|email-urgent) echo "high" ;;
    # Everything else: medium
    *) 
      # Keyword-based escalation
      if echo "$MSG" | grep -qiE "urgent|critical|failed|error|chargeback|dispute|immediate"; then
        echo "high"
      else
        echo "medium"
      fi
      ;;
  esac
}

case "$1" in
  init)
    sql "
      CREATE TABLE IF NOT EXISTS notify_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        tier TEXT NOT NULL DEFAULT 'medium',
        type TEXT,
        channel TEXT NOT NULL DEFAULT '$TELEGRAM_CHAT',
        created_at INTEGER NOT NULL,
        delivered_at INTEGER,
        status TEXT NOT NULL DEFAULT 'pending'
      );
      CREATE INDEX IF NOT EXISTS idx_tier ON notify_queue(tier);
      CREATE INDEX IF NOT EXISTS idx_status ON notify_queue(status);
    "
    echo "Notify DB initialized: $DB"
    ;;

  enqueue)
    shift
    MSG=""
    TIER=""
    TYPE=""
    CHANNEL="$TELEGRAM_CHAT"

    # First positional = message
    if [[ "$1" != "--"* ]]; then
      MSG="$1"; shift
    fi

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --tier) TIER="$2"; shift 2 ;;
        --type) TYPE="$2"; shift 2 ;;
        --channel) CHANNEL="$2"; shift 2 ;;
        --message|-m) MSG="$2"; shift 2 ;;
        *) shift ;;
      esac
    done

    [ -z "$MSG" ] && echo "Error: message required" && exit 1

    # Auto-classify if tier not specified
    [ -z "$TIER" ] && TIER=$(classify "$TYPE" "$MSG")

    TS=$(NOW)
    sql "INSERT INTO notify_queue(message, tier, type, channel, created_at) VALUES('$(echo "$MSG" | sed "s/'/''/g")', '$TIER', '$TYPE', '$CHANNEL', $TS);"

    # Critical: deliver immediately
    if [ "$TIER" = "critical" ]; then
      bash "$SCRIPT_DIR/notify.sh" send "$MSG" --channel "$CHANNEL"
      TS=$(NOW)
      sql "UPDATE notify_queue SET status='delivered', delivered_at=$TS WHERE id=(SELECT MAX(id) FROM notify_queue);"
      echo "[notify] Critical message delivered immediately."
    else
      echo "[notify] Queued as $TIER."
    fi
    ;;

  send)
    # Bypass queue — send directly
    shift
    MSG="$1"; shift
    CHANNEL="$TELEGRAM_CHAT"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --channel) CHANNEL="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    openclaw message send --channel telegram --to "telegram:$CHANNEL" --message "$MSG" 2>/dev/null \
      || curl -s -X POST "https://api.telegram.org/bot$(openclaw config get channels.telegram.botToken 2>/dev/null | tr -d '"')/sendMessage" \
         -d "chat_id=$CHANNEL" -d "text=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$MSG")" > /dev/null
    echo "[notify] Sent."
    ;;

  flush)
    TIER="${2:-high}"
    TS=$(NOW)

    # Get pending messages for this tier
    MSGS=$(sql "SELECT id, message, channel FROM notify_queue WHERE tier='$TIER' AND status='pending' ORDER BY created_at ASC;")

    if [ -z "$MSGS" ]; then
      echo "[notify] No pending $TIER messages."
      exit 0
    fi

    # Group by channel and build digest
    CHANNELS=$(sql "SELECT DISTINCT channel FROM notify_queue WHERE tier='$TIER' AND status='pending';")

    while IFS= read -r CHANNEL; do
      [ -z "$CHANNEL" ] && continue
      COUNT=$(sql "SELECT COUNT(*) FROM notify_queue WHERE tier='$TIER' AND status='pending' AND channel='$CHANNEL';")
      ITEMS=$(sql "SELECT message FROM notify_queue WHERE tier='$TIER' AND status='pending' AND channel='$CHANNEL' ORDER BY created_at ASC;" | head -10)

      TIER_CAP="$(echo "$TIER" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')"
      DIGEST="📬 *${TIER_CAP} digest* (${COUNT} item$([ "$COUNT" -ne 1 ] && echo s))"$'\n'"$ITEMS"

      bash "$SCRIPT_DIR/notify.sh" send "$DIGEST" --channel "$CHANNEL"
      sql "UPDATE notify_queue SET status='delivered', delivered_at=$TS WHERE tier='$TIER' AND status='pending' AND channel='$CHANNEL';"
    done <<< "$CHANNELS"

    echo "[notify] Flushed $TIER batch."
    ;;

  status)
    echo "=== Notification Queue Status ==="
    sql "SELECT tier, status, COUNT(*) as count FROM notify_queue GROUP BY tier, status ORDER BY tier, status;" | column -t -s '|'
    echo ""
    echo "=== Recent deliveries ==="
    sql "SELECT id, tier, datetime(created_at,'unixepoch','+4 hours'), substr(message,1,60) FROM notify_queue WHERE status='delivered' ORDER BY created_at DESC LIMIT 5;" | column -t -s '|'
    ;;

  *)
    echo "Usage: notify.sh {init|enqueue|send|flush|status}"
    exit 1
    ;;
esac
