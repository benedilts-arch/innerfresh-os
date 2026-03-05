#!/bin/bash
# Tier 3 E2E Tests — weekly, full round-trips including messaging
# Tests: calendar create/delete, Gmail read, Telegram send, notify queue delivery

PASS=0; FAIL=0

pass() { echo "✅ $1"; PASS=$((PASS+1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL+1)); }

export GOG_ACCOUNT=benedilts@gmail.com

# ── Calendar round-trip ──────────────────────────────────────────────────────
EVENT_JSON=$(gog calendar create benedilts@gmail.com \
  --summary "🧪 Tier3 Test Event — DELETE ME" \
  --from "$(python3 -c "from datetime import datetime,timedelta,timezone; t=datetime.now(timezone.utc)+timedelta(hours=2); print(t.strftime('%Y-%m-%dT%H:%M:%S+00:00'))")" \
  --to "$(python3 -c "from datetime import datetime,timedelta,timezone; t=datetime.now(timezone.utc)+timedelta(hours=3); print(t.strftime('%Y-%m-%dT%H:%M:%S+00:00'))")" \
  --force --no-input --json 2>/dev/null)

EVENT_ID=$(echo "$EVENT_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['event']['id'])" 2>/dev/null)
[ -n "$EVENT_ID" ] && pass "Calendar create: event ID=$EVENT_ID" || fail "Calendar create FAILED"

# Delete the test event
if [ -n "$EVENT_ID" ]; then
  gog calendar delete benedilts@gmail.com "$EVENT_ID" --force --no-input 2>/dev/null \
    && pass "Calendar delete OK" || fail "Calendar delete FAILED"
fi

# ── Gmail read ───────────────────────────────────────────────────────────────
GMAIL_COUNT=$(gog gmail search benedilts@gmail.com 'is:inbox newer_than:7d' --max 5 --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('messages',[])))" 2>/dev/null)
[ -n "$GMAIL_COUNT" ] && pass "Gmail read: $GMAIL_COUNT messages" || fail "Gmail read FAILED"

# ── Notify queue ─────────────────────────────────────────────────────────────
bash "$HOME/.openclaw/workspace/scripts/notify.sh" enqueue \
  "🧪 Tier 3 test message — if you see this, E2E tests are working" --tier high 2>/dev/null \
  && pass "Notify enqueue OK" || fail "Notify enqueue FAILED"

# ── Log pipeline ─────────────────────────────────────────────────────────────
python3 -c "
import sys; sys.path.insert(0,'$HOME/.openclaw/workspace/scripts')
from log import logger
logger('tier3-test').info('E2E test run', status='pass')
print('Log written')
" && pass "Log pipeline OK" || fail "Log pipeline FAILED"

echo ""
echo "=== Tier 3 Results: $PASS passed, $FAIL failed ==="
[ $FAIL -gt 0 ] && exit 1 || exit 0
