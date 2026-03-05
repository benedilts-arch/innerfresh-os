#!/bin/bash
# Tier 2 LLM Tests — weekly, makes live LLM calls (low cost, ~haiku)
# Tests: smoke test, routing, logging, redaction

SCRIPTS="$HOME/.openclaw/workspace/scripts"
PASS=0; FAIL=0

pass() { echo "✅ $1"; PASS=$((PASS+1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL+1)); }

# ── Smoke test via router ────────────────────────────────────────────────────
SMOKE=$(python3 "$SCRIPTS/llm_router.py" --smoke-test --model "claude-haiku-3-5" 2>&1)
echo "$SMOKE" | grep -q "PASSED" && pass "LLM smoke test passed" || fail "LLM smoke test FAILED: $SMOKE"

# ── Provider detection ───────────────────────────────────────────────────────
python3 -c "
import sys; sys.path.insert(0,'$SCRIPTS')
from llm_router import detect_provider, normalize_model
assert detect_provider('claude-haiku-3-5') == 'anthropic', 'claude detection failed'
assert detect_provider('gpt-4o-mini') == 'openai', 'openai detection failed'
assert detect_provider('gemini-2.0-flash') == 'google', 'google detection failed'
p, m = normalize_model('anthropic/claude-sonnet-4-6')
assert p == 'anthropic' and m == 'claude-sonnet-4-6', 'normalize failed'
print('Provider detection OK')
" && pass "Provider detection all correct" || fail "Provider detection broken"

# ── Secret redaction ─────────────────────────────────────────────────────────
python3 -c "
import sys; sys.path.insert(0,'$SCRIPTS')
from llm_router import redact_secrets
r = redact_secrets('my key is FAKE_SK_TEST_VALUE and ntn_xyz123')
assert '[REDACTED]' in r and 'sk-' not in r, 'redaction failed'
print('Redaction:', r)
" && pass "Secret redaction working" || fail "Secret redaction broken"

# ── LLM tracker log written ──────────────────────────────────────────────────
BEFORE=$(sqlite3 "$HOME/.openclaw/workspace/data/llm.db" "SELECT COUNT(*) FROM llm_calls;" 2>/dev/null || echo 0)
python3 "$SCRIPTS/llm_router.py" --model "claude-haiku-3-5" --prompt "Reply: TEST_OK" --task "tier2-test" 2>/dev/null
sleep 2
AFTER=$(sqlite3 "$HOME/.openclaw/workspace/data/llm.db" "SELECT COUNT(*) FROM llm_calls;" 2>/dev/null || echo 0)
[ "$AFTER" -gt "$BEFORE" ] && pass "LLM call logged to DB" || fail "LLM call NOT logged"

# ── Cost estimator ───────────────────────────────────────────────────────────
COST=$(bash "$SCRIPTS/llm-tracker.sh" estimate --model "anthropic/claude-sonnet-4-6" --input 1000 --output 500 2>/dev/null)
echo "$COST" | grep -q "0\." && pass "Cost estimator returns value" || fail "Cost estimator broken: $COST"

echo ""
echo "=== Tier 2 Results: $PASS passed, $FAIL failed ==="
[ $FAIL -gt 0 ] && exit 1 || exit 0
