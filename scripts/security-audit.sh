#!/bin/bash
# Nightly security audit script
ISSUES=0

echo "=== Security Audit $(date) ==="

# 1. Check credential file permissions
FILES=(
  "$HOME/.config/notion/api_key"
  "$HOME/.openclaw/openclaw.json"
  "$HOME/Library/Application Support/gogcli/credentials.json"
)
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    PERMS=$(stat -f "%OLp" "$f" 2>/dev/null || stat -c "%a" "$f" 2>/dev/null)
    if [ "$PERMS" != "600" ]; then
      echo "⚠️  Permissions $PERMS on $f (should be 600)"
      chmod 600 "$f" && echo "   Fixed."
      ISSUES=$((ISSUES+1))
    fi
  fi
done

# 2. Verify gateway is loopback-only
GATEWAY_BIND=$(openclaw gateway status 2>/dev/null | grep "bind=" | grep -o "bind=[^ ]*")
if [[ "$GATEWAY_BIND" != *"loopback"* ]] && [[ "$GATEWAY_BIND" != *"127.0.0.1"* ]]; then
  echo "🔴 CRITICAL: Gateway not bound to loopback! $GATEWAY_BIND"
  ISSUES=$((ISSUES+1))
fi

# 3. Check for secrets in git history (last 5 commits)
cd ~/.openclaw/workspace
if git log --oneline -5 2>/dev/null | head -1 | grep -q "."; then
  SECRET_PATTERNS="secret_|ntn_|sk-|Bearer |AKIA|AIza|bot[0-9]"
  if git log -p -5 2>/dev/null | grep -qE "$SECRET_PATTERNS"; then
    echo "⚠️  Possible secrets found in recent git history"
    ISSUES=$((ISSUES+1))
  fi
fi

echo "=== Audit complete. Issues found: $ISSUES ==="
exit $ISSUES
