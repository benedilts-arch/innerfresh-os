#!/bin/bash
# Tier 1 Integration Tests — nightly, no LLM calls, free
# Tests: script existence, DB integrity, cron health, file permissions

SCRIPTS="$HOME/.openclaw/workspace/scripts"
DATA="$HOME/.openclaw/workspace/data"
PASS=0; FAIL=0

pass() { echo "✅ $1"; PASS=$((PASS+1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL+1)); }

# ── Script existence ─────────────────────────────────────────────────────────
for SCRIPT in cron-db.sh cron-wrap.sh notify.sh finance.sh llm-tracker.sh log.sh logview.sh log-ingest.sh security-audit.sh; do
  [ -x "$SCRIPTS/$SCRIPT" ] && pass "$SCRIPT exists and is executable" || fail "$SCRIPT missing or not executable"
done

[ -f "$SCRIPTS/llm_router.py" ] && pass "llm_router.py exists" || fail "llm_router.py missing"
[ -f "$SCRIPTS/log.py" ] && pass "log.py exists" || fail "log.py missing"

# ── Python syntax ────────────────────────────────────────────────────────────
for PY in llm_router.py log.py; do
  python3 -c "import ast; ast.parse(open('$SCRIPTS/$PY').read())" 2>/dev/null \
    && pass "$PY syntax OK" || fail "$PY syntax error"
done

# ── SQLite DB integrity ──────────────────────────────────────────────────────
for DB in cron.db notify.db finance.db llm.db logs.db; do
  if [ -f "$DATA/$DB" ]; then
    sqlite3 "$DATA/$DB" "PRAGMA integrity_check;" 2>/dev/null | grep -q "ok" \
      && pass "$DB integrity OK" || fail "$DB integrity FAILED"
  else
    fail "$DB missing"
  fi
done

# ── File permissions ─────────────────────────────────────────────────────────
for F in "$HOME/.config/notion/api_key" "$HOME/.openclaw/openclaw.json"; do
  [ -f "$F" ] || continue
  PERMS=$(python3 -c "import stat,os; m=os.stat('$F').st_mode; print(oct(stat.S_IMODE(m)))")
  [ "$PERMS" = "0o600" ] && pass "Permissions OK: $F" || fail "Permissions wrong ($PERMS): $F"
done

# ── Log dir writeable ────────────────────────────────────────────────────────
touch "$HOME/.openclaw/workspace/data/logs/.write-test" 2>/dev/null \
  && rm "$HOME/.openclaw/workspace/data/logs/.write-test" && pass "Log dir writeable" \
  || fail "Log dir not writeable"

# ── Gateway running ──────────────────────────────────────────────────────────
openclaw gateway status 2>/dev/null | grep -q "loaded" \
  && pass "Gateway running" || fail "Gateway not running"

# ── Cron jobs exist ──────────────────────────────────────────────────────────
for JOB in morning-briefing nightly-security-audit weekly-memory-synthesis notify-flush-high notify-flush-medium log-nightly-ingest; do
  openclaw cron list 2>/dev/null | grep -q "$JOB" \
    && pass "Cron job exists: $JOB" || fail "Cron job missing: $JOB"
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "=== Tier 1 Results: $PASS passed, $FAIL failed ==="
[ $FAIL -gt 0 ] && exit 1 || exit 0
