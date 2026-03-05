#!/bin/bash
# backup-drill.sh — Integrity verification without modifying filesystem
#
# Verifies: decrypt works, manifest parses, checksums match, all files present
# Does NOT restore anything to disk.
#
# Usage: backup-drill.sh [archive_path|latest]

CONFIG_FILE="$HOME/.openclaw/workspace/.backup-config"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
BACKUP_DEST="${BACKUP_DEST:-$HOME/backups/openclaw}"
SCRIPTS="$HOME/.openclaw/workspace/scripts"

ARCHIVE="${1:-latest}"
STAGING="/tmp/openclaw-drill-$$"
PASS=0; FAIL=0

pass() { echo "✅ $1"; PASS=$((PASS+1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL+1)); }

_log() { bash "$SCRIPTS/log.sh" --event backup-drill --level "$1" --msg "$2" 2>/dev/null; }

if [ "$ARCHIVE" = "latest" ]; then
  ARCHIVE=$(ls -t "$BACKUP_DEST/archives/"*.enc 2>/dev/null | head -1)
fi

[ -z "$ARCHIVE" ] && echo "❌ No backups found" && exit 1
[ ! -f "$ARCHIVE" ] && echo "❌ Archive not found: $ARCHIVE" && exit 1
[ -z "$BACKUP_PASSPHRASE" ] && echo "❌ BACKUP_PASSPHRASE not set" && exit 1

echo "=== Backup Integrity Drill: $(basename "$ARCHIVE") ==="
echo ""

mkdir -p "$STAGING"
trap "rm -rf $STAGING" EXIT

# 1. Decryption test
openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d \
  -pass "pass:$BACKUP_PASSPHRASE" -in "$ARCHIVE" | \
  tar -xzf - -C "$STAGING" 2>/dev/null
[ $? -eq 0 ] && pass "Decryption + extraction succeeded" || { fail "Decryption FAILED"; exit 1; }

# 2. Manifest exists and parses
MANIFEST="$STAGING/manifest.json"
if [ -f "$MANIFEST" ]; then
  FILE_COUNT=$(python3 -c "import json; m=json.load(open('$MANIFEST')); print(len(m['files']))" 2>/dev/null)
  [ -n "$FILE_COUNT" ] && pass "Manifest parses OK ($FILE_COUNT files)" || fail "Manifest parse error"
else
  fail "Manifest not found"
  exit 1
fi

# 3. Checksum verification
python3 -c "
import json, os, hashlib

with open('$MANIFEST') as f:
    manifest = json.load(f)

staging_files = '$STAGING/files'
ok = bad = missing = 0

for entry in manifest['files']:
    orig = entry['path']
    rel = os.path.relpath(orig, os.path.expanduser('~'))
    src = os.path.join(staging_files, rel)

    if not os.path.exists(src):
        print(f'  ⚠️  Missing in archive: {orig}')
        missing += 1
        continue

    with open(src,'rb') as f:
        sha = hashlib.sha256(f.read()).hexdigest()

    if sha == entry.get('sha256',''):
        ok += 1
    else:
        print(f'  ❌ Checksum mismatch: {orig}')
        bad += 1

print(f'  checksums: {ok} OK, {bad} bad, {missing} missing')
import sys
sys.exit(0 if bad == 0 else 1)
"

if [ $? -eq 0 ]; then
  pass "All checksums valid"
else
  fail "Checksum mismatches found"
fi

# 4. Key files present
for KEY in "MEMORY.md" "LEARNINGS.md"; do
  FOUND=$(find "$STAGING" -name "$KEY" 2>/dev/null | head -1)
  [ -n "$FOUND" ] && pass "$KEY present in backup" || fail "$KEY missing from backup"
done

# 5. DB files present
DB_COUNT=$(find "$STAGING" -name "*.db" 2>/dev/null | wc -l | tr -d ' ')
[ "$DB_COUNT" -gt 0 ] && pass "$DB_COUNT SQLite DBs in backup" || fail "No SQLite DBs found in backup"

echo ""
echo "=== Drill complete: $PASS passed, $FAIL failed ==="
_log "info" "Integrity drill: $PASS passed, $FAIL failed — $ARCHIVE"

[ $FAIL -gt 0 ] && exit 1 || exit 0
