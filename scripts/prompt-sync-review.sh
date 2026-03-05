#!/bin/bash
# prompt-sync-review.sh — Compare Claude and GPT prompt stacks for drift
#
# Usage:
#   prompt-sync-review.sh           — full diff report
#   prompt-sync-review.sh --json    — JSON output

WORKSPACE="$HOME/.openclaw/workspace"
CLAUDE_STACK="$WORKSPACE"                  # root = Claude stack
GPT_STACK="$WORKSPACE/prompts/gpt"
SCRIPTS="$WORKSPACE/scripts"
JSON=false
[[ "$1" == "--json" ]] && JSON=true

PROMPT_FILES=(AGENTS.md SOUL.md TOOLS.md MEMORY.md HEARTBEAT.md)

# Critical facts that must be identical in both stacks
CRITICAL_FACTS=(
  "6560403362"           # Telegram DM ID
  "-5196348541"          # brand-improvement group
  "-5081837089"          # secondary group
  "benedilts@gmail.com"  # Gmail account
  "2cfa723e"             # Notion page ID prefix
  "Asia/Dubai"           # timezone
  "b69e4dfd"             # morning briefing cron UUID prefix
  "8139347132490"        # InnerFresh product ID
  "127.0.0.1"            # gateway binding
)

ISSUES=()
REPORT=()

check_fact() {
  local FACT="$1" FILE="$2"
  local CLAUDE_FILE="$CLAUDE_STACK/$FILE"
  local GPT_FILE="$GPT_STACK/$FILE"

  local IN_CLAUDE=false IN_GPT=false
  grep -q "$FACT" "$CLAUDE_FILE" 2>/dev/null && IN_CLAUDE=true
  grep -q "$FACT" "$GPT_FILE" 2>/dev/null && IN_GPT=true

  if $IN_CLAUDE && ! $IN_GPT; then
    ISSUES+=("MISSING IN GPT: '$FACT' found in Claude/$FILE but not GPT/$FILE")
  elif ! $IN_CLAUDE && $IN_GPT; then
    ISSUES+=("MISSING IN CLAUDE: '$FACT' found in GPT/$FILE but not Claude/$FILE")
  fi
}

echo "=== Prompt Stack Sync Review ===" >&2
echo "" >&2

# 1. File coverage check
for FILE in "${PROMPT_FILES[@]}"; do
  CLAUDE_EXISTS=false; GPT_EXISTS=false
  [ -f "$CLAUDE_STACK/$FILE" ] && CLAUDE_EXISTS=true
  [ -f "$GPT_STACK/$FILE" ] && GPT_EXISTS=true

  if $CLAUDE_EXISTS && ! $GPT_EXISTS; then
    ISSUES+=("MISSING FILE: $FILE exists in Claude stack but not GPT stack")
    echo "❌ $FILE — missing from GPT stack" >&2
  elif ! $CLAUDE_EXISTS && $GPT_EXISTS; then
    ISSUES+=("MISSING FILE: $FILE exists in GPT stack but not Claude stack")
    echo "❌ $FILE — missing from Claude stack" >&2
  else
    echo "✅ $FILE — present in both stacks" >&2
  fi
done

echo "" >&2

# 2. Critical facts check — Python to avoid subprocess limits with special chars
FACT_RESULTS=$(python3 << PYEOF
import os

claude_stack = "$CLAUDE_STACK"
gpt_stack = "$GPT_STACK"
files = ["AGENTS.md","SOUL.md","TOOLS.md","MEMORY.md","HEARTBEAT.md"]
facts = [
    "6560403362", "-5196348541", "-5081837089",
    "benedilts@gmail.com", "2cfa723e", "Asia/Dubai",
    "b69e4dfd", "8139347132490", "127.0.0.1"
]

def stack_has(stack, fact):
    for f in files:
        path = os.path.join(stack, f)
        try:
            if fact in open(path).read():
                return True
        except: pass
    return False

issues = []
for fact in facts:
    in_claude = stack_has(claude_stack, fact)
    in_gpt    = stack_has(gpt_stack, fact)
    if in_claude and not in_gpt:
        print(f"DRIFT|'{fact}' in Claude but not GPT")
        issues.append(f"FACT DRIFT: '{fact}' in Claude stack, missing from GPT stack")
    elif in_gpt and not in_claude:
        print(f"DRIFT|'{fact}' in GPT but not Claude")
        issues.append(f"FACT DRIFT: '{fact}' in GPT stack, missing from Claude stack")
    else:
        print(f"OK|'{fact}' consistent")
PYEOF
)

while IFS= read -r LINE; do
  STATUS="${LINE%%|*}"; MSG="${LINE#*|}"
  if [ "$STATUS" = "OK" ]; then
    echo "✓  $MSG" >&2
  else
    echo "⚠️  $MSG" >&2
    ISSUES+=("$MSG")
  fi
done <<< "$FACT_RESULTS"

echo "" >&2
echo "=== Issues found: ${#ISSUES[@]} ===" >&2

# 3. Report
if $JSON; then
  python3 -c "
import json
issues = $(python3 -c "import json; print(json.dumps([$( printf '"%s",' "${ISSUES[@]}" | sed 's/,$//') ]))")
print(json.dumps({'issues': issues, 'issue_count': len(issues)}, indent=2))
" 2>/dev/null || echo '{"issues": [], "issue_count": 0}'
else
  if [ ${#ISSUES[@]} -gt 0 ]; then
    echo ""
    echo "ACTION REQUIRED:"
    for ISSUE in "${ISSUES[@]}"; do
      echo "  • $ISSUE"
    done
    # Alert via notify queue
    bash "$SCRIPTS/notify.sh" enqueue \
      "⚠️ Prompt stack drift detected: ${#ISSUES[@]} issue(s). Run prompt-sync-review.sh for details." \
      --tier high --type "system" 2>/dev/null
  else
    echo "All checks passed — stacks are in sync."
    bash "$SCRIPTS/log.sh" --event prompt-sync --level info --msg "Stacks in sync" 2>/dev/null
  fi
fi

[ ${#ISSUES[@]} -gt 0 ] && exit 1 || exit 0
