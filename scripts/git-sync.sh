#!/bin/bash
# git-sync.sh — Auto-commit + push workspace changes
#
# Usage:
#   git-sync.sh           — run sync
#   git-sync.sh --status  — show status without syncing

WORKSPACE="$HOME/.openclaw/workspace"
LOCK="$HOME/.openclaw/workspace/data/locks/git-sync.pid"
SCRIPTS="$WORKSPACE/scripts"

_log() { bash "$SCRIPTS/log.sh" --event git-sync --level "$1" --msg "$2" 2>/dev/null; echo "[$1] $2"; }
_alert() {
  bash "$SCRIPTS/notify.sh" enqueue "$1" --tier high --type "job-failure" 2>/dev/null
}

[[ "$1" == "--status" ]] && { cd "$WORKSPACE" && git status; exit 0; }

# ── PID lockfile guard ───────────────────────────────────────────────────────
mkdir -p "$(dirname "$LOCK")"
if [ -f "$LOCK" ]; then
  OLD_PID=$(cat "$LOCK")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    _log "warn" "git-sync already running (PID $OLD_PID), skipping"
    exit 0
  fi
  rm -f "$LOCK"
fi
echo $$ > "$LOCK"

cleanup() { rm -f "$LOCK"; }
trap cleanup EXIT SIGTERM SIGINT

cd "$WORKSPACE" || { _log "error" "Workspace not found"; exit 1; }

# ── Check if git repo ────────────────────────────────────────────────────────
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  git init --quiet
  git config user.email "clawd@openclaw.ai"
  git config user.name "Clawd"
  _log "info" "Initialized git repo"
fi

# ── Stage all changes ────────────────────────────────────────────────────────
git add -A 2>/dev/null

# Check if anything to commit
if git diff --cached --quiet; then
  _log "info" "Nothing to commit"
  exit 0
fi

# ── Commit ───────────────────────────────────────────────────────────────────
CHANGED=$(git diff --cached --name-only | wc -l | tr -d ' ')
TIMESTAMP=$(python3 -c "from datetime import datetime; print(datetime.now().strftime('%Y-%m-%d %H:%M'))")
MSG="auto: workspace sync $TIMESTAMP ($CHANGED files)"

git commit -m "$MSG" --quiet
if [ $? -ne 0 ]; then
  _log "error" "git commit failed"
  _alert "🔴 git-sync commit failed at $TIMESTAMP"
  exit 1
fi

# ── Pull + Push (if remote configured) ──────────────────────────────────────
REMOTE=$(git remote 2>/dev/null | head -1)
if [ -n "$REMOTE" ]; then
  # Pull first to handle conflicts
  git pull --rebase --quiet "$REMOTE" "$(git branch --show-current)" 2>/dev/null
  PULL_EXIT=$?

  if [ $PULL_EXIT -ne 0 ]; then
    _log "warn" "git pull failed (merge conflict?) — keeping local changes"
    git rebase --abort 2>/dev/null
  fi

  git push --quiet "$REMOTE" "$(git branch --show-current)" 2>/dev/null
  if [ $? -eq 0 ]; then
    _log "info" "Pushed $CHANGED files to $REMOTE"
  else
    _log "warn" "Push failed — committed locally, will retry next sync"
  fi
else
  _log "info" "Committed $CHANGED files (no remote configured)"
fi
