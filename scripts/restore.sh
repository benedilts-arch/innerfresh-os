#!/bin/bash
# restore.sh — Restore workspace from encrypted backup
#
# Usage:
#   restore.sh list               — list available backups
#   restore.sh preview <archive>  — show manifest without restoring
#   restore.sh run <archive>      — restore from archive (requires --force)
#   restore.sh run latest         — restore most recent backup
#   restore.sh run <archive> --force

CONFIG_FILE="$HOME/.openclaw/workspace/.backup-config"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

BACKUP_DEST="${BACKUP_DEST:-$HOME/backups/openclaw}"
STAGING="/tmp/openclaw-restore-$$"

_err() { echo "❌ $1"; exit 1; }

case "$1" in
  list)
    echo "=== Available Backups ==="
    ls -lht "$BACKUP_DEST/archives/"*.enc 2>/dev/null || echo "None found"
    ;;

  preview)
    ARCHIVE="$2"
    [ -z "$ARCHIVE" ] && _err "provide archive path"
    [ -z "$BACKUP_PASSPHRASE" ] && _err "BACKUP_PASSPHRASE not set"
    [ ! -f "$ARCHIVE" ] && _err "archive not found: $ARCHIVE"

    mkdir -p "$STAGING"
    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d \
      -pass "pass:$BACKUP_PASSPHRASE" -in "$ARCHIVE" | \
      tar -xzf - -C "$STAGING" --strip-components=0 2>/dev/null

    MANIFEST="$STAGING/manifest.json"
    [ ! -f "$MANIFEST" ] && rm -rf "$STAGING" && _err "manifest not found in archive"

    python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
print(f'Backup: {m[\"backup\"]}')
print(f'Timestamp: {m[\"timestamp\"]}')
print(f'Files: {len(m[\"files\"])}')
print()
for entry in m['files']:
    size = entry.get('size', 0)
    print(f'  {entry[\"path\"]}  ({size:,} bytes)')
"
    rm -rf "$STAGING"
    ;;

  run)
    ARCHIVE="$2"
    FORCE=false
    [[ "$3" == "--force" ]] && FORCE=true
    [ -z "$ARCHIVE" ] && _err "provide archive path or 'latest'"
    [ -z "$BACKUP_PASSPHRASE" ] && _err "BACKUP_PASSPHRASE not set"

    # Resolve 'latest'
    if [ "$ARCHIVE" = "latest" ]; then
      ARCHIVE=$(ls -t "$BACKUP_DEST/archives/"*.enc 2>/dev/null | head -1)
      [ -z "$ARCHIVE" ] && _err "No backups found"
      echo "Using latest: $ARCHIVE"
    fi
    [ ! -f "$ARCHIVE" ] && _err "Archive not found: $ARCHIVE"

    if ! $FORCE; then
      echo "⚠️  This will overwrite existing files."
      echo "Run with --force to confirm: restore.sh run '$ARCHIVE' --force"
      exit 1
    fi

    echo "=== Restoring from $ARCHIVE ==="
    mkdir -p "$STAGING"

    # Decrypt + extract
    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d \
      -pass "pass:$BACKUP_PASSPHRASE" -in "$ARCHIVE" | \
      tar -xzf - -C "$STAGING" 2>/dev/null

    [ $? -ne 0 ] && rm -rf "$STAGING" && _err "Decryption failed — wrong passphrase?"

    MANIFEST="$STAGING/manifest.json"
    [ ! -f "$MANIFEST" ] && rm -rf "$STAGING" && _err "Manifest not found"

    # Restore files using manifest paths
    python3 -c "
import json, os, shutil, hashlib

with open('$STAGING/manifest.json') as f:
    manifest = json.load(f)

staging_files = '$STAGING/files'
restored = failed = 0

for entry in manifest['files']:
    orig_path = entry['path']
    rel = os.path.relpath(orig_path, os.path.expanduser('~'))
    src = os.path.join(staging_files, rel)

    if not os.path.exists(src):
        print(f'  ⚠️  Not found in archive: {orig_path}')
        failed += 1
        continue

    # Verify checksum before restoring
    with open(src,'rb') as f:
        sha = hashlib.sha256(f.read()).hexdigest()
    if sha != entry.get('sha256',''):
        print(f'  ❌ Checksum mismatch: {orig_path}')
        failed += 1
        continue

    os.makedirs(os.path.dirname(orig_path), exist_ok=True)
    shutil.copy2(src, orig_path)
    print(f'  ✅ {orig_path}')
    restored += 1

print()
print(f'Restored: {restored}  Failed: {failed}')
"
    rm -rf "$STAGING"
    echo "=== Restore complete ==="
    ;;

  *)
    echo "Usage: restore.sh {list|preview <archive>|run <archive|latest> [--force]}"
    exit 1
    ;;
esac
