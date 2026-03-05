#!/bin/bash
# synthesize-memory.sh — Weekly synthesis of daily notes into MEMORY.md
#
# Reads the past 7 days of daily notes, extracts durable patterns,
# and updates MEMORY.md. Never deletes daily notes.
#
# Usage: synthesize-memory.sh [--days <n>]

WORKSPACE="${WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY_FILE="$WORKSPACE/MEMORY.md"
MEMORY_DIR="$WORKSPACE/memory"
DAYS="${2:-7}"

# Collect daily notes from the past N days
NOTES=""
for i in $(seq 0 $((DAYS - 1))); do
  DATE=$(python3 -c "from datetime import date, timedelta; print(date.today() - timedelta(days=$i))")
  FILE="$MEMORY_DIR/${DATE}.md"
  if [ -f "$FILE" ]; then
    NOTES="$NOTES\n\n=== $DATE ===\n$(cat "$FILE")"
  fi
done

if [ -z "$NOTES" ]; then
  echo "No daily notes found for the past $DAYS days. Nothing to synthesize."
  exit 0
fi

echo "Found daily notes. Synthesis requires an LLM call — run this via the agent, not standalone."
echo "Notes collected from $DAYS days:"
echo "$NOTES" | grep "^===" | head -10
exit 0
