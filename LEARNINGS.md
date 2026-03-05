# LEARNINGS.md — Corrections & Insights

Captured from user feedback and operational experience. Updated in real-time.

---

## 2026-03-05

### macOS date command incompatibility
- **Trigger:** `date +%s%3N` produces `17727237683N` on macOS (BSD date)
- **Fix:** Use `python3 -c "import time; print(int(time.time()*1000))"`
- **Applies to:** All bash scripts needing millisecond timestamps

### gog calendar create hangs in background
- **Trigger:** Running `gog calendar create` from a cron or headless session
- **Fix:** Set Keychain access for gogcli to "Allow all applications"
- **Path:** Keychain Access app → gogcli entry → Access Control → Allow all

### Telegram group bot not responding
- **Trigger:** After disabling Privacy Mode via BotFather
- **Fix:** Remove bot from group and re-add it; Telegram requires this after Privacy Mode changes
- **Status:** Pending Benni doing the remove+re-add

### Notion token vs OAuth client secret
- **Trigger:** Used OAuth client secret file for Notion — wrong path
- **Fix:** Use internal integration token (`ntn_` prefix) from Notion settings
- **Stored at:** `~/.config/notion/api_key`

### groupAllowFrom must be integers
- **Trigger:** String group IDs in openclaw.json cause "Invalid allowFrom entry" warnings
- **Fix:** Store as integers: `-5081837089` not `"-5081837089"`

### bash case statement with `&` 
- **Trigger:** `pl|p&l)` in case statement causes syntax error
- **Fix:** Rename to `pl|pandl)` or avoid `&` in case patterns

### `${VAR^}` capitalization not available in bash 3.2
- **Trigger:** macOS ships bash 3.2 which doesn't support `${VAR^}` or `${VAR,}`
- **Fix:** Use `python3 -c "print('$VAR'.capitalize())"` or `echo "$VAR" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}'`
