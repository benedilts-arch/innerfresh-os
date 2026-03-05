#!/bin/bash
# log.sh — Structured event logger (Bash library + CLI)
#
# Source as library:
#   source ~/.openclaw/workspace/scripts/log.sh
#   log_info "email-scan" "Scanned 12 threads" '{"count":12}'
#
# CLI:
#   log.sh --event email-scan --level info --msg "Scanned 12"

LOG_DIR="${LOG_DIR:-$HOME/.openclaw/workspace/data/logs}"
mkdir -p "$LOG_DIR"

_log_redact() {
  echo "$1" | sed -E \
    -e 's/sk-[A-Za-z0-9]{20,}/[REDACTED]/g' \
    -e 's/ntn_[A-Za-z0-9]+/[REDACTED]/g' \
    -e 's/Bearer [A-Za-z0-9._~+\/-]+/[REDACTED]/g' \
    -e 's/AKIA[0-9A-Z]{16}/[REDACTED]/g' \
    -e 's/bot[0-9]+:[A-Za-z0-9_-]+/[REDACTED]/g'
}

_log_write() {
  local EVENT="$1" LEVEL="$2" MSG="$3" EXTRA="${4:-{}}"
  local TS
  TS=$(python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).isoformat())")
  MSG=$(_log_redact "$MSG")

  local LINE
  LINE=$(python3 -c "
import json, sys
entry = {'ts': '$TS', 'event': '$EVENT', 'level': '$LEVEL', 'msg': sys.argv[1]}
try:
    extra = json.loads(sys.argv[2])
    entry.update(extra)
except: pass
print(json.dumps(entry))
" "$MSG" "$EXTRA")

  echo "$LINE" >> "$LOG_DIR/${EVENT}.jsonl"
  echo "$LINE" >> "$LOG_DIR/all.jsonl"
}

log_debug()    { _log_write "$1" "debug"    "$2" "${3:-{}}"; }
log_info()     { _log_write "$1" "info"     "$2" "${3:-{}}"; }
log_warn()     { _log_write "$1" "warn"     "$2" "${3:-{}}"; }
log_error()    { _log_write "$1" "error"    "$2" "${3:-{}}"; }
log_critical() { _log_write "$1" "critical" "$2" "${3:-{}}"; }

# ── CLI mode ─────────────────────────────────────────────────────────────────
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  EVENT="" LEVEL="info" MSG="" FIELDS="{}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --event) EVENT="$2"; shift 2 ;;
      --level) LEVEL="$2"; shift 2 ;;
      --msg)   MSG="$2";   shift 2 ;;
      --fields) FIELDS="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -z "$EVENT" ] || [ -z "$MSG" ] && echo "Usage: log.sh --event <name> --level <l> --msg <msg>" && exit 1
  _log_write "$EVENT" "$LEVEL" "$MSG" "$FIELDS"
  echo "[$LEVEL] $EVENT: $MSG"
fi
