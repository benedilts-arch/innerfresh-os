#!/bin/bash
# backup.sh — Automated encrypted workspace backup
#
# Usage:
#   backup.sh run       — full backup cycle
#   backup.sh list      — list recent backups
#   backup.sh prune     — remove old backups beyond KEEP_COUNT
#   backup.sh init      — generate GPG key, configure
#
# Config (env vars or ~/.openclaw/workspace/.backup-config):
#   BACKUP_PASSPHRASE   — encryption passphrase (required)
#   BACKUP_DEST         — local backup dir (default: ~/backups/openclaw)
#   BACKUP_RCLONE       — rclone remote path (optional, e.g. gdrive:openclaw-backups)
#   BACKUP_KEEP         — number of backups to keep (default: 7)

WORKSPACE="$HOME/.openclaw/workspace"
CONFIG_FILE="$WORKSPACE/.backup-config"
SCRIPTS="$WORKSPACE/scripts"

# Load config
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

BACKUP_PASSPHRASE="${BACKUP_PASSPHRASE:-}"
BACKUP_DEST="${BACKUP_DEST:-$HOME/backups/openclaw}"
BACKUP_RCLONE="${BACKUP_RCLONE:-}"
BACKUP_KEEP="${BACKUP_KEEP:-7}"
TIMESTAMP=$(python3 -c "from datetime import datetime; print(datetime.now().strftime('%Y-%m-%d_%H-%M-%S'))")
BACKUP_NAME="workspace-$TIMESTAMP"
STAGING="$BACKUP_DEST/staging/$BACKUP_NAME"

mkdir -p "$BACKUP_DEST/archives" "$STAGING"

source "$SCRIPTS/log.sh" 2>/dev/null || true
_log() { bash "$SCRIPTS/log.sh" --event backup --level "$1" --msg "$2" 2>/dev/null; echo "[$1] $2"; }

case "$1" in
  init)
    echo "=== Backup Init ==="
    echo ""
    echo "Setting up backup configuration..."

    # Generate passphrase if none
    if [ -z "$BACKUP_PASSPHRASE" ]; then
      PASSPHRASE=$(openssl rand -hex 32)
      echo ""
      echo "⚠️  Generated encryption passphrase. SAVE THIS SOMEWHERE SAFE:"
      echo "   $PASSPHRASE"
      echo ""
      BACKUP_PASSPHRASE="$PASSPHRASE"
    fi

    cat > "$CONFIG_FILE" << CONF
BACKUP_PASSPHRASE="$BACKUP_PASSPHRASE"
BACKUP_DEST="$HOME/backups/openclaw"
BACKUP_RCLONE=""
BACKUP_KEEP=7
CONF
    chmod 600 "$CONFIG_FILE"
    echo "Config written to $CONFIG_FILE"
    echo ""
    echo "To set up cloud sync, configure rclone first:"
    echo "  rclone config"
    echo "Then set BACKUP_RCLONE in $CONFIG_FILE"
    echo "  e.g. BACKUP_RCLONE=\"gdrive:openclaw-backups\""
    ;;

  run)
    if [ -z "$BACKUP_PASSPHRASE" ]; then
      _log "error" "BACKUP_PASSPHRASE not set. Run backup.sh init first."
      exit 1
    fi

    _log "info" "Starting backup $BACKUP_NAME"
    T0=$(python3 -c "import time; print(int(time.time()))")

    # ── Discover files ──────────────────────────────────────────────────────
    MANIFEST_FILE="$STAGING/manifest.json"
    FILES=()

    # DBs and SQLite files
    while IFS= read -r f; do FILES+=("$f"); done < <(find "$HOME/.openclaw/workspace/data" -name "*.db" -o -name "*.sqlite" 2>/dev/null)
    while IFS= read -r f; do FILES+=("$f"); done < <(find "$HOME/.openclaw/workspace/data/logs" -name "*.jsonl" 2>/dev/null)

    # Workspace config/knowledge files
    for f in "$WORKSPACE/MEMORY.md" "$WORKSPACE/LEARNINGS.md" "$WORKSPACE/ERRORS.md" \
              "$WORKSPACE/FEATURE_REQUESTS.md" "$WORKSPACE/HEARTBEAT.md" \
              "$WORKSPACE/.backup-config"; do
      [ -f "$f" ] && FILES+=("$f")
    done

    # Memory files
    while IFS= read -r f; do FILES+=("$f"); done < <(find "$WORKSPACE/memory" -name "*.md" -o -name "*.json" 2>/dev/null)

    # Build manifest
    python3 -c "
import json, hashlib, os, sys
files = $(printf '%s\n' "${FILES[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))")
manifest = {'backup': '$BACKUP_NAME', 'timestamp': '$TIMESTAMP', 'files': []}
for f in files:
    if not os.path.exists(f): continue
    with open(f,'rb') as fh:
        sha = hashlib.sha256(fh.read()).hexdigest()
    manifest['files'].append({'path': f, 'size': os.path.getsize(f), 'sha256': sha})
with open('$MANIFEST_FILE','w') as out:
    json.dump(manifest, out, indent=2)
print(f'Manifest: {len(manifest[\"files\"])} files')
"

    # ── Copy files preserving paths ─────────────────────────────────────────
    python3 -c "
import json, os, shutil
with open('$MANIFEST_FILE') as f:
    manifest = json.load(f)
staging = '$STAGING/files'
for entry in manifest['files']:
    src = entry['path']
    # Relative path from HOME
    rel = os.path.relpath(src, os.path.expanduser('~'))
    dst = os.path.join(staging, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)
print('Files copied')
"

    # ── Encrypt (tar + openssl AES-256-CBC) ─────────────────────────────────
    ARCHIVE="$BACKUP_DEST/archives/${BACKUP_NAME}.tar.gz.enc"
    tar -czf - -C "$STAGING" . | \
      openssl enc -aes-256-cbc -pbkdf2 -iter 100000 \
        -pass "pass:$BACKUP_PASSPHRASE" -out "$ARCHIVE"

    if [ $? -ne 0 ]; then
      _log "error" "Encryption failed for $BACKUP_NAME"
      rm -rf "$STAGING"
      exit 1
    fi

    SIZE=$(du -sh "$ARCHIVE" | awk '{print $1}')
    _log "info" "Encrypted archive: $ARCHIVE ($SIZE)"

    # ── Cloud upload ────────────────────────────────────────────────────────
    if [ -n "$BACKUP_RCLONE" ]; then
      rclone copy "$ARCHIVE" "$BACKUP_RCLONE/" --quiet 2>/dev/null \
        && _log "info" "Uploaded to $BACKUP_RCLONE" \
        || _log "warn" "Cloud upload failed — local backup preserved"
    fi

    # ── Cleanup staging ─────────────────────────────────────────────────────
    rm -rf "$STAGING"

    # ── Prune ───────────────────────────────────────────────────────────────
    bash "$0" prune

    T1=$(python3 -c "import time; print(int(time.time()))")
    _log "info" "Backup complete in $((T1-T0))s: $ARCHIVE"
    bash "$SCRIPTS/cron-db.sh" log-end "$(cat /tmp/backup-run-id 2>/dev/null || echo 0)" "ok" "Backup $BACKUP_NAME ($SIZE)" 2>/dev/null
    ;;

  list)
    echo "=== Recent Backups ==="
    ls -lht "$BACKUP_DEST/archives/"*.enc 2>/dev/null | head -10 || echo "No backups found"
    ;;

  prune)
    COUNT=$(ls "$BACKUP_DEST/archives/"*.enc 2>/dev/null | wc -l | tr -d ' ')
    if [ "$COUNT" -gt "$BACKUP_KEEP" ]; then
      EXCESS=$((COUNT - BACKUP_KEEP))
      ls -t "$BACKUP_DEST/archives/"*.enc | tail -"$EXCESS" | xargs rm -f
      _log "info" "Pruned $EXCESS old backup(s), keeping $BACKUP_KEEP"
    fi
    ;;

  *)
    echo "Usage: backup.sh {init|run|list|prune}"
    exit 1
    ;;
esac
