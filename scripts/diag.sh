#!/bin/bash
# diag.sh — Unified diagnostic CLI
#
# Usage:
#   diag.sh health           — full system health check
#   diag.sh cron             — recent cron history (all jobs)
#   diag.sh cron <job>       — history for a specific job
#   diag.sh cron failures    — jobs that failed 3+ times in last 6h
#   diag.sh cron stale       — mark stuck-running jobs as failed
#   diag.sh logs [--level error] [--since 1h] [--grep <text>]
#   diag.sh logs errors      — errors in the last hour (alias)
#   diag.sh model            — current model, canary test, provider status
#   diag.sh dashboard        — unified usage dashboard
#   diag.sh help             — this help text

WORKSPACE="$HOME/.openclaw/workspace"
SCRIPTS="$WORKSPACE/scripts"
DATA="$WORKSPACE/data"

CMD="$1"; shift

case "$CMD" in

  health)
    bash "$SCRIPTS/health-check.sh" --full "$@"
    ;;

  cron)
    SUB="${1:-list}"; shift 2>/dev/null
    case "$SUB" in
      failures)
        echo "=== Persistent Failures (3+ in 6h) ==="
        NOW=$(python3 -c "import time; print(int(time.time()))")
        sqlite3 "$DATA/cron.db" "
          SELECT job_name, COUNT(*) as cnt, MAX(summary) as last_error
          FROM cron_runs
          WHERE status='failed' AND started_at > $(( NOW - 21600 ))
          GROUP BY job_name HAVING cnt >= 3
          ORDER BY cnt DESC;" | column -t -s '|'
        ;;
      stale)
        bash "$SCRIPTS/cron-db.sh" cleanup-stale
        ;;
      "")
        bash "$SCRIPTS/cron-db.sh" query --limit 20
        ;;
      *)
        # Treat as job name
        bash "$SCRIPTS/cron-db.sh" query --job "$SUB" --limit 15 "$@"
        ;;
    esac
    ;;

  logs)
    SUB="$1"
    if [ "$SUB" = "errors" ]; then
      bash "$SCRIPTS/logview.sh" --level error --since 1h
    else
      bash "$SCRIPTS/logview.sh" "$@"
    fi
    ;;

  model)
    echo "=== Model Status ==="
    CURRENT=$(openclaw config get model 2>/dev/null | tr -d '"')
    echo "Active model: ${CURRENT:-not configured}"
    echo ""
    PROVIDER=$(python3 "$SCRIPTS/llm_router.py" --detect-provider "${CURRENT:-unknown}" --json-out 2>/dev/null \
      | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Provider: {d[\"provider\"]}  Model: {d[\"model\"]}')" 2>/dev/null)
    [ -n "$PROVIDER" ] && echo "$PROVIDER"
    echo ""
    echo "=== Canary Test ==="
    bash "$SCRIPTS/model-swap.sh" --verify
    echo ""
    echo "=== Recent LLM Usage (24h) ==="
    bash "$SCRIPTS/llm-tracker.sh" report --days 1
    ;;

  dashboard)
    bash "$SCRIPTS/llm-tracker.sh" dashboard "$@"
    echo ""
    echo "=== Recent Cron Runs ==="
    bash "$SCRIPTS/cron-db.sh" query --limit 8
    echo ""
    echo "=== Log Stats ==="
    bash "$SCRIPTS/log-ingest.sh" stats 2>/dev/null
    ;;

  help|"")
    cat << 'HELP'
diag.sh — Diagnostic toolkit

  health                    Full health check (8 checks, backoff alerting)
  cron                      Last 20 cron runs
  cron <job-name>           History for a specific job
  cron failures             Jobs with 3+ failures in the last 6 hours
  cron stale                Clean up jobs stuck in "running" state
  logs errors               Errors in the last hour
  logs [filters]            Log viewer (--event --level --grep --since --json)
  model                     Current model, canary test, 24h usage
  dashboard                 LLM costs + cron stats + log stats
  help                      This text

Examples:
  diag.sh cron morning-briefing
  diag.sh logs --level error --since 24h
  diag.sh logs --grep chargeback --since 7d
  diag.sh model
  diag.sh dashboard --json
HELP
    ;;

  *)
    echo "Unknown command: $CMD. Run 'diag.sh help'."
    exit 1
    ;;
esac
