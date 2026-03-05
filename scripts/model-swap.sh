#!/bin/bash
# model-swap.sh — Switch the active LLM model with canary verification
#
# Usage:
#   model-swap.sh --model <model>             — swap and verify
#   model-swap.sh --status                    — show current model
#   model-swap.sh --verify                    — canary test without swapping
#
# Examples:
#   model-swap.sh --model anthropic/claude-sonnet-4-6
#   model-swap.sh --model openai/gpt-4o

SCRIPTS="$HOME/.openclaw/workspace/scripts"

_log() { bash "$SCRIPTS/log.sh" --event model-swap --level "$1" --msg "$2" 2>/dev/null; echo "[$1] $2"; }
_alert() { bash "$SCRIPTS/notify.sh" enqueue "$1" --tier critical --type system 2>/dev/null; }

canary_test() {
  local EXPECTED_PROVIDER="$1"
  local CANARY_PROMPT='{"messages":[{"role":"user","content":"Reply with only the text: CANARY_OK"}]}'

  # Try via OpenClaw proxy (uses whatever model is currently active)
  GATEWAY_TOKEN=$(python3 -c "import json; d=json.load(open('$HOME/.openclaw/openclaw.json')); print(d.get('gateway',{}).get('auth',{}).get('token',''))" 2>/dev/null)

  RESPONSE=$(curl -s -X POST "http://127.0.0.1:18789/v1/llm/complete" \
    -H "Authorization: Bearer $GATEWAY_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$(openclaw config get model 2>/dev/null | tr -d '\"')\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with only: CANARY_OK\"}],\"max_tokens\":20}" \
    --max-time 30 2>/dev/null)

  if echo "$RESPONSE" | grep -q "CANARY_OK"; then
    _log "info" "Canary test PASSED"
    return 0
  else
    _log "warn" "Canary test — unexpected response: $(echo "$RESPONSE" | head -c 100)"
    return 1
  fi
}

case "$1" in
  --status)
    CURRENT=$(openclaw config get model 2>/dev/null | tr -d '"')
    echo "Current model: ${CURRENT:-not set}"
    ;;

  --verify)
    echo "Running canary verification..."
    canary_test
    ;;

  --model)
    NEW_MODEL="$2"
    [ -z "$NEW_MODEL" ] && echo "Error: --model required" && exit 1

    # Detect provider from model name
    PROVIDER=$(python3 "$SCRIPTS/llm_router.py" --detect-provider "$NEW_MODEL" --json-out 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)['provider'])" 2>/dev/null)
    PROVIDER="${PROVIDER:-unknown}"

    PREVIOUS=$(openclaw config get model 2>/dev/null | tr -d '"')
    _log "info" "Swapping model: $PREVIOUS → $NEW_MODEL (provider: $PROVIDER)"

    # Update config
    openclaw config set model "$NEW_MODEL" 2>/dev/null
    if [ $? -ne 0 ]; then
      _log "error" "Failed to update model config"
      exit 1
    fi

    # Restart gateway
    _log "info" "Restarting gateway..."
    openclaw gateway restart 2>/dev/null
    sleep 3

    # Verify gateway came back up
    RETRIES=5
    for i in $(seq 1 $RETRIES); do
      STATUS=$(openclaw gateway status 2>/dev/null | grep -c "loaded")
      [ "$STATUS" -gt 0 ] && break
      sleep 2
    done

    if [ "$STATUS" -eq 0 ]; then
      _log "error" "Gateway did not restart after model swap"
      _alert "🔴 Model swap failed — gateway did not restart. Previous model: $PREVIOUS"
      exit 1
    fi

    # Canary test
    _log "info" "Running canary verification..."
    if canary_test "$PROVIDER"; then
      _log "info" "Model swap complete: $NEW_MODEL — canary passed"
      # Log to LLM tracker
      bash "$SCRIPTS/llm-tracker.sh" log \
        --provider "$PROVIDER" --model "$NEW_MODEL" \
        --input-tokens 10 --output-tokens 5 \
        --task "model-swap-canary" --desc "canary test after swap from $PREVIOUS" 2>/dev/null
    else
      _log "warn" "Canary returned unexpected response — check gateway logs"
      _alert "⚠️ Model swap to $NEW_MODEL: canary response unexpected. Check gateway. Previous: $PREVIOUS"
      echo "Gateway log: /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
    fi
    ;;

  *)
    echo "Usage: model-swap.sh [--model <model>|--status|--verify]"
    echo ""
    echo "Examples:"
    echo "  model-swap.sh --model anthropic/claude-sonnet-4-6"
    echo "  model-swap.sh --model openai/gpt-4o"
    echo "  model-swap.sh --status"
    exit 1
    ;;
esac
