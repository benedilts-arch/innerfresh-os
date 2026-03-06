#!/bin/bash
# manus-dispatch.sh — dispatch a task to Manus and return the result
# Usage: manus-dispatch.sh "Your task description" [lite|default|max]
# Returns: assistant text output on stdout

set -euo pipefail

TASK="$1"
PROFILE="${2:-default}"
TIMEOUT="${3:-600}"
API_BASE="https://api.manus.ai/v1"

# Load API key
if [ -z "${MANUS_API_KEY:-}" ]; then
  if [ -f ~/.config/manus/api_key ]; then
    MANUS_API_KEY=$(cat ~/.config/manus/api_key)
  elif [ -f ~/.openclaw/workspace/.env ]; then
    MANUS_API_KEY=$(grep ^MANUS_API_KEY ~/.openclaw/workspace/.env | cut -d= -f2-)
  fi
fi
[ -z "${MANUS_API_KEY:-}" ] && { echo "Error: MANUS_API_KEY not set" >&2; exit 1; }

# Map profile alias
case "$PROFILE" in
  lite)    MODEL="manus-1.6-lite" ;;
  max)     MODEL="manus-1.6-max" ;;
  *)       MODEL="manus-1.6" ;;
esac

# Create task
RESPONSE=$(curl -s -X POST "$API_BASE/tasks" \
  -H "API_KEY: $MANUS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"prompt\": $(echo "$TASK" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip()))'), \"agentProfile\": \"$MODEL\", \"taskMode\": \"agent\"}")

TASK_ID=$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin).get('task_id',''))")
[ -z "$TASK_ID" ] && { echo "Error creating task: $RESPONSE" >&2; exit 1; }
echo "Task created: $TASK_ID" >&2

# Poll until complete
ELAPSED=0
INTERVAL=8
while [ $ELAPSED -lt $TIMEOUT ]; do
  STATUS=$(curl -s "$API_BASE/tasks/$TASK_ID" -H "API_KEY: $MANUS_API_KEY" | \
    python3 -c "import json,sys; print(json.load(sys.stdin).get('status','unknown'))")

  if [ "$STATUS" = "completed" ]; then
    break
  elif [ "$STATUS" = "failed" ]; then
    echo "Task failed" >&2; exit 1
  fi
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
  echo "Waiting... ${ELAPSED}s (status: $STATUS)" >&2
done

# Extract assistant output
curl -s "$API_BASE/tasks/$TASK_ID" -H "API_KEY: $MANUS_API_KEY" | python3 -c "
import json, sys
d = json.load(sys.stdin)
output = d.get('output', [])
for block in output:
    if block.get('role') == 'assistant':
        for item in block.get('content', []):
            if item.get('type') == 'output_text':
                print(item['text'])
"
