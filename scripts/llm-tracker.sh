#!/bin/bash
# llm-tracker.sh — LLM usage and cost tracking
#
# Usage:
#   llm-tracker.sh init
#   llm-tracker.sh log --provider <p> --model <m> --input-tokens <n> --output-tokens <n> [--task <type>] [--desc <text>] [--duration <ms>]
#   llm-tracker.sh log-api --service <s> --endpoint <e> --method <m> --status <code> --duration <ms>
#   llm-tracker.sh report [--days <n>] [--model <m>] [--json]
#   llm-tracker.sh dashboard [--json]
#   llm-tracker.sh estimate --model <m> --input <tokens> --output <tokens>
#   llm-tracker.sh estimate-chars --model <m> --text "<text>"
#   llm-tracker.sh archive --days <n>

DB="${LLM_DB:-$HOME/.openclaw/workspace/data/llm.db}"
JSONL_LOG="${HOME}/.openclaw/workspace/data/llm-calls.jsonl"
mkdir -p "$(dirname "$DB")" "$(dirname "$JSONL_LOG")"

sql() { sqlite3 "$DB" "$@"; }
NOW() { python3 -c "import time; print(int(time.time()))"; }

# ── Pricing table (per 1M tokens, USD) ─────────────────────────────────────
PRICING='{
  "anthropic/claude-sonnet-4-6":   {"input": 3.00,  "output": 15.00},
  "anthropic/claude-haiku-3-5":    {"input": 0.80,  "output": 4.00},
  "anthropic/claude-opus-4":       {"input": 15.00, "output": 75.00},
  "openai/gpt-4o":                 {"input": 2.50,  "output": 10.00},
  "openai/gpt-4o-mini":            {"input": 0.15,  "output": 0.60},
  "openai/o3":                     {"input": 10.00, "output": 40.00},
  "google/gemini-2.0-flash":       {"input": 0.10,  "output": 0.40},
  "google/gemini-2.5-pro":         {"input": 1.25,  "output": 10.00}
}'

estimate_cost() {
  python3 -c "
import json, sys
pricing = $PRICING
model = sys.argv[1]
input_t = int(sys.argv[2])
output_t = int(sys.argv[3])
p = pricing.get(model, {'input': 3.0, 'output': 15.0})
cost = (input_t * p['input'] + output_t * p['output']) / 1_000_000
print(round(cost, 6))
" "$1" "$2" "$3"
}

case "$1" in
  init)
    sql "
      CREATE TABLE IF NOT EXISTS llm_calls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider TEXT,
        model TEXT NOT NULL,
        task_type TEXT,
        description TEXT,
        input_tokens INTEGER DEFAULT 0,
        output_tokens INTEGER DEFAULT 0,
        total_tokens INTEGER GENERATED ALWAYS AS (input_tokens + output_tokens) STORED,
        duration_ms INTEGER,
        estimated_cost REAL,
        status TEXT DEFAULT 'ok',
        created_at INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS api_calls (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service TEXT NOT NULL,
        endpoint TEXT,
        method TEXT,
        status_code INTEGER,
        duration_ms INTEGER,
        created_at INTEGER NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_llm_model ON llm_calls(model);
      CREATE INDEX IF NOT EXISTS idx_llm_date ON llm_calls(created_at);
      CREATE INDEX IF NOT EXISTS idx_llm_task ON llm_calls(task_type);
      CREATE INDEX IF NOT EXISTS idx_api_service ON api_calls(service);
    "
    echo "LLM tracker DB initialized: $DB"
    ;;

  log)
    shift
    PROVIDER="" MODEL="" INPUT=0 OUTPUT=0 TASK="general" DESC="" DURATION="" STATUS="ok"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --provider)      PROVIDER="$2"; shift 2 ;;
        --model)         MODEL="$2"; shift 2 ;;
        --input-tokens)  INPUT="$2"; shift 2 ;;
        --output-tokens) OUTPUT="$2"; shift 2 ;;
        --task)          TASK="$2"; shift 2 ;;
        --desc)          DESC="$2"; shift 2 ;;
        --duration)      DURATION="$2"; shift 2 ;;
        --status)        STATUS="$2"; shift 2 ;;
        *) shift ;;
      esac
    done

    [ -z "$MODEL" ] && echo "Error: --model required" && exit 1
    COST=$(estimate_cost "${PROVIDER:+$PROVIDER/}$MODEL" "$INPUT" "$OUTPUT" 2>/dev/null || estimate_cost "$MODEL" "$INPUT" "$OUTPUT")
    TS=$(NOW)

    sql "INSERT INTO llm_calls(provider,model,task_type,description,input_tokens,output_tokens,duration_ms,estimated_cost,status,created_at)
         VALUES('$PROVIDER','$MODEL','$TASK','$(echo "$DESC" | sed "s/'/''/g")',$INPUT,$OUTPUT,${DURATION:-NULL},$COST,'$STATUS',$TS);"

    # JSONL log (lightweight)
    echo "{\"ts\":$TS,\"model\":\"$MODEL\",\"input\":$INPUT,\"output\":$OUTPUT,\"cost\":$COST,\"task\":\"$TASK\"}" >> "$JSONL_LOG"
    echo "[llm-tracker] Logged: $MODEL in=$INPUT out=$OUTPUT cost=\$$COST"
    ;;

  log-api)
    shift
    SERVICE="" ENDPOINT="" METHOD="GET" STATUS_CODE=200 DURATION=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --service)  SERVICE="$2"; shift 2 ;;
        --endpoint) ENDPOINT="$2"; shift 2 ;;
        --method)   METHOD="$2"; shift 2 ;;
        --status)   STATUS_CODE="$2"; shift 2 ;;
        --duration) DURATION="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    TS=$(NOW)
    sql "INSERT INTO api_calls(service,endpoint,method,status_code,duration_ms,created_at) VALUES('$SERVICE','$ENDPOINT','$METHOD',$STATUS_CODE,${DURATION:-NULL},$TS);"
    ;;

  report)
    shift
    DAYS=30 MODEL="" JSON=false
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --days)  DAYS="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --json)  JSON=true; shift ;;
        *) shift ;;
      esac
    done

    CUTOFF=$(python3 -c "import time; print(int(time.time()) - $DAYS * 86400)")
    WHERE="created_at > $CUTOFF"
    [ -n "$MODEL" ] && WHERE="$WHERE AND model LIKE '%$MODEL%'"

    if $JSON; then
      sql -json "
        SELECT model,
          COUNT(*) as calls,
          SUM(input_tokens) as total_input,
          SUM(output_tokens) as total_output,
          ROUND(SUM(estimated_cost),4) as total_cost_usd
        FROM llm_calls WHERE $WHERE
        GROUP BY model ORDER BY total_cost_usd DESC;
      "
    else
      echo "=== LLM Usage Report (last $DAYS days) ==="
      sql "
        SELECT model, COUNT(*) as calls,
          SUM(input_tokens) as input_tok,
          SUM(output_tokens) as output_tok,
          ROUND(SUM(estimated_cost),4) as cost_usd
        FROM llm_calls WHERE $WHERE
        GROUP BY model ORDER BY cost_usd DESC;
      " | column -t -s '|'
      echo ""
      TOTAL=$(sql "SELECT ROUND(SUM(estimated_cost),4) FROM llm_calls WHERE $WHERE;")
      echo "Total estimated cost: \$$TOTAL USD"
    fi
    ;;

  dashboard)
    shift
    JSON=false
    [[ "$1" == "--json" ]] && JSON=true

    # Collect stats
    TOTAL_COST=$(sql "SELECT ROUND(COALESCE(SUM(estimated_cost),0),4) FROM llm_calls;")
    TOTAL_CALLS=$(sql "SELECT COUNT(*) FROM llm_calls;")
    TOTAL_TOKENS=$(sql "SELECT COALESCE(SUM(total_tokens),0) FROM llm_calls;")
    MONTH_COST=$(sql "SELECT ROUND(COALESCE(SUM(estimated_cost),0),4) FROM llm_calls WHERE created_at > strftime('%s','now','-30 days');")
    CRON_TOTAL=$(sqlite3 ~/.openclaw/workspace/data/cron.db "SELECT COUNT(*) FROM cron_runs;" 2>/dev/null || echo 0)
    CRON_OK=$(sqlite3 ~/.openclaw/workspace/data/cron.db "SELECT COUNT(*) FROM cron_runs WHERE status='ok';" 2>/dev/null || echo 0)
    CRON_FAIL=$(sqlite3 ~/.openclaw/workspace/data/cron.db "SELECT COUNT(*) FROM cron_runs WHERE status='failed';" 2>/dev/null || echo 0)
    DB_SIZE=$(du -sh ~/.openclaw/workspace/data/*.db 2>/dev/null | awk '{print $1, $2}' | tr '\n' ' ')
    JSONL_SIZE=$(du -sh "$JSONL_LOG" 2>/dev/null | awk '{print $1}')

    if $JSON; then
      python3 -c "
import json
print(json.dumps({
  'llm': {'total_cost_usd': $TOTAL_COST, 'calls': $TOTAL_CALLS, 'tokens': $TOTAL_TOKENS, 'last_30d_cost': $MONTH_COST},
  'cron': {'total': $CRON_TOTAL, 'ok': $CRON_OK, 'failed': $CRON_FAIL},
  'storage': {'db_sizes': '$DB_SIZE', 'jsonl_size': '${JSONL_SIZE:-0}'}
}, indent=2))
"
    else
      echo "=== Agent Dashboard ==="
      echo ""
      echo "── LLM Usage ──────────────────"
      echo "Total calls:    $TOTAL_CALLS"
      echo "Total tokens:   $TOTAL_TOKENS"
      echo "All-time cost:  \$$TOTAL_COST USD"
      echo "Last 30 days:   \$$MONTH_COST USD"
      echo ""
      echo "── Top Models (30d) ───────────"
      sql "SELECT model, COUNT(*) calls, ROUND(SUM(estimated_cost),4) cost FROM llm_calls WHERE created_at > strftime('%s','now','-30 days') GROUP BY model ORDER BY cost DESC LIMIT 5;" | column -t -s '|'
      echo ""
      echo "── Cron Reliability ───────────"
      echo "Total runs:  $CRON_TOTAL  |  OK: $CRON_OK  |  Failed: $CRON_FAIL"
      echo ""
      echo "── Storage ────────────────────"
      echo "$DB_SIZE"
    fi
    ;;

  estimate)
    shift
    MODEL="" INPUT=0 OUTPUT=0
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --model) MODEL="$2"; shift 2 ;;
        --input) INPUT="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    COST=$(estimate_cost "$MODEL" "$INPUT" "$OUTPUT")
    echo "Estimated cost: \$$COST USD (model=$MODEL, in=$INPUT, out=$OUTPUT)"
    ;;

  estimate-chars)
    shift
    MODEL="" TEXT=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --model) MODEL="$2"; shift 2 ;;
        --text)  TEXT="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    python3 -c "
text = '''$TEXT'''
# ~4 chars per token for English
tokens = max(1, len(text) // 4)
print(f'Estimated tokens: {tokens}')
"
    ;;

  archive)
    DAYS="${2:-90}"
    CUTOFF=$(python3 -c "import time; print(int(time.time()) - $DAYS * 86400)")
    MONTH=$(python3 -c "from datetime import datetime; print(datetime.now().strftime('%Y-%m'))")
    ARCHIVE_DB="$HOME/.openclaw/workspace/data/llm-archive-$MONTH.db"

    sqlite3 "$ARCHIVE_DB" "CREATE TABLE IF NOT EXISTS llm_calls AS SELECT * FROM llm_calls WHERE 0;"
    sqlite3 "$DB" ".dump llm_calls" | grep "INSERT" | grep -v "created_at > $CUTOFF" | sqlite3 "$ARCHIVE_DB" 2>/dev/null

    COUNT=$(sql "SELECT COUNT(*) FROM llm_calls WHERE created_at < $CUTOFF;")
    sql "DELETE FROM llm_calls WHERE created_at < $CUTOFF;"
    echo "Archived $COUNT rows older than $DAYS days to $ARCHIVE_DB"
    ;;

  *)
    echo "Usage: llm-tracker.sh {init|log|log-api|report|dashboard|estimate|estimate-chars|archive}"
    exit 1
    ;;
esac
